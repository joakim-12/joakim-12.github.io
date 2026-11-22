-- Official university designations. A member can request one or more labels,
-- but only the app administrator can approve and publish them.
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS staff_titles TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_staff_titles_check'
                   AND conrelid = 'public.profiles'::regclass) THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_staff_titles_check
            CHECK (staff_titles <@ ARRAY['dean','school_dean','provost','vice_chancellor','finance_manager','housing_officer']::TEXT[]);
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.staff_designation_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    school TEXT NOT NULL CHECK (char_length(BTRIM(school)) BETWEEN 2 AND 120),
    titles TEXT[] NOT NULL CHECK (cardinality(titles) BETWEEN 1 AND 6),
    faculty TEXT NOT NULL DEFAULT '' CHECK (char_length(faculty) <= 120),
    department TEXT NOT NULL DEFAULT '' CHECK (char_length(department) <= 120),
    staff_id_number TEXT NOT NULL CHECK (char_length(BTRIM(staff_id_number)) BETWEEN 3 AND 48),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
    review_note TEXT NOT NULL DEFAULT '' CHECK (char_length(review_note) <= 400),
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    CONSTRAINT staff_designation_titles_check CHECK (
        titles <@ ARRAY['dean','school_dean','provost','vice_chancellor','finance_manager','housing_officer']::TEXT[]
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS staff_designation_one_pending_per_user
    ON public.staff_designation_requests(user_id) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS staff_designation_school_idx
    ON public.staff_designation_requests(LOWER(BTRIM(school)), status, created_at);

ALTER TABLE public.staff_designation_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS staff_designation_requests_read ON public.staff_designation_requests;
CREATE POLICY staff_designation_requests_read ON public.staff_designation_requests
    FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.is_admin());
DROP POLICY IF EXISTS staff_designation_requests_submit ON public.staff_designation_requests;
CREATE POLICY staff_designation_requests_submit ON public.staff_designation_requests
    FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid() AND status = 'pending');
REVOKE ALL ON public.staff_designation_requests FROM anon, public;
GRANT SELECT, INSERT ON public.staff_designation_requests TO authenticated;

CREATE OR REPLACE FUNCTION public.guard_staff_designation_request()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_profile public.profiles%ROWTYPE;
BEGIN
    IF auth.uid() IS NULL OR public.is_admin() THEN RETURN NEW; END IF;
    IF TG_OP <> 'INSERT' OR NEW.user_id <> auth.uid() OR NEW.status <> 'pending' THEN
        RAISE EXCEPTION 'Staff designations can only be submitted for your own account.' USING ERRCODE = '42501';
    END IF;
    SELECT * INTO v_profile FROM public.profiles WHERE id = auth.uid();
    IF v_profile.role NOT IN ('lecturer','chaplain','security')
       OR v_profile.verification_status <> 'approved'
       OR COALESCE(v_profile.employment_status, 'active') <> 'active'
       OR COALESCE(BTRIM(v_profile.staff_id_number), '') = ''
       OR LOWER(BTRIM(v_profile.university)) <> LOWER(BTRIM(NEW.school)) THEN
        RAISE EXCEPTION 'Complete staff verification and use your university on your staff profile first.' USING ERRCODE = '42501';
    END IF;
    IF EXISTS (SELECT 1 FROM UNNEST(NEW.titles) AS title WHERE title = ANY(v_profile.staff_titles)) THEN
        RAISE EXCEPTION 'Your account already has one of these approved designations.' USING ERRCODE = '23505';
    END IF;
    NEW.staff_id_number := BTRIM(NEW.staff_id_number);
    NEW.school := BTRIM(NEW.school);
    NEW.faculty := BTRIM(COALESCE(NEW.faculty, ''));
    NEW.department := BTRIM(COALESCE(NEW.department, ''));
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS staff_designation_request_guard ON public.staff_designation_requests;
CREATE TRIGGER staff_designation_request_guard BEFORE INSERT OR UPDATE
    ON public.staff_designation_requests FOR EACH ROW EXECUTE FUNCTION public.guard_staff_designation_request();
REVOKE ALL ON FUNCTION public.guard_staff_designation_request() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.guard_profile_staff_titles()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
    IF auth.uid() IS NOT NULL AND NEW.staff_titles IS DISTINCT FROM OLD.staff_titles
       AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only an administrator can publish verified university designations.' USING ERRCODE = '42501';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS profiles_guard_staff_titles ON public.profiles;
CREATE TRIGGER profiles_guard_staff_titles BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.guard_profile_staff_titles();
REVOKE ALL ON FUNCTION public.guard_profile_staff_titles() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.review_staff_designation_request(p_request_id UUID, p_approve BOOLEAN, p_note TEXT DEFAULT '')
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_request public.staff_designation_requests%ROWTYPE;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only an app administrator can verify a university designation.' USING ERRCODE = '42501';
    END IF;
    SELECT * INTO v_request FROM public.staff_designation_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'No such staff designation request.' USING ERRCODE = 'P0002'; END IF;
    IF v_request.status <> 'pending' THEN RAISE EXCEPTION 'This designation was already reviewed.' USING ERRCODE = 'P0001'; END IF;
    UPDATE public.staff_designation_requests SET
        status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
        review_note = LEFT(BTRIM(COALESCE(p_note, '')), 400),
        reviewed_by = auth.uid(), reviewed_at = NOW()
      WHERE id = p_request_id;
    IF p_approve THEN
        UPDATE public.profiles SET staff_titles = ARRAY(
            SELECT DISTINCT title FROM UNNEST(COALESCE(staff_titles, ARRAY[]::TEXT[]) || v_request.titles) AS title
            ORDER BY title
        ) WHERE id = v_request.user_id;
    END IF;
    RETURN CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END;
END;
$$;
REVOKE ALL ON FUNCTION public.review_staff_designation_request(UUID, BOOLEAN, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.review_staff_designation_request(UUID, BOOLEAN, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.is_housing_office(p_school_key TEXT)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
    SELECT COALESCE((
        SELECT p.role = 'admin' OR (
            'housing_officer' = ANY(COALESCE(p.staff_titles, ARRAY[]::TEXT[]))
            AND p.employment_status = 'active'
            AND LOWER(BTRIM(p.university)) = LOWER(BTRIM(COALESCE(p_school_key, '')))
        ) FROM public.profiles p WHERE p.id = auth.uid()
    ), FALSE);
$$;
REVOKE ALL ON FUNCTION public.is_housing_office(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_housing_office(TEXT) TO authenticated;

-- The housing office alone may read all student requests, edit room inventory,
-- verify payments, or confirm beds. Other staff roles retain their own service tools.
DROP POLICY IF EXISTS hostels_staff_write ON public.hostels;
CREATE POLICY hostels_staff_write ON public.hostels FOR INSERT TO authenticated
    WITH CHECK (added_by = auth.uid() AND public.is_housing_office(school_key));
DROP POLICY IF EXISTS hostels_staff_edit ON public.hostels;
CREATE POLICY hostels_staff_edit ON public.hostels FOR UPDATE TO authenticated
    USING (public.is_housing_office(school_key)) WITH CHECK (public.is_housing_office(school_key));
DROP POLICY IF EXISTS hostels_staff_remove ON public.hostels;
CREATE POLICY hostels_staff_remove ON public.hostels FOR DELETE TO authenticated
    USING (public.is_housing_office(school_key));

DROP POLICY IF EXISTS hostel_rooms_staff_write ON public.hostel_rooms;
CREATE POLICY hostel_rooms_staff_write ON public.hostel_rooms FOR INSERT TO authenticated
    WITH CHECK (EXISTS (SELECT 1 FROM public.hostels h WHERE h.id = hostel_rooms.hostel_id AND public.is_housing_office(h.school_key)));
DROP POLICY IF EXISTS hostel_rooms_staff_edit ON public.hostel_rooms;
CREATE POLICY hostel_rooms_staff_edit ON public.hostel_rooms FOR UPDATE TO authenticated
    USING (EXISTS (SELECT 1 FROM public.hostels h WHERE h.id = hostel_rooms.hostel_id AND public.is_housing_office(h.school_key)))
    WITH CHECK (EXISTS (SELECT 1 FROM public.hostels h WHERE h.id = hostel_rooms.hostel_id AND public.is_housing_office(h.school_key)));
DROP POLICY IF EXISTS hostel_rooms_staff_remove ON public.hostel_rooms;
CREATE POLICY hostel_rooms_staff_remove ON public.hostel_rooms FOR DELETE TO authenticated
    USING (EXISTS (SELECT 1 FROM public.hostels h WHERE h.id = hostel_rooms.hostel_id AND public.is_housing_office(h.school_key)));

DROP POLICY IF EXISTS hostel_bookings_own ON public.hostel_bookings;
CREATE POLICY hostel_bookings_own ON public.hostel_bookings FOR SELECT TO authenticated USING (
    student_id = auth.uid() OR public.is_admin() OR EXISTS (
        SELECT 1 FROM public.hostel_rooms r JOIN public.hostels h ON h.id = r.hostel_id
        WHERE r.id = hostel_bookings.room_id AND public.is_housing_office(h.school_key)
    ) OR EXISTS (
        SELECT 1 FROM public.my_approved_beds() mine WHERE mine.room_id = hostel_bookings.room_id
          AND mine.semester_key = LOWER(BTRIM(hostel_bookings.semester))
    )
);
DROP POLICY IF EXISTS hostel_bookings_office_edit ON public.hostel_bookings;
CREATE POLICY hostel_bookings_office_edit ON public.hostel_bookings FOR UPDATE TO authenticated
    USING (EXISTS (SELECT 1 FROM public.hostel_rooms r JOIN public.hostels h ON h.id = r.hostel_id
        WHERE r.id = hostel_bookings.room_id AND public.is_housing_office(h.school_key)))
    WITH CHECK (status IN ('approved','rejected','cancelled'));

DO $$
DECLARE v_function TEXT;
BEGIN
    FOREACH v_function IN ARRAY ARRAY[
        'public.decide_hostel_booking(uuid,text,text)',
        'public.school_bed_requests(text)',
        'public.review_hostel_payment(uuid,boolean,text)',
        'public.save_hostel_payment_settings(text,text[],text,text,text,text,text,text,text)'
    ] LOOP
        IF to_regprocedure(v_function) IS NOT NULL THEN
            EXECUTE replace(pg_get_functiondef(to_regprocedure(v_function)),
                'public.is_school_staff(', 'public.is_housing_office(');
        END IF;
    END LOOP;
END;
$$;

NOTIFY pgrst, 'reload schema';


-- Final booking and lecturer credential hardening
-- Prevent direct room booking edits and require verified lecturer documents.
-- All booking changes must use the SECURITY DEFINER RPCs, which enforce the
-- student, payment, capacity, and housing-office checks.

DO $$
DECLARE
    policy_row RECORD;
BEGIN
    -- Keep read policies; remove every direct write policy so that an old
    -- permissive student policy cannot combine with a newer manager policy.
    FOR policy_row IN
        SELECT policyname
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'hostel_bookings'
          AND cmd <> 'SELECT'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.hostel_bookings', policy_row.policyname);
    END LOOP;
END;
$$;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
    ON public.hostel_bookings FROM PUBLIC, anon, authenticated;

-- Lecturer designation is only granted through review_lecturer_submission,
-- which validates the three required documents and their private file paths.
CREATE OR REPLACE FUNCTION public.approve_membership(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    requested TEXT;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only an admin can approve a role request.'
            USING ERRCODE = '42501';
    END IF;

    SELECT requested_role INTO requested
      FROM public.profiles WHERE id = p_user_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No such member.' USING ERRCODE = 'P0002';
    END IF;
    IF requested = 'lecturer' THEN
        RAISE EXCEPTION 'Review the lecturer documents in the staff verification queue.'
            USING ERRCODE = '42501';
    END IF;

    UPDATE public.profiles
       SET verification_status = 'approved',
           role = CASE WHEN requested_role IN ('security', 'chaplain')
                       THEN requested_role ELSE role END,
           requested_role = ''
     WHERE id = p_user_id;

    INSERT INTO public.admin_action_log (actor_id, target_user_id, action)
        VALUES (auth.uid(), p_user_id, 'approve');
END;
$$;

CREATE OR REPLACE FUNCTION public.set_user_role(p_user_id UUID, p_role TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    target public.profiles%ROWTYPE;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only an admin can change a role.'
            USING ERRCODE = '42501';
    END IF;
    IF p_role NOT IN ('student', 'lecturer', 'security', 'admin', 'member', 'chaplain') THEN
        RAISE EXCEPTION 'Unknown role.' USING ERRCODE = '22023';
    END IF;

    SELECT * INTO target FROM public.profiles WHERE id = p_user_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No such member.' USING ERRCODE = 'P0002';
    END IF;
    IF p_role = 'lecturer' AND NOT EXISTS (
        SELECT 1 FROM public.lecturer_submissions s
         WHERE s.user_id = p_user_id
           AND s.status = 'approved'
           AND public.normalize_id_number(s.staff_id_number) =
               public.normalize_id_number(target.staff_id_number)
           AND s.national_id_number <> ''
           AND s.national_id_path <> ''
           AND s.staff_id_path <> ''
           AND s.introduction_letter_path <> ''
    ) THEN
        RAISE EXCEPTION 'A lecturer can only be enabled after all required documents are reviewed and approved.'
            USING ERRCODE = '42501';
    END IF;
    IF p_role <> 'admin' AND target.role = 'admin'
       AND (SELECT COUNT(*) FROM public.profiles WHERE role = 'admin') <= 1 THEN
        RAISE EXCEPTION 'That is the last admin. Appoint another admin first.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE public.profiles
       SET role = p_role,
           verification_status = 'approved',
           requested_role = ''
     WHERE id = p_user_id;

    INSERT INTO public.admin_action_log (actor_id, target_user_id, action, detail)
        VALUES (auth.uid(), p_user_id, 'set_role', p_role);
END;
$$;

REVOKE ALL ON FUNCTION public.approve_membership(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.set_user_role(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.approve_membership(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_user_role(UUID, TEXT) TO authenticated;

-- Keep booking management behind the manager-only RPCs. A generic direct
-- UPDATE policy is unnecessary and can be abused to edit decision fields.
DROP POLICY IF EXISTS hostel_bookings_office_edit ON public.hostel_bookings;

DO $$
DECLARE
    signature TEXT;
BEGIN
    FOREACH signature IN ARRAY ARRAY[
        'public.decide_hostel_booking(uuid,text,text)',
        'public.school_bed_requests(text)',
        'public.review_hostel_payment(uuid,boolean,text)',
        'public.save_hostel_payment_settings(text,text[],text,text,text,text,text,text,text)'
    ] LOOP
        IF to_regprocedure(signature) IS NOT NULL THEN
            EXECUTE replace(pg_get_functiondef(to_regprocedure(signature)),
                'public.is_school_staff(', 'public.is_housing_office(');
        END IF;
    END LOOP;
END;
$$;

NOTIFY pgrst, 'reload schema';
