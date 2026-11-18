-- Hostel student booking RPCs used by the Campus Services page.
-- Registration number and school membership are checked server-side.

CREATE OR REPLACE FUNCTION public.hostel_room_availability(
    p_school_key TEXT,
    p_semester TEXT
)
RETURNS TABLE (room_id UUID, beds_available INTEGER)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
    SELECT r.id,
           GREATEST(r.capacity - COUNT(b.id)::INTEGER, 0) AS beds_available
      FROM public.hostel_rooms r
      JOIN public.hostels h ON h.id = r.hostel_id
      LEFT JOIN public.hostel_bookings b
        ON b.room_id = r.id
       AND b.status = 'approved'
       AND b.payment_status = 'verified'
       AND b.semester_ends_at > NOW()
       AND LOWER(BTRIM(b.semester)) = LOWER(BTRIM(COALESCE(p_semester, '')))
     WHERE h.school_key = LOWER(BTRIM(COALESCE(p_school_key, '')))
       AND h.verified
     GROUP BY r.id, r.capacity
     HAVING r.capacity - COUNT(b.id)::INTEGER > 0
     ORDER BY r.id
$$;

CREATE OR REPLACE FUNCTION public.book_hostel_room(
    p_room_id UUID,
    p_semester TEXT,
    p_note TEXT DEFAULT ''
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
    v_user UUID := auth.uid();
    v_school_key TEXT;
    v_school TEXT;
    v_university TEXT;
    v_registration TEXT;
    v_capacity INTEGER;
    v_taken INTEGER;
    v_booking UUID;
    v_semester TEXT := BTRIM(COALESCE(p_semester, ''));
BEGIN
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'Sign in before requesting a room.' USING ERRCODE = '42501';
    END IF;
    IF char_length(v_semester) < 3 OR char_length(v_semester) > 40 THEN
        RAISE EXCEPTION 'Enter the semester, for example 2026/2027-1.' USING ERRCODE = '22023';
    END IF;

    SELECT p.university, sr.registration_number
      INTO v_university, v_registration
      FROM public.profiles p
      LEFT JOIN public.student_registrations sr ON sr.user_id = p.id
     WHERE p.id = v_user;
    IF NULLIF(BTRIM(v_registration), '') IS NULL THEN
        RAISE EXCEPTION 'Add your student registration number before booking.' USING ERRCODE = 'P0001';
    END IF;

    SELECT h.school_key, h.school, r.capacity
      INTO v_school_key, v_school, v_capacity
      FROM public.hostel_rooms r
      JOIN public.hostels h ON h.id = r.hostel_id
     WHERE r.id = p_room_id AND h.verified
     FOR UPDATE OF r;
    IF v_school_key IS NULL THEN
        RAISE EXCEPTION 'That hostel room is not available.' USING ERRCODE = 'P0002';
    END IF;
    IF LOWER(BTRIM(COALESCE(v_university, ''))) <> v_school_key THEN
        RAISE EXCEPTION 'Your profile must belong to this school before you book.' USING ERRCODE = '42501';
    END IF;
    IF EXISTS (
        SELECT 1 FROM public.hostel_bookings b
         WHERE b.student_id = v_user AND LOWER(BTRIM(b.semester)) = LOWER(v_semester)
           AND b.status IN ('pending', 'approved') AND b.semester_ends_at > NOW()
    ) THEN
        RAISE EXCEPTION 'You already have a room request for this semester.' USING ERRCODE = '23505';
    END IF;

    SELECT COUNT(*)::INTEGER INTO v_taken
      FROM public.hostel_bookings b
     WHERE b.room_id = p_room_id AND b.status = 'approved'
       AND b.payment_status = 'verified' AND b.semester_ends_at > NOW()
       AND LOWER(BTRIM(b.semester)) = LOWER(v_semester);
    IF v_taken >= v_capacity THEN
        RAISE EXCEPTION 'That room has no available beds.' USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO public.hostel_bookings
        (room_id, student_id, semester, status, request_note,
         semester_started_at, semester_ends_at, payment_status)
    VALUES
        (p_room_id, v_user, v_semester, 'pending', LEFT(BTRIM(COALESCE(p_note, '')), 400),
         NOW(), NOW() + INTERVAL '6 months', 'unpaid')
    RETURNING id INTO v_booking;
    RETURN v_booking;
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_hostel_booking(p_booking_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_changed INTEGER;
BEGIN
    UPDATE public.hostel_bookings
       SET status = 'cancelled', updated_at = NOW()
     WHERE id = p_booking_id AND student_id = auth.uid()
       AND status IN ('pending', 'approved')
       AND payment_status IN ('unpaid', 'rejected', 'expired')
       AND semester_ends_at > NOW();
    GET DIAGNOSTICS v_changed = ROW_COUNT;
    RETURN v_changed = 1;
END;
$$;

REVOKE ALL ON FUNCTION public.hostel_room_availability(TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.book_hostel_room(UUID, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.cancel_hostel_booking(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.hostel_room_availability(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.book_hostel_room(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_hostel_booking(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';

