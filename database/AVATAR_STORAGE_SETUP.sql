-- Campus Connect profile photo storage setup.
-- Safe to run again. Creates the public avatar bucket and owner-only uploads.
-- Profile image reads are public so profile photos can display to other members.
BEGIN;

INSERT INTO storage.buckets (
    id, name, public, file_size_limit, allowed_mime_types
)
VALUES (
    'avatars',
    'avatars',
    TRUE,
    10485760,
    ARRAY['image/*']
)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    public = TRUE,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Users upload own avatar" ON storage.objects;
CREATE POLICY "Users upload own avatar"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = (SELECT auth.uid())::TEXT
    );

DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
CREATE POLICY "Anyone can view avatars"
    ON storage.objects FOR SELECT TO public
    USING (bucket_id = 'avatars');

COMMIT;
