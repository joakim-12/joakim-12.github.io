-- Allow recorded voice notes in the existing private chat-media bucket.
-- This only appends audio/* to the MIME allowlist; access policies are unchanged.
BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM storage.buckets WHERE id = 'campus-private-media'
    ) THEN
        RAISE EXCEPTION 'The campus-private-media bucket is missing; run the existing media-storage setup first.';
    END IF;
END;
$$;

UPDATE storage.buckets
SET allowed_mime_types = CASE
    WHEN allowed_mime_types IS NULL THEN ARRAY['audio/*']::TEXT[]
    WHEN 'audio/*' = ANY(allowed_mime_types) THEN allowed_mime_types
    ELSE array_append(allowed_mime_types, 'audio/*')
END
WHERE id = 'campus-private-media';

COMMIT;
