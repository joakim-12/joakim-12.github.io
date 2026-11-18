-- Allow members with existing one-to-one chat history to see each other's active statuses.
-- Blocks and the 24-hour status expiry continue to apply.
BEGIN;

CREATE OR REPLACE FUNCTION public.can_view_story_from_chat(p_author_id UUID, p_viewer_id UUID)
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
            FROM public.messages AS message
            WHERE message.sender_id = p_author_id
              AND message.receiver_id = p_viewer_id
        )
        AND EXISTS (
            SELECT 1
            FROM public.messages AS message
            WHERE message.sender_id = p_viewer_id
              AND message.receiver_id = p_author_id
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
                OR public.can_view_story_from_chat(story.user_id, (SELECT auth.uid()))
            )
      );
$$;

REVOKE ALL ON FUNCTION public.can_view_story_from_chat(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_view_story_from_chat(UUID, UUID) TO authenticated;
REVOKE ALL ON FUNCTION public.get_story_author_profiles(UUID[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_story_author_profiles(UUID[]) TO authenticated;

DROP POLICY IF EXISTS "Authenticated users view stories" ON public.stories;
CREATE POLICY "Authenticated users view stories"
    ON public.stories FOR SELECT TO authenticated
    USING (
        expires_at > NOW()
        AND (
            user_id = (SELECT auth.uid())
            OR public.are_mutual_connections(user_id, (SELECT auth.uid()))
            OR public.can_view_story_from_follower(user_id, (SELECT auth.uid()))
            OR public.can_view_story_from_chat(user_id, (SELECT auth.uid()))
        )
    );

-- Story media shares the private social bucket with posts. Grant chat peers access
-- only to objects actively referenced by an eligible, unexpired story.
DROP POLICY IF EXISTS "Connections view private social media" ON storage.objects;
CREATE POLICY "Connections view private social media"
    ON storage.objects FOR SELECT TO authenticated
    USING (
        bucket_id = 'campus-private-media'
        AND (
            (storage.foldername(name))[1] = (SELECT auth.uid())::TEXT
            OR CASE
                WHEN (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
                THEN public.are_mutual_connections(
                    (storage.foldername(name))[1]::UUID,
                    (SELECT auth.uid())
                )
                ELSE FALSE
            END
            OR EXISTS (
                SELECT 1
                FROM public.stories AS story
                WHERE story.media_url = 'private-media:' || storage.objects.name
                  AND story.expires_at > NOW()
                  AND (
                      public.can_view_story_from_follower(story.user_id, (SELECT auth.uid()))
                      OR public.can_view_story_from_chat(story.user_id, (SELECT auth.uid()))
                  )
            )
        )
    );

COMMIT;
