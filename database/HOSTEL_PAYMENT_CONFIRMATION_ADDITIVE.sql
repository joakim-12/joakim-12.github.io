-- Additive hostel payment workflow. This migration preserves all existing
-- booking constraints, policies, and RPCs; it adds versioned RPCs instead.

ALTER TABLE public.hostel_bookings
    ADD COLUMN IF NOT EXISTS semester_started_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS semester_ends_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS payment_status TEXT NOT NULL DEFAULT 'unpaid',
    ADD COLUMN IF NOT EXISTS payment_method TEXT,
    ADD COLUMN IF NOT EXISTS payment_reference TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS payment_proof_path TEXT,
    ADD COLUMN IF NOT EXISTS payment_submitted_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS payment_verified_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS payment_verified_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

UPDATE public.hostel_bookings
   SET semester_started_at = COALESCE(semester_started_at, created_at),
       semester_ends_at = COALESCE(semester_ends_at, created_at + INTERVAL '6 months')
 WHERE semester_started_at IS NULL OR semester_ends_at IS NULL;

ALTER TABLE public.hostel_bookings
    ALTER COLUMN semester_started_at SET DEFAULT NOW(),
    ALTER COLUMN semester_started_at SET NOT NULL,
    ALTER COLUMN semester_ends_at SET DEFAULT (NOW() + INTERVAL '6 months'),
    ALTER COLUMN semester_ends_at SET NOT NULL;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'hostel_bookings_payment_status_v2_check') THEN
        ALTER TABLE public.hostel_bookings ADD CONSTRAINT hostel_bookings_payment_status_v2_check
            CHECK (payment_status IN ('unpaid', 'submitted', 'verified', 'rejected', 'expired'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'hostel_bookings_payment_method_v2_check') THEN
        ALTER TABLE public.hostel_bookings ADD CONSTRAINT hostel_bookings_payment_method_v2_check
            CHECK (payment_method IS NULL OR payment_method IN ('mpesa', 'bank'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'hostel_bookings_payment_reference_v2_check') THEN
        ALTER TABLE public.hostel_bookings ADD CONSTRAINT hostel_bookings_payment_reference_v2_check
            CHECK (char_length(payment_reference) <= 100);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS hostel_bookings_payment_queue_v2_idx
    ON public.hostel_bookings (payment_status, semester_ends_at);

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('hostel-payment-proofs', 'hostel-payment-proofs', FALSE, 8388608,
        ARRAY['image/jpeg','image/png','image/webp','application/pdf'])
ON CONFLICT (id) DO NOTHING;

CREATE POLICY hostel_payment_proofs_read_v2 ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'hostel-payment-proofs'
        AND (
            (storage.foldername(name))[1] = auth.uid()::TEXT
            OR EXISTS (
                SELECT 1 FROM public.hostel_bookings b
                JOIN public.hostel_rooms r ON r.id = b.room_id
                JOIN public.hostels h ON h.id = r.hostel_id
                WHERE b.id::TEXT = (storage.foldername(name))[2]
                  AND public.is_school_staff(h.school_key)
            )
        )
    );

CREATE POLICY hostel_payment_proofs_upload_v2 ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'hostel-payment-proofs'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
        AND EXISTS (
            SELECT 1 FROM public.hostel_bookings b
            WHERE b.id::TEXT = (storage.foldername(name))[2]
              AND b.student_id = auth.uid()
              AND b.status IN ('pending', 'approved')
              AND b.semester_ends_at > NOW()
        )
    );

CREATE POLICY hostel_payment_proofs_remove_v2 ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'hostel-payment-proofs'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
        AND EXISTS (
            SELECT 1 FROM public.hostel_bookings b
            WHERE b.id::TEXT = (storage.foldername(name))[2]
              AND b.student_id = auth.uid()
              AND b.payment_status <> 'verified'
        )
    );

CREATE OR REPLACE FUNCTION public.refresh_expired_hostel_bookings_v2()
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_count INTEGER;
BEGIN
    UPDATE public.hostel_bookings
       SET payment_status = 'expired', updated_at = NOW()
     WHERE semester_ends_at <= NOW()
       AND status IN ('pending', 'approved')
       AND payment_status <> 'expired';
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;
REVOKE ALL ON FUNCTION public.refresh_expired_hostel_bookings_v2() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.submit_hostel_payment_proof(
    p_booking_id UUID, p_method TEXT, p_reference TEXT, p_proof_path TEXT
)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_status TEXT;
BEGIN
    PERFORM public.refresh_expired_hostel_bookings_v2();
    IF COALESCE(p_method, '') NOT IN ('mpesa', 'bank') THEN
        RAISE EXCEPTION 'Choose M-Pesa or bank transfer.' USING ERRCODE = '22023';
    END IF;
    IF char_length(BTRIM(COALESCE(p_reference, ''))) < 3 OR char_length(p_reference) > 100 THEN
        RAISE EXCEPTION 'Enter the M-Pesa receipt code or bank reference.' USING ERRCODE = '22023';
    END IF;
    IF p_proof_path IS NULL OR split_part(p_proof_path, '/', 1) <> auth.uid()::TEXT
       OR split_part(p_proof_path, '/', 2) <> p_booking_id::TEXT THEN
        RAISE EXCEPTION 'The payment file does not belong to this booking.' USING ERRCODE = '42501';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM storage.objects o
                   WHERE o.bucket_id = 'hostel-payment-proofs' AND o.name = p_proof_path) THEN
        RAISE EXCEPTION 'Upload the M-Pesa or bank confirmation before sending it.' USING ERRCODE = 'P0001';
    END IF;
    UPDATE public.hostel_bookings
       SET payment_status = 'submitted', payment_method = p_method,
           payment_reference = BTRIM(p_reference), payment_proof_path = p_proof_path,
           payment_submitted_at = NOW(), payment_verified_at = NULL,
           payment_verified_by = NULL, decision_note = '', updated_at = NOW()
     WHERE id = p_booking_id AND student_id = auth.uid()
       AND status IN ('pending', 'approved') AND semester_ends_at > NOW()
    RETURNING payment_status INTO v_status;
    IF v_status IS NULL THEN
        RAISE EXCEPTION 'This booking is no longer waiting for payment.' USING ERRCODE = 'P0001';
    END IF;
    RETURN v_status;
END;
$$;

CREATE OR REPLACE FUNCTION public.review_hostel_payment(
    p_booking_id UUID, p_approve BOOLEAN, p_note TEXT DEFAULT ''
)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_room UUID; v_school TEXT; v_status TEXT; v_payment_status TEXT;
        v_semester_end TIMESTAMPTZ; v_taken INTEGER; v_capacity INTEGER;
BEGIN
    PERFORM public.refresh_expired_hostel_bookings_v2();
    SELECT r.id, h.school_key, b.status, b.payment_status, b.semester_ends_at, r.capacity
      INTO v_room, v_school, v_status, v_payment_status, v_semester_end, v_capacity
      FROM public.hostel_bookings b
      JOIN public.hostel_rooms r ON r.id = b.room_id
      JOIN public.hostels h ON h.id = r.hostel_id
     WHERE b.id = p_booking_id FOR UPDATE OF b;
    IF v_room IS NULL THEN RAISE EXCEPTION 'No such hostel request.' USING ERRCODE = 'P0002'; END IF;
    IF NOT public.is_school_staff(v_school) THEN
        RAISE EXCEPTION 'Only this school’s housing office can verify payment.' USING ERRCODE = '42501';
    END IF;
    IF v_status NOT IN ('pending', 'approved') OR v_semester_end <= NOW()
       OR v_payment_status <> 'submitted' THEN
        RAISE EXCEPTION 'This request is expired or has no submitted payment proof.' USING ERRCODE = 'P0001';
    END IF;
    IF p_approve THEN
        IF NOT EXISTS (SELECT 1 FROM public.hostel_bookings b JOIN storage.objects o
                       ON o.bucket_id = 'hostel-payment-proofs' AND o.name = b.payment_proof_path
                       WHERE b.id = p_booking_id) THEN
            RAISE EXCEPTION 'The submitted payment receipt is unavailable.' USING ERRCODE = 'P0001';
        END IF;
        IF v_status = 'pending' THEN
            SELECT COUNT(*) INTO v_taken FROM public.hostel_bookings b
             WHERE b.room_id = v_room AND b.status = 'approved'
               AND b.semester_ends_at > NOW() AND b.id <> p_booking_id;
            IF v_taken >= v_capacity THEN RAISE EXCEPTION 'That room has no beds left.' USING ERRCODE = 'P0001'; END IF;
        END IF;
        UPDATE public.hostel_bookings SET status = 'approved', payment_status = 'verified',
            payment_verified_at = NOW(), payment_verified_by = auth.uid(),
            decided_by = auth.uid(), decided_at = NOW(),
            decision_note = LEFT(BTRIM(COALESCE(p_note, 'Payment checked by the housing office.')), 400),
            updated_at = NOW() WHERE id = p_booking_id;
        RETURN 'approved';
    END IF;
    UPDATE public.hostel_bookings SET payment_status = 'rejected',
        decision_note = LEFT(BTRIM(COALESCE(p_note, 'Please send a clearer payment confirmation.')), 400),
        decided_by = auth.uid(), decided_at = NOW(), updated_at = NOW()
     WHERE id = p_booking_id;
    RETURN 'rejected';
END;
$$;

CREATE OR REPLACE FUNCTION public.decide_hostel_booking(
    p_booking_id UUID, p_decision TEXT, p_note TEXT DEFAULT ''
)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_room UUID; v_school TEXT; v_payment TEXT; v_end TIMESTAMPTZ;
        v_taken INTEGER; v_capacity INTEGER;
BEGIN
    IF p_decision NOT IN ('approved', 'rejected', 'cancelled') THEN
        RAISE EXCEPTION 'That decision is not one the housing office can make.' USING ERRCODE = '22023';
    END IF;
    SELECT r.id, h.school_key, b.payment_status, b.semester_ends_at, r.capacity
      INTO v_room, v_school, v_payment, v_end, v_capacity
      FROM public.hostel_bookings b
      JOIN public.hostel_rooms r ON r.id = b.room_id
      JOIN public.hostels h ON h.id = r.hostel_id
     WHERE b.id = p_booking_id;
    IF v_room IS NULL THEN RAISE EXCEPTION 'No such booking.' USING ERRCODE = 'P0002'; END IF;
    IF NOT public.is_school_staff(v_school) THEN
        RAISE EXCEPTION 'Only the housing office of that school can decide a bed.' USING ERRCODE = '42501';
    END IF;
    IF p_decision = 'approved' THEN
        IF v_payment <> 'verified' OR v_end <= NOW() THEN
            RAISE EXCEPTION 'Verify the student’s payment before assigning the room.' USING ERRCODE = 'P0001';
        END IF;
        SELECT COUNT(*) INTO v_taken FROM public.hostel_bookings b
         WHERE b.room_id = v_room AND b.status = 'approved'
           AND b.semester_ends_at > NOW() AND b.id <> p_booking_id;
        IF v_taken >= v_capacity THEN RAISE EXCEPTION 'That room is full.' USING ERRCODE = 'P0001'; END IF;
    END IF;
    UPDATE public.hostel_bookings SET status = p_decision,
        decision_note = LEFT(BTRIM(COALESCE(p_note, '')), 400),
        decided_by = auth.uid(), decided_at = NOW(), updated_at = NOW()
     WHERE id = p_booking_id;
    RETURN p_decision;
END;
$$;

CREATE OR REPLACE FUNCTION public.my_bed_requests_v2()
RETURNS TABLE (
    booking_id UUID, hostel_name TEXT, room_label TEXT, room_capacity INT, school TEXT,
    semester TEXT, status TEXT, request_note TEXT, decision_note TEXT, decided_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ, registration_number TEXT, semester_started_at TIMESTAMPTZ,
    semester_ends_at TIMESTAMPTZ, payment_status TEXT, payment_method TEXT,
    payment_reference TEXT, payment_proof_path TEXT, payment_submitted_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
    PERFORM public.refresh_expired_hostel_bookings_v2();
    RETURN QUERY
    SELECT b.id, h.name, r.label, r.capacity, h.school, b.semester, b.status,
           b.request_note, b.decision_note, b.decided_at, b.created_at, sr.registration_number,
           b.semester_started_at, b.semester_ends_at, b.payment_status, b.payment_method,
           b.payment_reference, b.payment_proof_path, b.payment_submitted_at
      FROM public.hostel_bookings b
      JOIN public.hostel_rooms r ON r.id = b.room_id
      JOIN public.hostels h ON h.id = r.hostel_id
      LEFT JOIN public.student_registrations sr ON sr.user_id = b.student_id
     WHERE b.student_id = auth.uid()
     ORDER BY b.created_at DESC LIMIT 40;
END;
$$;

CREATE OR REPLACE FUNCTION public.school_bed_requests_v2(p_school_key TEXT)
RETURNS TABLE (
    booking_id UUID, student_id UUID, student_name TEXT, registration_number TEXT,
    hostel_name TEXT, room_label TEXT, room_capacity INT, beds_approved INT,
    semester TEXT, status TEXT, request_note TEXT, decided_at TIMESTAMPTZ, created_at TIMESTAMPTZ,
    semester_started_at TIMESTAMPTZ, semester_ends_at TIMESTAMPTZ, payment_status TEXT,
    payment_method TEXT, payment_reference TEXT, payment_proof_path TEXT,
    payment_submitted_at TIMESTAMPTZ, payment_verified_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
    PERFORM public.refresh_expired_hostel_bookings_v2();
    IF NOT public.is_school_staff(p_school_key) THEN
        RAISE EXCEPTION 'Only this school’s housing office sees its requests.' USING ERRCODE = '42501';
    END IF;
    RETURN QUERY
    SELECT b.id, b.student_id, p.full_name, sr.registration_number, h.name, r.label, r.capacity,
           (SELECT COUNT(*)::INT FROM public.hostel_bookings x
             WHERE x.room_id = b.room_id AND x.status = 'approved'
               AND x.semester_ends_at > NOW()
               AND LOWER(BTRIM(x.semester)) = LOWER(BTRIM(b.semester))),
           b.semester, b.status, b.request_note, b.decided_at, b.created_at,
           b.semester_started_at, b.semester_ends_at, b.payment_status, b.payment_method,
           b.payment_reference, b.payment_proof_path, b.payment_submitted_at, b.payment_verified_at
      FROM public.hostel_bookings b
      JOIN public.hostel_rooms r ON r.id = b.room_id
      JOIN public.hostels h ON h.id = r.hostel_id
      JOIN public.profiles p ON p.id = b.student_id
      LEFT JOIN public.student_registrations sr ON sr.user_id = b.student_id
     WHERE h.school_key = LOWER(BTRIM(COALESCE(p_school_key, '')))
     ORDER BY b.created_at DESC LIMIT 200;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_hostel_payment_proof(UUID, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.review_hostel_payment(UUID, BOOLEAN, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.my_bed_requests_v2() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.school_bed_requests_v2(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_hostel_payment_proof(UUID, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_hostel_payment(UUID, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.my_bed_requests_v2() TO authenticated;
GRANT EXECUTE ON FUNCTION public.school_bed_requests_v2(TEXT) TO authenticated;

NOTIFY pgrst, 'reload schema';

