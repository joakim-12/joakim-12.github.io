-- Persistent reposts for Campus Connect video Reels.
BEGIN;

CREATE TABLE IF NOT EXISTS public.post_reposts (
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (post_id, user_id)
);

CREATE INDEX IF NOT EXISTS post_reposts_post_idx
    ON public.post_reposts (post_id, created_at DESC);

ALTER TABLE public.post_reposts ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, DELETE ON public.post_reposts TO authenticated;

DROP POLICY IF EXISTS "Members view reposts of visible posts" ON public.post_reposts;
CREATE POLICY "Members view reposts of visible posts"
    ON public.post_reposts FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = post_reposts.post_id
        )
    );

DROP POLICY IF EXISTS "Members repost visible posts as themselves" ON public.post_reposts;
CREATE POLICY "Members repost visible posts as themselves"
    ON public.post_reposts FOR INSERT TO authenticated
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = post_reposts.post_id
        )
    );

DROP POLICY IF EXISTS "Members remove their own reposts" ON public.post_reposts;
CREATE POLICY "Members remove their own reposts"
    ON public.post_reposts FOR DELETE TO authenticated
    USING (user_id = (SELECT auth.uid()));

COMMIT;
