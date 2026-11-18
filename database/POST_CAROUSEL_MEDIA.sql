-- Store up to ten ordered photos and short videos on a single post.
-- image_url remains the first item for compatibility with older app versions.
BEGIN;

ALTER TABLE public.posts
    ADD COLUMN IF NOT EXISTS media_items JSONB NOT NULL DEFAULT '[]'::JSONB;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'posts_media_items_array_check'
          AND conrelid = 'public.posts'::regclass
    ) THEN
        ALTER TABLE public.posts
            ADD CONSTRAINT posts_media_items_array_check
            CHECK (
                jsonb_typeof(media_items) = 'array'
                AND jsonb_array_length(media_items) <= 10
            );
    END IF;
END;
$$;

COMMIT;
