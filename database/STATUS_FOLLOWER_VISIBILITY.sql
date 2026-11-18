-- Opt-in follower visibility for active statuses.
-- Run once against the connected Supabase project before installing app v1.65.
BEGIN;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS allow_follower_statuses BOOLEAN NOT NULL DEFAULT FALSE;

CREATE OR REPLACE FUNCTION public.can_view_story_from_follower(
    p_author_id UUID,
    p_viewer_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT COALESCE(
        p_author_id IS NOT NULL
        AND p_viewer_id = (SELECT auth.uid())
        AND p_author_id <> p_viewer_id
        AND NOT public.is_blocked_between(p_author_id, p_viewer_id)
        AND EXISTS (
            SELECT 1
            FROM public.profiles AS author
            WHERE author.id = p_author_id
              AND author.allow_follower_statuses
        )
        AND EXISTS (
            SELECT 1
            FROM public.follows AS relationship
            WHERE relationship.follower_id = p_viewer_id
              AND relationship.following_id = p_author_id
        ),
        FALSE
    );
$$;

CREATE OR REPLACE FUNCTION public.get_story_author_profiles(p_user_ids UUID[])
RETURNS TABLE (id UUID, username TEXT, full_name TEXT, avatar_url TEXT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT profile.id, profile.username, profile.full_name, profile.avatar_url
    FROM public.profiles AS profile
    WHERE (SELECT auth.uid()) IS NOT NULL
      AND profile.id = ANY(COALESCE(p_user_ids, ARRAY[]::UUID[]))
      AND EXISTS (
          SELECT 1
          FROM public.stories AS story
          WHERE story.user_id = profile.id
            AND story.expires_at > NOW()
            AND (
                story.user_id = (SELECT auth.uid())
                OR public.are_mutual_connections(story.user_id, (SELECT auth.uid()))
                OR public.can_view_story_from_follower(story.user_id, (SELECT auth.uid()))
            )
      );
$$;

REVOKE ALL ON FUNCTION public.can_view_story_from_follower(UUID, UUID)
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_view_story_from_follower(UUID, UUID)
    TO authenticated;
REVOKE ALL ON FUNCTION public.get_story_author_profiles(UUID[])
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_story_author_profiles(UUID[])
    TO authenticated;

DROP POLICY IF EXISTS "Authenticated users view stories" ON public.stories;
CREATE POLICY "Authenticated users view stories"
    ON public.stories FOR SELECT TO authenticated
    USING (
        expires_at > NOW()
        AND (
            user_id = (SELECT auth.uid())
            OR public.are_mutual_connections(user_id, (SELECT auth.uid()))
            OR public.can_view_story_from_follower(user_id, (SELECT auth.uid()))
        )
    );

COMMIT;
