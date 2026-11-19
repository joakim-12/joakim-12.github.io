-- Disambiguate the output column `status` from meal_subscriptions.status.
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
      FROM public.meal_subscriptions AS ms
      JOIN public.meal_plans AS mp ON mp.id = ms.meal_plan_id
     WHERE ms.student_id = auth.uid()
     ORDER BY ms.created_at DESC
     LIMIT 30;
END;
$$;

REVOKE ALL ON FUNCTION public.my_meal_subscriptions_v1() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.my_meal_subscriptions_v1() TO authenticated;
NOTIFY pgrst, 'reload schema';
