-- Student requests for campus full-board and half-board meal subscriptions.
CREATE TABLE IF NOT EXISTS public.meal_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    meal_plan_id UUID NOT NULL REFERENCES public.meal_plans(id) ON DELETE RESTRICT,
    school TEXT NOT NULL,
    school_key TEXT GENERATED ALWAYS AS (LOWER(BTRIM(school))) STORED,
    semester TEXT NOT NULL CHECK (char_length(BTRIM(semester)) BETWEEN 3 AND 40),
    status TEXT NOT NULL DEFAULT 'requested'
        CHECK (status IN ('requested', 'active', 'rejected', 'cancelled', 'expired')),
    starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ends_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '6 months'),
    decision_note TEXT NOT NULL DEFAULT '' CHECK (char_length(decision_note) <= 400),
    decided_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    decided_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS meal_subscriptions_student_idx
    ON public.meal_subscriptions (student_id, created_at DESC);
CREATE INDEX IF NOT EXISTS meal_subscriptions_school_status_idx
    ON public.meal_subscriptions (school_key, status, created_at DESC);

ALTER TABLE public.meal_subscriptions ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.meal_subscriptions TO authenticated;
REVOKE ALL ON public.meal_subscriptions FROM anon, PUBLIC;

DROP POLICY IF EXISTS meal_subscriptions_read_v1 ON public.meal_subscriptions;
CREATE POLICY meal_subscriptions_read_v1 ON public.meal_subscriptions
    FOR SELECT TO authenticated
    USING (student_id = auth.uid() OR public.is_school_staff(school_key));

CREATE OR REPLACE FUNCTION public.request_meal_subscription_v1(
    p_meal_plan_id UUID,
    p_semester TEXT
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
    v_user UUID := auth.uid();
    v_school TEXT;
    v_school_key TEXT;
    v_university TEXT;
    v_registration TEXT;
    v_id UUID;
    v_semester TEXT := BTRIM(COALESCE(p_semester, ''));
BEGIN
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'Sign in before requesting a meal plan.' USING ERRCODE = '42501';
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
        RAISE EXCEPTION 'Add your student registration number before subscribing.' USING ERRCODE = 'P0001';
    END IF;
    SELECT mp.school, mp.school_key
      INTO v_school, v_school_key
      FROM public.meal_plans mp
     WHERE mp.id = p_meal_plan_id
       AND (mp.starts_on IS NULL OR mp.starts_on <= CURRENT_DATE)
       AND (mp.ends_on IS NULL OR mp.ends_on >= CURRENT_DATE);
    IF v_school_key IS NULL THEN
        RAISE EXCEPTION 'That meal plan is no longer available.' USING ERRCODE = 'P0002';
    END IF;
    IF LOWER(BTRIM(COALESCE(v_university, ''))) <> v_school_key THEN
        RAISE EXCEPTION 'Your profile must belong to this school before subscribing.' USING ERRCODE = '42501';
    END IF;
    IF EXISTS (SELECT 1 FROM public.meal_subscriptions ms
               WHERE ms.student_id = v_user
                 AND LOWER(BTRIM(ms.semester)) = LOWER(v_semester)
                 AND ms.status IN ('requested', 'active') AND ms.ends_at > NOW()) THEN
        RAISE EXCEPTION 'You already have a meal-plan request for this semester.' USING ERRCODE = '23505';
    END IF;
    INSERT INTO public.meal_subscriptions (student_id, meal_plan_id, school, semester)
    VALUES (v_user, p_meal_plan_id, v_school, v_semester)
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.my_meal_subscriptions_v1()
RETURNS TABLE (
    subscription_id UUID, plan_name TEXT, plan_kind TEXT, semester TEXT, status TEXT,
    starts_at TIMESTAMPTZ, ends_at TIMESTAMPTZ, price_semester NUMERIC,
    decision_note TEXT, created_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
    UPDATE public.meal_subscriptions AS ms
       SET status = 'expired', updated_at = NOW()
     WHERE ms.student_id = auth.uid()
       AND ms.status = 'active'
       AND ms.ends_at <= NOW();
    RETURN QUERY
    SELECT ms.id, mp.name, mp.kind, ms.semester, ms.status, ms.starts_at, ms.ends_at,
           mp.price_semester, ms.decision_note, ms.created_at
      FROM public.meal_subscriptions ms
      JOIN public.meal_plans mp ON mp.id = ms.meal_plan_id
     WHERE ms.student_id = auth.uid()
     ORDER BY ms.created_at DESC LIMIT 30;
END;
$$;

CREATE OR REPLACE FUNCTION public.school_meal_subscriptions_v1(p_school_key TEXT)
RETURNS TABLE (
    subscription_id UUID, student_name TEXT, registration_number TEXT,
    plan_name TEXT, plan_kind TEXT, semester TEXT, status TEXT,
    starts_at TIMESTAMPTZ, ends_at TIMESTAMPTZ, price_semester NUMERIC,
    decision_note TEXT, created_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
    IF NOT public.is_school_staff(p_school_key) THEN
        RAISE EXCEPTION 'Only this school’s catering office can review subscriptions.' USING ERRCODE = '42501';
    END IF;
    UPDATE public.meal_subscriptions ms SET status = 'expired', updated_at = NOW()
     WHERE ms.school_key = LOWER(BTRIM(COALESCE(p_school_key, '')))
       AND ms.status = 'active' AND ms.ends_at <= NOW();
    RETURN QUERY
    SELECT ms.id, p.full_name, sr.registration_number, mp.name, mp.kind, ms.semester,
           ms.status, ms.starts_at, ms.ends_at, mp.price_semester, ms.decision_note, ms.created_at
      FROM public.meal_subscriptions ms
      JOIN public.meal_plans mp ON mp.id = ms.meal_plan_id
      JOIN public.profiles p ON p.id = ms.student_id
      LEFT JOIN public.student_registrations sr ON sr.user_id = ms.student_id
     WHERE ms.school_key = LOWER(BTRIM(COALESCE(p_school_key, '')))
     ORDER BY ms.created_at DESC LIMIT 200;
END;
$$;

CREATE OR REPLACE FUNCTION public.review_meal_subscription_v1(
    p_subscription_id UUID, p_approve BOOLEAN, p_note TEXT DEFAULT ''
)
RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_school_key TEXT; v_status TEXT;
BEGIN
    SELECT school_key, status INTO v_school_key, v_status
      FROM public.meal_subscriptions WHERE id = p_subscription_id FOR UPDATE;
    IF v_school_key IS NULL THEN RAISE EXCEPTION 'No such meal-plan request.' USING ERRCODE = 'P0002'; END IF;
    IF NOT public.is_school_staff(v_school_key) THEN
        RAISE EXCEPTION 'Only this school’s catering office can decide a subscription.' USING ERRCODE = '42501';
    END IF;
    IF v_status <> 'requested' THEN
        RAISE EXCEPTION 'This meal-plan request has already been reviewed.' USING ERRCODE = 'P0001';
    END IF;
    UPDATE public.meal_subscriptions
       SET status = CASE WHEN p_approve THEN 'active' ELSE 'rejected' END,
           starts_at = NOW(), ends_at = NOW() + INTERVAL '6 months',
           decision_note = LEFT(BTRIM(COALESCE(p_note, '')), 400),
           decided_by = auth.uid(), decided_at = NOW(), updated_at = NOW()
     WHERE id = p_subscription_id;
    RETURN CASE WHEN p_approve THEN 'active' ELSE 'rejected' END;
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_my_meal_subscription_v1(p_subscription_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_count INTEGER;
BEGIN
    UPDATE public.meal_subscriptions SET status = 'cancelled', updated_at = NOW()
     WHERE id = p_subscription_id AND student_id = auth.uid()
       AND status IN ('requested', 'active') AND ends_at > NOW();
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count = 1;
END;
$$;

REVOKE ALL ON FUNCTION public.request_meal_subscription_v1(UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.my_meal_subscriptions_v1() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.school_meal_subscriptions_v1(TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.review_meal_subscription_v1(UUID, BOOLEAN, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.cancel_my_meal_subscription_v1(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_meal_subscription_v1(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.my_meal_subscriptions_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.school_meal_subscriptions_v1(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_meal_subscription_v1(UUID, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_my_meal_subscription_v1(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
