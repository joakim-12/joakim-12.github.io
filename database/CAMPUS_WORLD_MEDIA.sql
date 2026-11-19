-- Fix 404 Bucket not found when publishing a World-audience photo or video.
-- Safe to run more than once. The bucket is public because these posts are
-- intentionally public; uploads remain limited to each member's own folder.

INSERT INTO storage.buckets (
    id, name, public, file_size_limit, allowed_mime_types
)
VALUES (
    'campus-world-media',
    'campus-world-media',
    TRUE,
    524288000,
    ARRAY['image/*', 'video/*']
)
ON CONFLICT (id) DO UPDATE
SET public = TRUE,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Members upload own world post media" ON storage.objects;
CREATE POLICY "Members upload own world post media"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'campus-world-media'
        AND (storage.foldername(name))[1] = (SELECT auth.uid())::TEXT
    );

NOTIFY pgrst, 'reload schema';
