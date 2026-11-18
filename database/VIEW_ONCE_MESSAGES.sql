BEGIN;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'campus-view-once-media',
    'campus-view-once-media',
    FALSE,
    524288000,
    ARRAY['image/*', 'video/*']::TEXT[]
)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    public = FALSE,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

CREATE TABLE IF NOT EXISTS public.view_once_opens (
    message_id UUID PRIMARY KEY
        REFERENCES public.messages(id) ON DELETE CASCADE,
    viewer_id UUID NOT NULL
        REFERENCES auth.users(id) ON DELETE CASCADE,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.view_once_opens ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.view_once_opens FROM anon, authenticated, service_role;
GRANT SELECT ON TABLE public.view_once_opens TO authenticated;
GRANT SELECT, INSERT ON TABLE public.view_once_opens TO service_role;

DROP POLICY IF EXISTS "Participants view view-once opens" ON public.view_once_opens;
CREATE POLICY "Participants view view-once opens"
    ON public.view_once_opens FOR SELECT TO authenticated
    USING (
        viewer_id = (SELECT auth.uid())
        OR EXISTS (
            SELECT 1 FROM public.messages AS message
            WHERE message.id = view_once_opens.message_id
              AND message.sender_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS "Authenticated users upload own view-once media" ON storage.objects;
CREATE POLICY "Authenticated users upload own view-once media"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'campus-view-once-media'
        AND (storage.foldername(name))[1] = (SELECT auth.uid())::TEXT
    );

COMMIT;
