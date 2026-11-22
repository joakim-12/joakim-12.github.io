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
