-- Hostel eligibility, university payment instructions, and payment review.
-- Safe to run repeatedly. Email domains and payment numbers are configured per
-- university; Kabarak's defaults below are copied from its official hostel page.

ALTER TABLE public.campus_services
    ADD COLUMN IF NOT EXISTS student_email_domains TEXT[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS hostel_paybill_number TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS hostel_paybill_account_hint TEXT NOT NULL DEFAULT 'Student registration number',
    ADD COLUMN IF NOT EXISTS hostel_bank_name TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS hostel_bank_branch TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS hostel_bank_account_name TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS hostel_bank_account_number TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS hostel_payment_note TEXT NOT NULL DEFAULT '';

ALTER TABLE public.hostel_bookings
    ADD COLUMN IF NOT EXISTS payment_status TEXT NOT NULL DEFAULT 'instructions_sent',
    ADD COLUMN IF NOT EXISTS payment_reference TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS payment_review_note TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS payment_details_snapshot JSONB NOT NULL DEFAULT '{}'::JSONB,
    ADD COLUMN IF NOT EXISTS payment_submitted_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS payment_reviewed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS payment_reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'hostel_bookings_payment_status_check'
          AND conrelid = 'public.hostel_bookings'::regclass
    ) THEN
        ALTER TABLE public.hostel_bookings
            ADD CONSTRAINT hostel_bookings_payment_status_check
            CHECK (payment_status IN ('instructions_sent', 'submitted', 'verified', 'rejected'));
    END IF;
END;
$$;

-- Kabarak officially lists these hostel-only payment details. Other schools
-- enter their own values in Campus services > Housing office settings.
INSERT INTO public.campus_services (
    school, accommodation, student_email_domains, hostel_paybill_number,
    hostel_paybill_account_hint, hostel_bank_name, hostel_bank_branch,
    hostel_bank_account_name, hostel_bank_account_number, hostel_payment_note
)
VALUES (
    'Kabarak University', TRUE, ARRAY['kabarak.ac.ke'], '4080909',
    'Use your student registration/admission number', 'KCB Bank Kenya', 'Nakuru',
    'KABARAK UNIVERSITY HOSTEL & CATERING', '1289700893',
    'Hostel charges only. Verify the amount and reference with the University before paying.'
)
ON CONFLICT (school_key) DO UPDATE SET
    accommodation = TRUE,
    student_email_domains = CASE
        WHEN cardinality(public.campus_services.student_email_domains) = 0
            THEN EXCLUDED.student_email_domains
        ELSE public.campus_services.student_email_domains
    END,
    hostel_paybill_number = CASE WHEN public.campus_services.hostel_paybill_number = ''
        THEN EXCLUDED.hostel_paybill_number ELSE public.campus_services.hostel_paybill_number END,
    hostel_paybill_account_hint = CASE WHEN public.campus_services.hostel_paybill_account_hint = ''
        THEN EXCLUDED.hostel_paybill_account_hint ELSE public.campus_services.hostel_paybill_account_hint END,
    hostel_bank_name = CASE WHEN public.campus_services.hostel_bank_name = ''
        THEN EXCLUDED.hostel_bank_name ELSE public.campus_services.hostel_bank_name END,
    hostel_bank_branch = CASE WHEN public.campus_services.hostel_bank_branch = ''
        THEN EXCLUDED.hostel_bank_branch ELSE public.campus_services.hostel_bank_branch END,
    hostel_bank_account_name = CASE WHEN public.campus_services.hostel_bank_account_name = ''
        THEN EXCLUDED.hostel_bank_account_name ELSE public.campus_services.hostel_bank_account_name END,
    hostel_bank_account_number = CASE WHEN public.campus_services.hostel_bank_account_number = ''
        THEN EXCLUDED.hostel_bank_account_number ELSE public.campus_services.hostel_bank_account_number END,
    hostel_payment_note = CASE WHEN public.campus_services.hostel_payment_note = ''
        THEN EXCLUDED.hostel_payment_note ELSE public.campus_services.hostel_payment_note END;

CREATE OR REPLACE FUNCTION public.save_hostel_payment_settings(
    p_school TEXT,
    p_email_domains TEXT[],
    p_paybill_number TEXT,
    p_paybill_account_hint TEXT,
    p_bank_name TEXT,
    p_bank_branch TEXT,
    p_bank_account_name TEXT,
    p_bank_account_number TEXT,
    p_payment_note TEXT DEFAULT ''
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_school TEXT := LEFT(BTRIM(COALESCE(p_school, '')), 100);
    v_domains TEXT[];
BEGIN
    IF v_school = '' OR NOT public.is_school_staff(LOWER(BTRIM(v_school))) THEN
        RAISE EXCEPTION 'Only the school housing office can change hostel payment settings.'
            USING ERRCODE = '42501';
    END IF;

    SELECT COALESCE(ARRAY_AGG(domain), ARRAY[]::TEXT[])
      INTO v_domains
      FROM (
          SELECT DISTINCT LOWER(LTRIM(BTRIM(value), '@')) AS domain
            FROM UNNEST(COALESCE(p_email_domains, ARRAY[]::TEXT[])) AS domains(value)
           WHERE BTRIM(value) <> ''
           LIMIT 20
      ) AS cleaned
     WHERE domain ~ '^[a-z0-9]+([.-][a-z0-9]+)*\.[a-z]{2,}$';

    IF cardinality(v_domains) = 0 THEN
        RAISE EXCEPTION 'Add at least one official student email domain.' USING ERRCODE = '22023';
    END IF;
    IF BTRIM(COALESCE(p_paybill_number, '')) = ''
       AND BTRIM(COALESCE(p_bank_account_number, '')) = '' THEN
        RAISE EXCEPTION 'Add the school''s Paybill number or bank account.' USING ERRCODE = '22023';
    END IF;

    INSERT INTO public.campus_services (
        school, updated_by, student_email_domains, hostel_paybill_number,
        hostel_paybill_account_hint, hostel_bank_name, hostel_bank_branch,
        hostel_bank_account_name, hostel_bank_account_number, hostel_payment_note
    ) VALUES (
        v_school, auth.uid(), v_domains,
        LEFT(BTRIM(COALESCE(p_paybill_number, '')), 40),
        LEFT(BTRIM(COALESCE(p_paybill_account_hint, 'Student registration number')), 120),
        LEFT(BTRIM(COALESCE(p_bank_name, '')), 100),
        LEFT(BTRIM(COALESCE(p_bank_branch, '')), 100),
        LEFT(BTRIM(COALESCE(p_bank_account_name, '')), 120),
        LEFT(BTRIM(COALESCE(p_bank_account_number, '')), 60),
        LEFT(BTRIM(COALESCE(p_payment_note, '')), 400)
    ) ON CONFLICT (school_key) DO UPDATE SET
        updated_by = EXCLUDED.updated_by,
        student_email_domains = EXCLUDED.student_email_domains,
        hostel_paybill_number = EXCLUDED.hostel_paybill_number,
        hostel_paybill_account_hint = EXCLUDED.hostel_paybill_account_hint,
        hostel_bank_name = EXCLUDED.hostel_bank_name,
        hostel_bank_branch = EXCLUDED.hostel_bank_branch,
        hostel_bank_account_name = EXCLUDED.hostel_bank_account_name,
        hostel_bank_account_number = EXCLUDED.hostel_bank_account_number,
        hostel_payment_note = EXCLUDED.hostel_payment_note,
        updated_at = NOW();
END;
$$;

REVOKE ALL ON FUNCTION public.save_hostel_payment_settings(TEXT, TEXT[], TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT)
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_hostel_payment_settings(TEXT, TEXT[], TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT)
    TO authenticated;

CREATE OR REPLACE FUNCTION public.hostel_room_availability(p_school_key TEXT, p_semester TEXT)
RETURNS TABLE (room_id UUID, beds_available INT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT r.id,
           GREATEST(r.capacity - COUNT(b.id)::INT, 0)
      FROM public.hostel_rooms AS r
      JOIN public.hostels AS h ON h.id = r.hostel_id
      LEFT JOIN public.hostel_bookings AS b
        ON b.room_id = r.id
       AND LOWER(BTRIM(b.semester)) = LOWER(BTRIM(p_semester))
       AND b.status IN ('pending', 'approved')
     WHERE h.school_key = LOWER(BTRIM(COALESCE(p_school_key, '')))
     GROUP BY r.id, r.capacity;
$$;

REVOKE ALL ON FUNCTION public.hostel_room_availability(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.hostel_room_availability(TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.book_hostel_room(
    p_room_id UUID,
    p_semester TEXT,
    p_note TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_role TEXT;
    v_profile_school TEXT;
    v_email TEXT;
    v_email_confirmed TIMESTAMPTZ;
    v_email_domain TEXT;
    v_registration_number TEXT;
    v_school TEXT;
    v_school_key TEXT;
    v_accommodation BOOLEAN;
    v_domains TEXT[];
    v_paybill TEXT;
    v_paybill_hint TEXT;
    v_bank_name TEXT;
    v_bank_branch TEXT;
    v_bank_account_name TEXT;
    v_bank_account_number TEXT;
    v_payment_note TEXT;
    v_room_label TEXT;
    v_capacity INT;
    v_fee NUMERIC(10,2);
    v_taken INT;
    v_semester TEXT := LEFT(BTRIM(COALESCE(p_semester, '')), 40);
    v_payment JSONB;
    v_booking_id UUID;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Sign in with your student account first.' USING ERRCODE = '42501';
    END IF;
    IF v_semester !~ '^.{3,40}$' THEN
        RAISE EXCEPTION 'Enter the semester, for example 2026/2027-1.' USING ERRCODE = '22023';
    END IF;

    SELECT p.role, LOWER(BTRIM(COALESCE(p.university, '')))
      INTO v_role, v_profile_school
      FROM public.profiles AS p WHERE p.id = v_uid;
    IF v_role IS DISTINCT FROM 'student' THEN
        RAISE EXCEPTION 'Only a student account can book a hostel room.' USING ERRCODE = '42501';
    END IF;

    SELECT u.email, u.email_confirmed_at INTO v_email, v_email_confirmed
      FROM auth.users AS u WHERE u.id = v_uid;
    IF v_email_confirmed IS NULL OR POSITION('@' IN COALESCE(v_email, '')) = 0 THEN
        RAISE EXCEPTION 'Confirm your university email before booking.' USING ERRCODE = '42501';
    END IF;
    v_email_domain := LOWER(SPLIT_PART(v_email, '@', 2));

    SELECT r.registration_number INTO v_registration_number
      FROM public.student_registrations AS r WHERE r.user_id = v_uid;
    IF v_registration_number IS NULL THEN
        RAISE EXCEPTION 'Add the student registration number issued by your university before booking.'
            USING ERRCODE = '42501';
    END IF;

    SELECT h.school, h.school_key, r.label, r.capacity, r.fee_semester,
           cs.accommodation, cs.student_email_domains,
           cs.hostel_paybill_number, cs.hostel_paybill_account_hint,
           cs.hostel_bank_name, cs.hostel_bank_branch,
           cs.hostel_bank_account_name, cs.hostel_bank_account_number,
           cs.hostel_payment_note
      INTO v_school, v_school_key, v_room_label, v_capacity, v_fee,
           v_accommodation, v_domains, v_paybill, v_paybill_hint,
           v_bank_name, v_bank_branch, v_bank_account_name, v_bank_account_number,
           v_payment_note
      FROM public.hostel_rooms AS r
      JOIN public.hostels AS h ON h.id = r.hostel_id
      LEFT JOIN public.campus_services AS cs ON cs.school_key = h.school_key
     WHERE r.id = p_room_id
     FOR UPDATE OF r;

    IF v_school_key IS NULL THEN
        RAISE EXCEPTION 'That room is no longer available.' USING ERRCODE = 'P0002';
    END IF;
    IF v_profile_school <> '' AND v_profile_school <> v_school_key THEN
        RAISE EXCEPTION 'Your student profile belongs to a different university.' USING ERRCODE = '42501';
    END IF;
    IF v_email_domain <> ALL(COALESCE(v_domains, ARRAY[]::TEXT[])) THEN
        RAISE EXCEPTION 'Use the confirmed student email domain configured by your university.' USING ERRCODE = '42501';
    END IF;
    IF v_accommodation IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'This university has not enabled hostel booking in Campus Connect.' USING ERRCODE = 'P0001';
    END IF;
    IF COALESCE(v_paybill, '') = '' AND COALESCE(v_bank_account_number, '') = '' THEN
        RAISE EXCEPTION 'The university has not configured hostel payment details yet.' USING ERRCODE = 'P0001';
    END IF;

    SELECT COUNT(*)::INT INTO v_taken
      FROM public.hostel_bookings AS b
     WHERE b.room_id = p_room_id
       AND LOWER(BTRIM(b.semester)) = LOWER(BTRIM(v_semester))
       AND b.status IN ('pending', 'approved');
    IF v_taken >= v_capacity THEN
        RAISE EXCEPTION 'That room has no spaces left for this semester.' USING ERRCODE = 'P0001';
    END IF;

    v_payment := JSONB_BUILD_OBJECT(
        'paybill_number', NULLIF(v_paybill, ''),
        'paybill_account_hint', v_paybill_hint,
        'bank_name', NULLIF(v_bank_name, ''),
        'bank_branch', NULLIF(v_bank_branch, ''),
        'bank_account_name', NULLIF(v_bank_account_name, ''),
        'bank_account_number', NULLIF(v_bank_account_number, ''),
        'note', v_payment_note
    );

    INSERT INTO public.hostel_bookings (
        room_id, student_id, semester, request_note, payment_status, payment_details_snapshot
    ) VALUES (
        p_room_id, v_uid, v_semester,
        LEFT(BTRIM(COALESCE(p_note, '')), 400), 'instructions_sent', v_payment
    ) RETURNING id INTO v_booking_id;

    RETURN JSONB_BUILD_OBJECT(
        'booking_id', v_booking_id,
        'school', v_school,
        'room_label', v_room_label,
        'semester', v_semester,
        'fee_semester', v_fee,
        'registration_number', v_registration_number,
        'payment_details', v_payment
    );
END;
$$;

REVOKE ALL ON FUNCTION public.book_hostel_room(UUID, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.book_hostel_room(UUID, TEXT, TEXT) TO authenticated;

-- Prevent direct table writes from bypassing university email and registration checks.
DROP POLICY IF EXISTS hostel_bookings_student_ask ON public.hostel_bookings;
REVOKE INSERT, UPDATE ON public.hostel_bookings FROM authenticated;
REVOKE SELECT ON public.hostel_bookings FROM authenticated;
-- Queries may read a roommate's basic placement under the existing RLS rule,
-- but payment references and the stored account snapshot are only returned
-- by owner/office SECURITY DEFINER RPCs below.
GRANT SELECT (
    id, room_id, student_id, semester, request_note, status, decision_note,
    decided_by, decided_at, created_at, updated_at
) ON public.hostel_bookings TO authenticated;
REVOKE ALL ON FUNCTION public.ask_for_hostel_bed(UUID, TEXT, TEXT) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.submit_hostel_payment(p_booking_id UUID, p_reference TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_status TEXT;
    v_payment_status TEXT;
BEGIN
    SELECT b.status, b.payment_status INTO v_status, v_payment_status
      FROM public.hostel_bookings AS b
     WHERE b.id = p_booking_id AND b.student_id = auth.uid()
     FOR UPDATE;
    IF v_status IS NULL THEN RAISE EXCEPTION 'No such booking.' USING ERRCODE = 'P0002'; END IF;
    IF v_status <> 'pending' OR v_payment_status NOT IN ('instructions_sent', 'rejected') THEN
        RAISE EXCEPTION 'This booking is not waiting for a payment reference.' USING ERRCODE = 'P0001';
    END IF;
    IF LENGTH(BTRIM(COALESCE(p_reference, ''))) NOT BETWEEN 4 AND 120 THEN
        RAISE EXCEPTION 'Enter the M-Pesa transaction code or bank payment reference.' USING ERRCODE = '22023';
    END IF;
    UPDATE public.hostel_bookings
       SET payment_reference = LEFT(BTRIM(p_reference), 120),
           payment_status = 'submitted', payment_submitted_at = NOW(),
           payment_review_note = '', payment_reviewed_at = NULL, payment_reviewed_by = NULL
     WHERE id = p_booking_id;
    RETURN 'submitted';
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_hostel_booking(p_booking_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_status TEXT;
BEGIN
    UPDATE public.hostel_bookings
       SET status = 'cancelled',
           decision_note = 'Cancelled by the student.',
           decided_at = NOW(),
           decided_by = auth.uid()
     WHERE id = p_booking_id
       AND student_id = auth.uid()
       AND status IN ('pending', 'approved')
    RETURNING status INTO v_status;
    IF v_status IS NULL THEN
        RAISE EXCEPTION 'This booking cannot be cancelled.' USING ERRCODE = 'P0001';
    END IF;
    RETURN v_status;
END;
$$;

CREATE OR REPLACE FUNCTION public.review_hostel_payment(
    p_booking_id UUID, p_verified BOOLEAN, p_note TEXT DEFAULT ''
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_school_key TEXT;
    v_payment_status TEXT;
    v_next TEXT := CASE WHEN p_verified THEN 'verified' ELSE 'rejected' END;
BEGIN
    SELECT h.school_key, b.payment_status INTO v_school_key, v_payment_status
      FROM public.hostel_bookings AS b
      JOIN public.hostel_rooms AS r ON r.id = b.room_id
      JOIN public.hostels AS h ON h.id = r.hostel_id
     WHERE b.id = p_booking_id FOR UPDATE OF b, r;
    IF v_school_key IS NULL THEN RAISE EXCEPTION 'No such booking.' USING ERRCODE = 'P0002'; END IF;
    IF NOT public.is_school_staff(v_school_key) THEN
        RAISE EXCEPTION 'Only that university housing office can review payment.' USING ERRCODE = '42501';
    END IF;
    IF v_payment_status <> 'submitted' THEN
        RAISE EXCEPTION 'The student has not submitted a payment reference.' USING ERRCODE = 'P0001';
    END IF;
    UPDATE public.hostel_bookings
       SET payment_status = v_next,
           payment_review_note = LEFT(BTRIM(COALESCE(p_note, '')), 400),
           payment_reviewed_at = NOW(), payment_reviewed_by = auth.uid()
     WHERE id = p_booking_id;
    RETURN v_next;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_hostel_payment(UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.cancel_hostel_booking(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.review_hostel_payment(UUID, BOOLEAN, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_hostel_payment(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_hostel_booking(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_hostel_payment(UUID, BOOLEAN, TEXT) TO authenticated;

-- Replace the office decision function so a bed cannot be confirmed before
-- the submitted payment reference has been checked by the housing office.
CREATE OR REPLACE FUNCTION public.decide_hostel_booking(
    p_booking_id UUID, p_decision TEXT, p_note TEXT DEFAULT ''
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_room UUID; v_school TEXT; v_semester TEXT; v_taken INT; v_capacity INT;
    v_payment_status TEXT;
BEGIN
    IF p_decision NOT IN ('approved', 'rejected', 'cancelled') THEN
        RAISE EXCEPTION 'That decision is not one the housing office can make.' USING ERRCODE = '22023';
    END IF;
    SELECT r.id, h.school_key, b.semester, b.payment_status
      INTO v_room, v_school, v_semester, v_payment_status
      FROM public.hostel_bookings AS b
      JOIN public.hostel_rooms AS r ON r.id = b.room_id
      JOIN public.hostels AS h ON h.id = r.hostel_id
     WHERE b.id = p_booking_id FOR UPDATE OF b, r;
    IF v_room IS NULL THEN RAISE EXCEPTION 'No such booking.' USING ERRCODE = 'P0002'; END IF;
    IF NOT public.is_school_staff(v_school) THEN
        RAISE EXCEPTION 'Only the housing office of that school can decide a bed.' USING ERRCODE = '42501';
    END IF;
    IF p_decision = 'approved' AND v_payment_status <> 'verified' THEN
        RAISE EXCEPTION 'Verify the payment reference before approving this room.' USING ERRCODE = 'P0001';
    END IF;
    IF p_decision = 'approved' THEN
        SELECT capacity INTO v_capacity FROM public.hostel_rooms WHERE id = v_room;
        SELECT COUNT(*)::INT INTO v_taken FROM public.hostel_bookings
         WHERE room_id = v_room AND LOWER(BTRIM(semester)) = LOWER(BTRIM(v_semester))
           AND status = 'approved' AND id <> p_booking_id;
        IF v_taken >= v_capacity THEN
            RAISE EXCEPTION 'That room is full for % - % of % beds are already approved.', v_semester, v_taken, v_capacity
                USING ERRCODE = 'P0001';
        END IF;
    END IF;
    UPDATE public.hostel_bookings SET status = p_decision,
           decision_note = LEFT(BTRIM(COALESCE(p_note, '')), 400),
           decided_by = auth.uid(), decided_at = NOW()
     WHERE id = p_booking_id;
    RETURN p_decision;
END;
$$;

-- Recreate the two list RPCs with payment fields, without exposing other
-- students' payment data through direct table access.
DROP FUNCTION IF EXISTS public.my_bed_requests();
CREATE FUNCTION public.my_bed_requests()
RETURNS TABLE (
    booking_id UUID, hostel_name TEXT, room_label TEXT, room_capacity INT,
    school TEXT, semester TEXT, status TEXT, request_note TEXT, decision_note TEXT,
    decided_at TIMESTAMPTZ, created_at TIMESTAMPTZ, payment_status TEXT,
    payment_reference TEXT, payment_review_note TEXT, payment_details JSONB,
    registration_number TEXT
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
    SELECT b.id, h.name, r.label, r.capacity, h.school, b.semester, b.status,
           b.request_note, b.decision_note, b.decided_at, b.created_at,
           b.payment_status, b.payment_reference, b.payment_review_note,
           b.payment_details_snapshot, sr.registration_number
      FROM public.hostel_bookings b
      JOIN public.hostel_rooms r ON r.id = b.room_id
      JOIN public.hostels h ON h.id = r.hostel_id
      LEFT JOIN public.student_registrations sr ON sr.user_id = b.student_id
     WHERE b.student_id = auth.uid()
     ORDER BY b.created_at DESC LIMIT 40;
$$;

DROP FUNCTION IF EXISTS public.school_bed_requests(TEXT);
CREATE FUNCTION public.school_bed_requests(p_school_key TEXT)
RETURNS TABLE (
    booking_id UUID, student_id UUID, student_name TEXT, registration_number TEXT,
    hostel_name TEXT, room_label TEXT, room_capacity INT, beds_approved INT,
    semester TEXT, status TEXT, request_note TEXT, decided_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ, payment_status TEXT, payment_reference TEXT,
    payment_review_note TEXT
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
BEGIN
    IF NOT public.is_school_staff(p_school_key) THEN
        RAISE EXCEPTION 'Only the housing office of that school sees its requests.' USING ERRCODE = '42501';
    END IF;
    RETURN QUERY
    SELECT b.id, b.student_id, p.full_name, sr.registration_number,
           h.name, r.label, r.capacity,
           (SELECT COUNT(*)::INT FROM public.hostel_bookings x
             WHERE x.room_id = b.room_id AND x.status = 'approved'
               AND LOWER(BTRIM(x.semester)) = LOWER(BTRIM(b.semester))),
           b.semester, b.status, b.request_note, b.decided_at, b.created_at,
           b.payment_status, b.payment_reference, b.payment_review_note
      FROM public.hostel_bookings b
      JOIN public.hostel_rooms r ON r.id = b.room_id
      JOIN public.hostels h ON h.id = r.hostel_id
      JOIN public.profiles p ON p.id = b.student_id
      LEFT JOIN public.student_registrations sr ON sr.user_id = b.student_id
     WHERE h.school_key = LOWER(BTRIM(COALESCE(p_school_key, '')))
     ORDER BY b.created_at DESC LIMIT 200;
END;
$$;

REVOKE ALL ON FUNCTION public.my_bed_requests() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.school_bed_requests(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.my_bed_requests() TO authenticated;
GRANT EXECUTE ON FUNCTION public.school_bed_requests(TEXT) TO authenticated;

NOTIFY pgrst, 'reload schema';
