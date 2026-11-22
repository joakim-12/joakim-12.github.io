-- Repair post media uploads when either Storage bucket was removed or missed
-- during database setup. Safe to run repeatedly.
BEGIN;

INSERT INTO storage.buckets (
    id, name, public, file_size_limit, allowed_mime_types
)
VALUES
    (
        'campus-private-media',
        'campus-private-media',
        FALSE,
        524288000,
        ARRAY['image/*', 'video/*', 'audio/*']
    ),
    (
        'campus-world-media',
        'campus-world-media',
        TRUE,
        524288000,
        ARRAY['image/*', 'video/*']
    )
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Authenticated users upload own private social media" ON storage.objects;
CREATE POLICY "Authenticated users upload own private social media"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'campus-private-media'
        AND (storage.foldername(name))[1] = (SELECT auth.uid())::TEXT
    );

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

DROP POLICY IF EXISTS "Users delete own private social media" ON storage.objects;
CREATE POLICY "Users delete own private social media"
    ON storage.objects FOR DELETE TO authenticated
    USING (
        bucket_id = 'campus-private-media'
        AND (storage.foldername(name))[1] = (SELECT auth.uid())::TEXT
    );

DROP POLICY IF EXISTS "Members upload own world post media" ON storage.objects;
CREATE POLICY "Members upload own world post media"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'campus-world-media'
        AND (storage.foldername(name))[1] = (SELECT auth.uid())::TEXT
    );

COMMIT;
