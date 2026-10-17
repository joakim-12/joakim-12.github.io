-- THIS IS THE FILE TO USE (built 2026-10-17): it is schema.sql + every
-- migration, plus message reactions / stars / replies, lecturer credentials,
-- study modes, one number per account, the bulletin board, the company directory, the broadcast
-- policies behind the typing indicator, private group chats and a final check.
-- It replaces RUN_ONCE.sql, RUN_THIS_IN_SUPABASE.sql, RUN_MESSAGE_MARKS.sql,
-- RUN_FRIEND_NAMES.sql, RUN_CLASSES_MIN.sql and REPAIR_CHATS.sql.
-- ===================================================================
-- CAMPUS CONNECT — ONE-SHOT DATABASE UPDATE
-- Paste this ENTIRE file into Supabase SQL Editor and click Run.
-- Safe to run multiple times (everything is idempotent).
-- Built 2026-10-14 from schema.sql + all migrations, in order.
-- ===================================================================

-- ==================== PART 1/17: schema.sql ===========================
-- ============================================================
-- CAMPUS CONNECT
-- Social networking database for university students
-- Platform: Supabase / PostgreSQL
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- This public bucket serves chat/profile attachments and older public post URLs.
-- Apply database/migrations/20261011_social_access_controls.sql to store new
-- feed/status media in a private bucket restricted to mutual connections.
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
VALUES (
    'campus-media',
    'campus-media',
    TRUE,
    524288000,
    ARRAY[
        'image/*',
        'video/*',
        'audio/*',
        'application/pdf',
        'text/plain',
        'text/csv',
        'application/rtf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    ]
)
ON CONFLICT (id) DO UPDATE
SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Authenticated users upload own campus media"
    ON storage.objects;

CREATE POLICY "Authenticated users upload own campus media"
    ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'campus-media'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- ============================================================
-- 1. STUDENT PROFILES
-- Each profile belongs to an authenticated Supabase user.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY
        REFERENCES auth.users(id) ON DELETE CASCADE,

    username TEXT NOT NULL UNIQUE
        CHECK (
            username = LOWER(username)
            AND username ~ '^[a-z0-9_]{3,30}$'
        ),

    full_name TEXT NOT NULL DEFAULT ''
        CHECK (char_length(trim(full_name)) <= 100),

    gender TEXT NOT NULL DEFAULT ''
        CHECK (gender IN ('', 'male', 'female', 'other')),

    bio TEXT NOT NULL DEFAULT ''
        CHECK (char_length(bio) <= 500),

    avatar_url TEXT,

    course TEXT NOT NULL DEFAULT ''
        CHECK (char_length(course) <= 120),

    contact_email TEXT NOT NULL DEFAULT ''
        CHECK (char_length(contact_email) <= 254),

    contact_phone TEXT NOT NULL DEFAULT ''
        CHECK (char_length(contact_phone) <= 32),

    share_email BOOLEAN NOT NULL DEFAULT FALSE,

    share_phone BOOLEAN NOT NULL DEFAULT FALSE,

    is_discoverable BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS contact_email TEXT NOT NULL DEFAULT '';
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS contact_phone TEXT NOT NULL DEFAULT '';
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS share_email BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS share_phone BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS is_discoverable BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS gender TEXT NOT NULL DEFAULT '';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'public.profiles'::REGCLASS
          AND conname = 'profiles_gender_check'
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_gender_check
            CHECK (gender IN ('', 'male', 'female', 'other'));
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'public.profiles'::REGCLASS
          AND conname = 'profiles_contact_email_length_check'
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_contact_email_length_check
            CHECK (char_length(contact_email) <= 254);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'public.profiles'::REGCLASS
          AND conname = 'profiles_contact_phone_length_check'
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_contact_phone_length_check
            CHECK (char_length(contact_phone) <= 32);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.enforce_profile_contact_sharing()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NOT NEW.share_email THEN
        NEW.contact_email := '';
    END IF;
    IF NOT NEW.share_phone THEN
        NEW.contact_phone := '';
    END IF;
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_profile_contact_sharing() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS profiles_enforce_contact_sharing ON public.profiles;
CREATE TRIGGER profiles_enforce_contact_sharing
    BEFORE INSERT OR UPDATE
    ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_profile_contact_sharing();

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    username_base TEXT;
    candidate_username TEXT;
    attempt INTEGER;
    metadata JSONB;
BEGIN
    metadata := COALESCE(NEW.raw_user_meta_data, '{}'::JSONB);
    username_base := LOWER(
        REGEXP_REPLACE(
            COALESCE(
                metadata->>'username',
                SPLIT_PART(COALESCE(NEW.email, NEW.phone, 'student'), '@', 1)
            ),
            '[^a-zA-Z0-9_]',
            '',
            'g'
        )
    );
    username_base := LEFT(username_base, 20);
    IF char_length(username_base) < 3 THEN
        username_base := 'student';
    END IF;

    FOR attempt IN 0..5 LOOP
        candidate_username := CASE
            WHEN attempt = 0 THEN username_base
            ELSE LEFT(username_base, 19) || '_' || LEFT(NEW.id::TEXT, 8) ||
                 CASE WHEN attempt > 1 THEN '_' || (attempt - 1)::TEXT ELSE '' END
        END;

        BEGIN
            INSERT INTO public.profiles (
                id,
                username,
                full_name,
                course
            )
            VALUES (
                NEW.id,
                candidate_username,
                LEFT(COALESCE(metadata->>'full_name', 'Member'), 100),
                LEFT(COALESCE(metadata->>'course', ''), 120)
            )
            ON CONFLICT (id) DO NOTHING;
            RETURN NEW;
        EXCEPTION WHEN unique_violation THEN
            IF attempt = 5 THEN
                RAISE;
            END IF;
        END;
    END LOOP;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS on_auth_user_created_create_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_create_profile
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_auth_user();

DO $$
DECLARE
    registered_user RECORD;
    username_base TEXT;
    candidate_username TEXT;
    attempt INTEGER;
BEGIN
    FOR registered_user IN
        SELECT auth_user.id, auth_user.email, auth_user.phone, auth_user.raw_user_meta_data
        FROM auth.users AS auth_user
        WHERE NOT EXISTS (
            SELECT 1
            FROM public.profiles AS profile
            WHERE profile.id = auth_user.id
        )
        ORDER BY auth_user.created_at, auth_user.id
    LOOP
        username_base := LOWER(
            REGEXP_REPLACE(
                COALESCE(
                    registered_user.raw_user_meta_data->>'username',
                    SPLIT_PART(COALESCE(registered_user.email, registered_user.phone, 'student'), '@', 1)
                ),
                '[^a-zA-Z0-9_]',
                '',
                'g'
            )
        );
        username_base := LEFT(username_base, 20);
        IF char_length(username_base) < 3 THEN
            username_base := 'student';
        END IF;

        FOR attempt IN 0..5 LOOP
            candidate_username := CASE
                WHEN attempt = 0 THEN username_base
                ELSE LEFT(username_base, 19) || '_' || LEFT(registered_user.id::TEXT, 8) ||
                     CASE WHEN attempt > 1 THEN '_' || (attempt - 1)::TEXT ELSE '' END
            END;

            BEGIN
                INSERT INTO public.profiles (id, username, full_name, course)
                VALUES (
                    registered_user.id,
                    candidate_username,
                    LEFT(COALESCE(registered_user.raw_user_meta_data->>'full_name', 'Member'), 100),
                    LEFT(COALESCE(registered_user.raw_user_meta_data->>'course', ''), 120)
                )
                ON CONFLICT (id) DO NOTHING;
                EXIT;
            EXCEPTION WHEN unique_violation THEN
                IF attempt = 5 THEN
                    RAISE;
                END IF;
            END;
        END LOOP;
    END LOOP;
END;
$$;


-- ============================================================
-- 2. POSTS
-- Students can publish text posts and optional image URLs.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES auth.users(id) ON DELETE CASCADE,

    caption TEXT NOT NULL DEFAULT ''
        CHECK (char_length(caption) <= 5000),

    image_url TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (
        char_length(trim(caption)) > 0
        OR image_url IS NOT NULL
    )
);


-- ============================================================
-- 3. FOLLOWS
-- follower_id follows following_id.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.follows (
    follower_id UUID NOT NULL
        REFERENCES auth.users(id) ON DELETE CASCADE,

    following_id UUID NOT NULL
        REFERENCES auth.users(id) ON DELETE CASCADE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (follower_id, following_id),

    CHECK (follower_id <> following_id)
);


-- ============================================================
-- 4. POST LIKES
-- A user can like each post only once.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.post_likes (
    user_id UUID NOT NULL
        REFERENCES auth.users(id) ON DELETE CASCADE,

    post_id UUID NOT NULL
        REFERENCES public.posts(id) ON DELETE CASCADE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, post_id)
);


-- ============================================================
-- 5. COMMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    post_id UUID NOT NULL
        REFERENCES public.posts(id) ON DELETE CASCADE,

    user_id UUID NOT NULL
        REFERENCES auth.users(id) ON DELETE CASCADE,

    content TEXT NOT NULL
        CHECK (
            char_length(trim(content)) BETWEEN 1 AND 2000
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 6. STORIES
-- Stories expire after 24 hours by default.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES auth.users(id) ON DELETE CASCADE,

    media_url TEXT,

    content TEXT NOT NULL DEFAULT ''
        CHECK (char_length(content) <= 500),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    expires_at TIMESTAMPTZ NOT NULL
        DEFAULT (NOW() + INTERVAL '24 hours'),

    CONSTRAINT stories_expiration_window_check
        CHECK (
            expires_at > created_at
            AND expires_at <= created_at + INTERVAL '24 hours'
        ),
    CONSTRAINT stories_content_or_media_check
        CHECK (char_length(trim(content)) > 0 OR media_url IS NOT NULL)
);

ALTER TABLE public.stories
    ALTER COLUMN media_url DROP NOT NULL;

ALTER TABLE public.stories
    ADD COLUMN IF NOT EXISTS content TEXT NOT NULL DEFAULT '';

UPDATE public.stories
SET expires_at = created_at + INTERVAL '24 hours'
WHERE expires_at > created_at + INTERVAL '24 hours';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'stories_content_or_media_check'
          AND conrelid = 'public.stories'::regclass
    ) THEN
        ALTER TABLE public.stories
            ADD CONSTRAINT stories_content_or_media_check
            CHECK (char_length(trim(content)) > 0 OR media_url IS NOT NULL);
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'stories_expiration_window_check'
          AND conrelid = 'public.stories'::regclass
    ) THEN
        ALTER TABLE public.stories
            ADD CONSTRAINT stories_expiration_window_check
            CHECK (
                expires_at > created_at
                AND expires_at <= created_at + INTERVAL '24 hours'
            );
    END IF;
END;
$$;


-- ============================================================
-- 7. PRIVATE MESSAGES
-- Only the sender and receiver can read a conversation.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    sender_id UUID NOT NULL
        REFERENCES auth.users(id) ON DELETE CASCADE,

    receiver_id UUID NOT NULL
        REFERENCES auth.users(id) ON DELETE CASCADE,

    content TEXT NOT NULL
        CHECK (
            char_length(trim(content)) BETWEEN 1 AND 5000
        ),

    media_url TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    is_read BOOLEAN NOT NULL DEFAULT FALSE,

    read_at TIMESTAMPTZ,

    CHECK (sender_id <> receiver_id),

    CHECK (
        (is_read = FALSE AND read_at IS NULL)
        OR
        (is_read = TRUE AND read_at IS NOT NULL)
    )
);

-- ============================================================
-- 8. WEBRTC CALL SIGNALING
-- The table carries short-lived offer/answer/ICE signaling only.
-- Media stays peer-to-peer and is not stored in Supabase.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.call_signals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    call_id UUID NOT NULL,

    sender_id UUID NOT NULL
        REFERENCES auth.users(id) ON DELETE CASCADE,

    recipient_id UUID NOT NULL
        REFERENCES auth.users(id) ON DELETE CASCADE,

    kind TEXT NOT NULL
        CHECK (kind IN ('offer', 'answer', 'ice', 'end', 'reject', 'busy')),

    payload JSONB NOT NULL DEFAULT '{}'::JSONB
        CHECK (
            jsonb_typeof(payload) = 'object'
            AND octet_length(payload::TEXT) <= 65536
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (sender_id <> recipient_id)
);

GRANT SELECT, INSERT, DELETE ON public.call_signals TO authenticated;


-- ============================================================
-- 9. INDEXES
-- Improve performance when loading feeds, comments and chats.
-- ============================================================

CREATE INDEX IF NOT EXISTS posts_user_created_idx
    ON public.posts (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS posts_created_idx
    ON public.posts (created_at DESC);

CREATE INDEX IF NOT EXISTS comments_post_created_idx
    ON public.comments (post_id, created_at ASC);

CREATE INDEX IF NOT EXISTS comments_user_idx
    ON public.comments (user_id);

CREATE INDEX IF NOT EXISTS follows_following_idx
    ON public.follows (following_id, created_at DESC);

CREATE INDEX IF NOT EXISTS post_likes_post_idx
    ON public.post_likes (post_id);

CREATE INDEX IF NOT EXISTS stories_user_created_idx
    ON public.stories (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS stories_expires_idx
    ON public.stories (expires_at);

CREATE INDEX IF NOT EXISTS messages_sender_created_idx
    ON public.messages (sender_id, created_at DESC);

CREATE INDEX IF NOT EXISTS messages_receiver_created_idx
    ON public.messages (receiver_id, created_at DESC);

CREATE INDEX IF NOT EXISTS messages_sender_conversation_cursor_idx
    ON public.messages (sender_id, receiver_id, created_at DESC, id DESC);

CREATE INDEX IF NOT EXISTS messages_receiver_conversation_cursor_idx
    ON public.messages (receiver_id, sender_id, created_at DESC, id DESC);

CREATE INDEX IF NOT EXISTS messages_unread_receiver_idx
    ON public.messages (receiver_id, created_at DESC)
    WHERE is_read = FALSE;

CREATE INDEX IF NOT EXISTS profiles_username_search_idx
    ON public.profiles USING GIN (username gin_trgm_ops);

CREATE INDEX IF NOT EXISTS profiles_full_name_search_idx
    ON public.profiles USING GIN (full_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS profiles_course_search_idx
    ON public.profiles USING GIN (course gin_trgm_ops);

CREATE INDEX IF NOT EXISTS profiles_contact_email_search_idx
    ON public.profiles USING GIN (contact_email gin_trgm_ops)
    WHERE share_email = TRUE;

CREATE INDEX IF NOT EXISTS profiles_contact_phone_search_idx
    ON public.profiles USING GIN (contact_phone gin_trgm_ops)
    WHERE share_phone = TRUE;

CREATE INDEX IF NOT EXISTS call_signals_recipient_created_idx
    ON public.call_signals (recipient_id, created_at DESC);

CREATE INDEX IF NOT EXISTS call_signals_sender_created_idx
    ON public.call_signals (sender_id, created_at DESC);


-- ============================================================
-- 10. AUTOMATIC UPDATED_AT TIMESTAMPS
-- ============================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_set_updated_at
    ON public.profiles;

CREATE TRIGGER profiles_set_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS posts_set_updated_at
    ON public.posts;

CREATE TRIGGER posts_set_updated_at
    BEFORE UPDATE ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS comments_set_updated_at
    ON public.comments;

CREATE TRIGGER comments_set_updated_at
    BEFORE UPDATE ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- 10. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_signals ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- 11. PROFILE POLICIES
-- Profiles are visible to their owners, discoverable members, and private-chat peers.
-- Users can create and update only their own profiles.
-- ============================================================

DROP POLICY IF EXISTS "Profiles are viewable by authenticated users"
    ON public.profiles;

CREATE POLICY "Profiles are viewable by authenticated users"
    ON public.profiles
    FOR SELECT TO authenticated
    USING (
        auth.uid() = id
        OR is_discoverable
        OR EXISTS (
            SELECT 1
            FROM public.messages AS message
            WHERE (message.sender_id = auth.uid() AND message.receiver_id = profiles.id)
               OR (message.receiver_id = auth.uid() AND message.sender_id = profiles.id)
        )
    );

DROP POLICY IF EXISTS "Users create their own profile"
    ON public.profiles;

CREATE POLICY "Users create their own profile"
    ON public.profiles
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users update their own profile"
    ON public.profiles;

CREATE POLICY "Users update their own profile"
    ON public.profiles
    FOR UPDATE TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users delete their own profile"
    ON public.profiles;

CREATE POLICY "Users delete their own profile"
    ON public.profiles
    FOR DELETE TO authenticated
    USING (auth.uid() = id);


-- ============================================================
-- 12. POST POLICIES
-- ============================================================

DROP POLICY IF EXISTS "Authenticated users view posts"
    ON public.posts;

CREATE POLICY "Authenticated users view posts"
    ON public.posts
    FOR SELECT TO authenticated
    USING (TRUE);

DROP POLICY IF EXISTS "Users create their own posts"
    ON public.posts;

CREATE POLICY "Users create their own posts"
    ON public.posts
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users update their own posts"
    ON public.posts;

CREATE POLICY "Users update their own posts"
    ON public.posts
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users delete their own posts"
    ON public.posts;

CREATE POLICY "Users delete their own posts"
    ON public.posts
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);


-- ============================================================
-- 13. FOLLOW POLICIES
-- ============================================================

DROP POLICY IF EXISTS "Authenticated users view follows"
    ON public.follows;

CREATE POLICY "Authenticated users view follows"
    ON public.follows
    FOR SELECT TO authenticated
    USING (TRUE);

DROP POLICY IF EXISTS "Users follow as themselves"
    ON public.follows;

CREATE POLICY "Users follow as themselves"
    ON public.follows
    FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = follower_id
        AND follower_id <> following_id
    );

DROP POLICY IF EXISTS "Users unfollow as themselves"
    ON public.follows;

CREATE POLICY "Users unfollow as themselves"
    ON public.follows
    FOR DELETE TO authenticated
    USING (auth.uid() = follower_id);


-- ============================================================
-- 14. LIKE POLICIES
-- ============================================================

DROP POLICY IF EXISTS "Authenticated users view likes"
    ON public.post_likes;

CREATE POLICY "Authenticated users view likes"
    ON public.post_likes
    FOR SELECT TO authenticated
    USING (TRUE);

DROP POLICY IF EXISTS "Users like as themselves"
    ON public.post_likes;

CREATE POLICY "Users like as themselves"
    ON public.post_likes
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users remove their own likes"
    ON public.post_likes;

CREATE POLICY "Users remove their own likes"
    ON public.post_likes
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);


-- ============================================================
-- 15. COMMENT POLICIES
-- ============================================================

DROP POLICY IF EXISTS "Authenticated users view comments"
    ON public.comments;

CREATE POLICY "Authenticated users view comments"
    ON public.comments
    FOR SELECT TO authenticated
    USING (TRUE);

DROP POLICY IF EXISTS "Users create their own comments"
    ON public.comments;

CREATE POLICY "Users create their own comments"
    ON public.comments
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users update their own comments"
    ON public.comments;

CREATE POLICY "Users update their own comments"
    ON public.comments
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users delete their own comments"
    ON public.comments;

CREATE POLICY "Users delete their own comments"
    ON public.comments
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);


-- ============================================================
-- 16. STORY POLICIES
-- ============================================================

DROP POLICY IF EXISTS "Authenticated users view stories"
    ON public.stories;

CREATE POLICY "Authenticated users view stories"
    ON public.stories
    FOR SELECT TO authenticated
    USING (expires_at > NOW());

DROP POLICY IF EXISTS "Users create their own stories"
    ON public.stories;

CREATE POLICY "Users create their own stories"
    ON public.stories
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users delete their own stories"
    ON public.stories;

CREATE POLICY "Users delete their own stories"
    ON public.stories
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================
-- 17. CALL SIGNAL POLICIES
-- Only the two call participants can read or remove signaling rows.
-- Users can only create signals as themselves.
-- ============================================================

DROP POLICY IF EXISTS "Call participants view call signals"
    ON public.call_signals;

CREATE POLICY "Call participants view call signals"
    ON public.call_signals
    FOR SELECT TO authenticated
    USING (
        auth.uid() = sender_id
        OR auth.uid() = recipient_id
    );

DROP POLICY IF EXISTS "Users send call signals as themselves"
    ON public.call_signals;

CREATE POLICY "Users send call signals as themselves"
    ON public.call_signals
    FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = sender_id
        AND sender_id <> recipient_id
    );

DROP POLICY IF EXISTS "Call participants delete call signals"
    ON public.call_signals;

CREATE POLICY "Call participants delete call signals"
    ON public.call_signals
    FOR DELETE TO authenticated
    USING (
        auth.uid() = sender_id
        OR auth.uid() = recipient_id
    );


-- ============================================================
-- 18. PRIVATE MESSAGE POLICIES
-- Important: users must not access messages belonging to others.
-- ============================================================

DROP POLICY IF EXISTS "Participants view their messages"
    ON public.messages;

CREATE POLICY "Participants view their messages"
    ON public.messages
    FOR SELECT TO authenticated
    USING (
        auth.uid() = sender_id
        OR auth.uid() = receiver_id
    );

DROP POLICY IF EXISTS "Users send messages as themselves"
    ON public.messages;

CREATE POLICY "Users send messages as themselves"
    ON public.messages
    FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = sender_id
        AND sender_id <> receiver_id
    );

DROP POLICY IF EXISTS "Recipients mark messages as read"
    ON public.messages;

CREATE POLICY "Recipients mark messages as read"
    ON public.messages
    FOR UPDATE TO authenticated
    USING (
        auth.uid() = receiver_id
    )
    WITH CHECK (
        auth.uid() = receiver_id
    );

DROP POLICY IF EXISTS "Senders delete their own messages"
    ON public.messages;

CREATE POLICY "Senders delete their own messages"
    ON public.messages
    FOR DELETE TO authenticated
    USING (
        auth.uid() = sender_id
    );


-- ============================================================
-- 19. PROTECT MESSAGE IMMUTABLE FIELDS
-- Recipients may mark messages as read, but cannot rewrite
-- the sender, receiver, content, or creation timestamp.
-- ============================================================

CREATE OR REPLACE FUNCTION public.protect_message_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.id IS DISTINCT FROM OLD.id
       OR NEW.sender_id IS DISTINCT FROM OLD.sender_id
       OR NEW.receiver_id IS DISTINCT FROM OLD.receiver_id
       OR NEW.content IS DISTINCT FROM OLD.content
       OR NEW.media_url IS DISTINCT FROM OLD.media_url
       OR NEW.created_at IS DISTINCT FROM OLD.created_at
    THEN
        RAISE EXCEPTION
            'Message sender, receiver, content, and creation time cannot be changed.';
    END IF;

    IF NEW.is_read IS DISTINCT FROM OLD.is_read THEN
        IF OLD.is_read = TRUE AND NEW.is_read = FALSE THEN
            RAISE EXCEPTION 'A read message cannot be marked unread.';
        END IF;

        IF NEW.is_read = TRUE AND NEW.read_at IS NULL THEN
            NEW.read_at = NOW();
        END IF;
    END IF;

    IF NEW.is_read = FALSE THEN
        NEW.read_at = NULL;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_message_fields_trigger
    ON public.messages;

CREATE TRIGGER protect_message_fields_trigger
    BEFORE UPDATE ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_message_fields();

-- Postgres Changes must be enabled for live call signaling.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'call_signals'
    ) THEN
        ALTER PUBLICATION supabase_realtime
            ADD TABLE public.call_signals;
    END IF;
END;
$$;

-- Private and community chat inserts drive live message delivery.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
    END IF;
END;
$$;


-- ============================================================
-- 20. REACTIONS, GROUPS, CHANNELS, CHAT MEDIA, NOTIFICATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.post_reactions (
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reaction TEXT NOT NULL
        CHECK (reaction IN ('👍', '❤️', '😂', '🎉', '🤔')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (post_id, user_id)
);

INSERT INTO public.post_reactions (post_id, user_id, reaction)
SELECT post_id, user_id, '❤️'
FROM public.post_likes
ON CONFLICT (post_id, user_id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.communities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 3 AND 80),
    description TEXT NOT NULL DEFAULT '' CHECK (char_length(description) <= 500),
    kind TEXT NOT NULL CHECK (kind IN ('group', 'channel')),
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.community_members (
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (community_id, user_id)
);

DROP POLICY IF EXISTS "Community members view peer profiles"
    ON public.profiles;
CREATE POLICY "Community members view peer profiles"
    ON public.profiles FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM public.community_members AS own_membership
            JOIN public.community_members AS peer_membership
                ON peer_membership.community_id = own_membership.community_id
            WHERE own_membership.user_id = (SELECT auth.uid())
              AND peer_membership.user_id = profiles.id
        )
    );

CREATE TABLE IF NOT EXISTS public.community_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL DEFAULT '' CHECK (char_length(content) <= 5000),
    media_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (char_length(trim(content)) > 0 OR media_url IS NOT NULL)
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'community_messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime
            ADD TABLE public.community_messages;
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    actor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('reaction', 'comment', 'follow', 'message')),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (recipient_id <> actor_id)
);

ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS media_url TEXT;
ALTER TABLE public.messages
    ALTER COLUMN content SET DEFAULT '';
ALTER TABLE public.messages
    ALTER COLUMN content DROP NOT NULL;
ALTER TABLE public.messages
    DROP CONSTRAINT IF EXISTS messages_content_check;
ALTER TABLE public.messages
    DROP CONSTRAINT IF EXISTS messages_content_or_media_check;
ALTER TABLE public.messages
    ADD CONSTRAINT messages_content_or_media_check
        CHECK (
            char_length(COALESCE(content, '')) <= 5000
            AND (char_length(trim(COALESCE(content, ''))) > 0 OR media_url IS NOT NULL)
        );

CREATE INDEX IF NOT EXISTS post_reactions_post_idx
    ON public.post_reactions (post_id, reaction);
CREATE INDEX IF NOT EXISTS communities_created_idx
    ON public.communities (created_at DESC);
CREATE INDEX IF NOT EXISTS community_members_user_idx
    ON public.community_members (user_id, joined_at DESC);
CREATE INDEX IF NOT EXISTS community_messages_created_idx
    ON public.community_messages (community_id, created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_recipient_created_idx
    ON public.notifications (recipient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_unread_idx
    ON public.notifications (recipient_id, created_at DESC)
    WHERE is_read = FALSE;

ALTER TABLE public.post_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.post_reactions TO authenticated;
GRANT SELECT, UPDATE, DELETE ON public.communities TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.community_members TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.community_messages TO authenticated;
GRANT SELECT ON public.notifications TO authenticated;

CREATE OR REPLACE FUNCTION public.is_community_member(p_community_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.community_members AS member
        WHERE member.community_id = p_community_id
          AND member.user_id = (SELECT auth.uid())
    );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_community(p_community_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.community_members AS member
        WHERE member.community_id = p_community_id
          AND member.user_id = (SELECT auth.uid())
          AND member.role IN ('owner', 'admin')
    );
$$;

CREATE OR REPLACE FUNCTION public.is_community_public(p_community_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.communities AS community
        WHERE community.id = p_community_id
          AND community.is_public = TRUE
    );
$$;

CREATE OR REPLACE FUNCTION public.create_community(
    p_name TEXT,
    p_description TEXT,
    p_kind TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    new_community_id UUID;
    current_user_id UUID := auth.uid();
BEGIN
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'You must be signed in to create a community.';
    END IF;
    IF p_kind NOT IN ('group', 'channel') THEN
        RAISE EXCEPTION 'Choose either a group or a channel.';
    END IF;
    IF char_length(trim(COALESCE(p_name, ''))) NOT BETWEEN 3 AND 80
       OR char_length(COALESCE(p_description, '')) > 500 THEN
        RAISE EXCEPTION 'Community name or description is too long or too short.';
    END IF;

    INSERT INTO public.communities (owner_id, name, description, kind)
    VALUES (current_user_id, trim(p_name), trim(COALESCE(p_description, '')), p_kind)
    RETURNING id INTO new_community_id;

    INSERT INTO public.community_members (community_id, user_id, role)
    VALUES (new_community_id, current_user_id, 'owner');

    RETURN new_community_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_notifications_read()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'You must be signed in to update notifications.';
    END IF;

    UPDATE public.notifications
    SET is_read = TRUE
    WHERE recipient_id = auth.uid()
      AND is_read = FALSE;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_post_reaction_summary(p_post_ids UUID[])
RETURNS TABLE (
    post_id UUID,
    reaction TEXT,
    reaction_count BIGINT,
    my_reaction TEXT
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
    WITH requested_posts AS (
        SELECT DISTINCT requested.post_id
        FROM unnest(COALESCE(p_post_ids, ARRAY[]::UUID[])) AS requested(post_id)
        WHERE requested.post_id IS NOT NULL
    )
    SELECT
        post_reaction.post_id,
        post_reaction.reaction,
        COUNT(*)::BIGINT,
        MAX(post_reaction.reaction) FILTER (
            WHERE post_reaction.user_id = (SELECT auth.uid())
        )
    FROM public.post_reactions AS post_reaction
    JOIN requested_posts
      ON requested_posts.post_id = post_reaction.post_id
    GROUP BY post_reaction.post_id, post_reaction.reaction;
$$;

REVOKE ALL ON FUNCTION public.is_community_member(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.can_manage_community(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_community_public(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.create_community(TEXT, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.mark_notifications_read() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_post_reaction_summary(UUID[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_community_member(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_community(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_community_public(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_community(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_notifications_read() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_post_reaction_summary(UUID[]) TO authenticated;

DROP POLICY IF EXISTS "Authenticated users view post reactions"
    ON public.post_reactions;
CREATE POLICY "Authenticated users view post reactions"
    ON public.post_reactions FOR SELECT TO authenticated USING (TRUE);
DROP POLICY IF EXISTS "Users manage their own post reactions"
    ON public.post_reactions;
CREATE POLICY "Users manage their own post reactions"
    ON public.post_reactions FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Members discover public communities"
    ON public.communities;
CREATE POLICY "Members discover public communities"
    ON public.communities FOR SELECT TO authenticated
    USING (is_public OR public.is_community_member(id));
DROP POLICY IF EXISTS "Community managers update communities"
    ON public.communities;
CREATE POLICY "Community managers update communities"
    ON public.communities FOR UPDATE TO authenticated
    USING (public.can_manage_community(id))
    WITH CHECK (public.can_manage_community(id));
DROP POLICY IF EXISTS "Community owners delete communities"
    ON public.communities;
CREATE POLICY "Community owners delete communities"
    ON public.communities FOR DELETE TO authenticated
    USING (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Members view community membership"
    ON public.community_members;
CREATE POLICY "Members view community membership"
    ON public.community_members FOR SELECT TO authenticated
    USING (
        user_id = (SELECT auth.uid())
        OR public.is_community_member(community_id)
        OR public.is_community_public(community_id)
    );
DROP POLICY IF EXISTS "Members join public communities"
    ON public.community_members;
CREATE POLICY "Members join public communities"
    ON public.community_members FOR INSERT TO authenticated
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND role = 'member'
        AND public.is_community_public(community_id)
    );
DROP POLICY IF EXISTS "Members leave or managers remove members"
    ON public.community_members;
CREATE POLICY "Members leave or managers remove members"
    ON public.community_members FOR DELETE TO authenticated
    USING (
        (user_id = (SELECT auth.uid()) AND role <> 'owner')
        OR (role <> 'owner' AND public.can_manage_community(community_id))
    );

DROP POLICY IF EXISTS "Community members view messages"
    ON public.community_messages;
CREATE POLICY "Community members view messages"
    ON public.community_messages FOR SELECT TO authenticated
    USING (public.is_community_member(community_id));
DROP POLICY IF EXISTS "Community members send group messages"
    ON public.community_messages;
CREATE POLICY "Community members send group messages"
    ON public.community_messages FOR INSERT TO authenticated
    WITH CHECK (
        sender_id = (SELECT auth.uid())
        AND public.is_community_member(community_id)
        AND (
            EXISTS (
                SELECT 1 FROM public.communities AS community
                WHERE community.id = community_messages.community_id
                  AND community.kind = 'group'
            )
            OR public.can_manage_community(community_id)
        )
    );
DROP POLICY IF EXISTS "Community senders and managers delete messages"
    ON public.community_messages;
CREATE POLICY "Community senders and managers delete messages"
    ON public.community_messages FOR DELETE TO authenticated
    USING (
        sender_id = (SELECT auth.uid())
        OR public.can_manage_community(community_id)
    );

DROP POLICY IF EXISTS "Users view their own notifications"
    ON public.notifications;
CREATE POLICY "Users view their own notifications"
    ON public.notifications FOR SELECT TO authenticated
    USING (recipient_id = (SELECT auth.uid()));

CREATE OR REPLACE FUNCTION public.notify_post_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    post_owner_id UUID;
    notification_kind TEXT;
BEGIN
    SELECT post.user_id INTO post_owner_id
    FROM public.posts AS post
    WHERE post.id = NEW.post_id;

    IF post_owner_id IS NOT NULL AND post_owner_id <> NEW.user_id THEN
        notification_kind := CASE TG_TABLE_NAME
            WHEN 'comments' THEN 'comment'
            ELSE 'reaction'
        END;
        INSERT INTO public.notifications (recipient_id, actor_id, kind, post_id)
        VALUES (post_owner_id, NEW.user_id, notification_kind, NEW.post_id);
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_new_follow()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.notifications (recipient_id, actor_id, kind)
    VALUES (NEW.following_id, NEW.follower_id, 'follow');
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.notifications (recipient_id, actor_id, kind)
    VALUES (NEW.receiver_id, NEW.sender_id, 'message');
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.notify_post_activity() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.notify_new_follow() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.notify_new_message() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS post_likes_notify_activity ON public.post_likes;
CREATE TRIGGER post_likes_notify_activity
    AFTER INSERT ON public.post_likes
    FOR EACH ROW EXECUTE FUNCTION public.notify_post_activity();
DROP TRIGGER IF EXISTS post_reactions_notify_activity ON public.post_reactions;
CREATE TRIGGER post_reactions_notify_activity
    AFTER INSERT ON public.post_reactions
    FOR EACH ROW EXECUTE FUNCTION public.notify_post_activity();
DROP TRIGGER IF EXISTS comments_notify_activity ON public.comments;
CREATE TRIGGER comments_notify_activity
    AFTER INSERT ON public.comments
    FOR EACH ROW EXECUTE FUNCTION public.notify_post_activity();
DROP TRIGGER IF EXISTS follows_notify_activity ON public.follows;
CREATE TRIGGER follows_notify_activity
    AFTER INSERT ON public.follows
    FOR EACH ROW EXECUTE FUNCTION public.notify_new_follow();
DROP TRIGGER IF EXISTS messages_notify_activity ON public.messages;
CREATE TRIGGER messages_notify_activity
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.notify_new_message();

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
    END IF;
END;
$$;

-- ============================================================
-- END OF CAMPUS CONNECT SCHEMA
-- ============================================================

NOTIFY pgrst, 'reload schema';

-- ================ PART 2/17: migrations/20261011_profile_gender.sql ================
BEGIN;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS gender TEXT NOT NULL DEFAULT '';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'public.profiles'::REGCLASS
          AND conname = 'profiles_gender_check'
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_gender_check
            CHECK (gender IN ('', 'male', 'female', 'other'));
    END IF;
END;
$$;

COMMIT;

-- ================ PART 3/17: migrations/20261011_social_access_controls.sql ================
BEGIN;

CREATE TABLE IF NOT EXISTS public.user_blocks (
    blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (blocker_id, blocked_id),
    CHECK (blocker_id <> blocked_id)
);

CREATE INDEX IF NOT EXISTS user_blocks_blocked_idx
    ON public.user_blocks (blocked_id, blocker_id);

ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, DELETE ON public.user_blocks TO authenticated;

CREATE TABLE IF NOT EXISTS public.user_presence (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_presence ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE ON public.user_presence TO authenticated;

DROP POLICY IF EXISTS "Members write their own presence" ON public.user_presence;
CREATE POLICY "Members write their own presence"
    ON public.user_presence FOR INSERT TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Members update their own presence" ON public.user_presence;
CREATE POLICY "Members update their own presence"
    ON public.user_presence FOR UPDATE TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users view their own blocks" ON public.user_blocks;
CREATE POLICY "Users view their own blocks"
    ON public.user_blocks FOR SELECT TO authenticated
    USING ((SELECT auth.uid()) = blocker_id);

DROP POLICY IF EXISTS "Users block others as themselves" ON public.user_blocks;
CREATE POLICY "Users block others as themselves"
    ON public.user_blocks FOR INSERT TO authenticated
    WITH CHECK (
        (SELECT auth.uid()) = blocker_id
        AND blocker_id <> blocked_id
    );

DROP POLICY IF EXISTS "Users unblock others as themselves" ON public.user_blocks;
CREATE POLICY "Users unblock others as themselves"
    ON public.user_blocks FOR DELETE TO authenticated
    USING ((SELECT auth.uid()) = blocker_id);

CREATE OR REPLACE FUNCTION public.is_blocked_between(p_first UUID, p_second UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT p_first IS NOT NULL
       AND p_second IS NOT NULL
       AND (p_first = auth.uid() OR p_second = auth.uid())
       AND EXISTS (
            SELECT 1
            FROM public.user_blocks AS block
            WHERE (block.blocker_id = p_first AND block.blocked_id = p_second)
               OR (block.blocker_id = p_second AND block.blocked_id = p_first)
       );
$$;

CREATE OR REPLACE FUNCTION public.are_mutual_connections(p_first UUID, p_second UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT p_first IS NOT NULL
       AND p_second IS NOT NULL
       AND p_first <> p_second
       AND (p_first = auth.uid() OR p_second = auth.uid())
       AND NOT public.is_blocked_between(p_first, p_second)
       AND EXISTS (
            SELECT 1 FROM public.follows
            WHERE follower_id = p_first AND following_id = p_second
       )
       AND EXISTS (
            SELECT 1 FROM public.follows
            WHERE follower_id = p_second AND following_id = p_first
       );
$$;

CREATE OR REPLACE FUNCTION public.get_blocked_profiles()
RETURNS TABLE (id UUID, username TEXT, full_name TEXT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT profile.id, profile.username, profile.full_name
    FROM public.user_blocks AS block
    JOIN public.profiles AS profile ON profile.id = block.blocked_id
    WHERE block.blocker_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.update_last_seen()
RETURNS TIMESTAMPTZ
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
    updated_value TIMESTAMPTZ;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'You must be signed in to update your last-seen time.';
    END IF;

    INSERT INTO public.user_presence (user_id, last_seen_at)
    VALUES (auth.uid(), NOW())
    ON CONFLICT (user_id)
    DO UPDATE SET last_seen_at = EXCLUDED.last_seen_at
    RETURNING last_seen_at INTO updated_value;

    RETURN updated_value;
END;
$$;

REVOKE ALL ON FUNCTION public.is_blocked_between(UUID, UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.are_mutual_connections(UUID, UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_blocked_profiles() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.update_last_seen() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_blocked_between(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.are_mutual_connections(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_blocked_profiles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_last_seen() TO authenticated;

DROP POLICY IF EXISTS "Members view mutual connection presence" ON public.user_presence;
CREATE POLICY "Members view mutual connection presence"
    ON public.user_presence FOR SELECT TO authenticated
    USING (
        user_id = (SELECT auth.uid())
        OR public.are_mutual_connections(user_id, (SELECT auth.uid()))
    );

DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Profiles are viewable by authenticated users"
    ON public.profiles FOR SELECT TO authenticated
    USING (
        (SELECT auth.uid()) = id
        OR (
            NOT public.is_blocked_between((SELECT auth.uid()), id)
            AND (
                is_discoverable
                OR public.are_mutual_connections((SELECT auth.uid()), id)
                OR EXISTS (
                    SELECT 1
                    FROM public.messages AS message
                    WHERE (message.sender_id = (SELECT auth.uid()) AND message.receiver_id = profiles.id)
                       OR (message.receiver_id = (SELECT auth.uid()) AND message.sender_id = profiles.id)
                )
            )
        )
    );

DROP POLICY IF EXISTS "Community members view peer profiles" ON public.profiles;
CREATE POLICY "Community members view peer profiles"
    ON public.profiles FOR SELECT TO authenticated
    USING (
        NOT public.is_blocked_between((SELECT auth.uid()), profiles.id)
        AND EXISTS (
            SELECT 1
            FROM public.community_members AS own_membership
            JOIN public.community_members AS peer_membership
                ON peer_membership.community_id = own_membership.community_id
            WHERE own_membership.user_id = (SELECT auth.uid())
              AND peer_membership.user_id = profiles.id
        )
    );

DROP POLICY IF EXISTS "Authenticated users view posts" ON public.posts;
CREATE POLICY "Authenticated users view posts"
    ON public.posts FOR SELECT TO authenticated
    USING (
        user_id = (SELECT auth.uid())
        OR public.are_mutual_connections(user_id, (SELECT auth.uid()))
    );

DROP POLICY IF EXISTS "Authenticated users view stories" ON public.stories;
CREATE POLICY "Authenticated users view stories"
    ON public.stories FOR SELECT TO authenticated
    USING (
        expires_at > NOW()
        AND (
            user_id = (SELECT auth.uid())
            OR public.are_mutual_connections(user_id, (SELECT auth.uid()))
        )
    );

DROP POLICY IF EXISTS "Authenticated users view comments" ON public.comments;
CREATE POLICY "Authenticated users view comments"
    ON public.comments FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = comments.post_id
        )
    );

DROP POLICY IF EXISTS "Users create their own comments" ON public.comments;
CREATE POLICY "Users create their own comments"
    ON public.comments FOR INSERT TO authenticated
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = comments.post_id
        )
    );

DROP POLICY IF EXISTS "Authenticated users view post reactions" ON public.post_reactions;
CREATE POLICY "Authenticated users view post reactions"
    ON public.post_reactions FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = post_reactions.post_id
        )
    );

DROP POLICY IF EXISTS "Users follow as themselves" ON public.follows;
CREATE POLICY "Users follow as themselves"
    ON public.follows FOR INSERT TO authenticated
    WITH CHECK (
        follower_id = (SELECT auth.uid())
        AND follower_id <> following_id
        AND NOT public.is_blocked_between(follower_id, following_id)
    );

DROP POLICY IF EXISTS "Participants view their messages" ON public.messages;
CREATE POLICY "Participants view their messages"
    ON public.messages FOR SELECT TO authenticated
    USING (
        (
            (SELECT auth.uid()) = sender_id
            OR (SELECT auth.uid()) = receiver_id
        )
        AND NOT public.is_blocked_between(sender_id, receiver_id)
    );

DROP POLICY IF EXISTS "Users send messages as themselves" ON public.messages;
CREATE POLICY "Users send messages as themselves"
    ON public.messages FOR INSERT TO authenticated
    WITH CHECK (
        sender_id = (SELECT auth.uid())
        AND sender_id <> receiver_id
        AND NOT public.is_blocked_between(sender_id, receiver_id)
    );

DROP POLICY IF EXISTS "Recipients mark messages as read" ON public.messages;
CREATE POLICY "Recipients mark messages as read"
    ON public.messages FOR UPDATE TO authenticated
    USING (
        receiver_id = (SELECT auth.uid())
        AND NOT public.is_blocked_between(sender_id, receiver_id)
    )
    WITH CHECK (
        receiver_id = (SELECT auth.uid())
        AND NOT public.is_blocked_between(sender_id, receiver_id)
    );

DROP POLICY IF EXISTS "Call participants view signaling" ON public.call_signals;
DROP POLICY IF EXISTS "Call participants view call signals" ON public.call_signals;
CREATE POLICY "Call participants view call signals"
    ON public.call_signals FOR SELECT TO authenticated
    USING (
        (sender_id = (SELECT auth.uid()) OR recipient_id = (SELECT auth.uid()))
        AND NOT public.is_blocked_between(sender_id, recipient_id)
    );

DROP POLICY IF EXISTS "Call senders create signaling" ON public.call_signals;
DROP POLICY IF EXISTS "Users send call signals as themselves" ON public.call_signals;
CREATE POLICY "Users send call signals as themselves"
    ON public.call_signals FOR INSERT TO authenticated
    WITH CHECK (
        sender_id = (SELECT auth.uid())
        AND sender_id <> recipient_id
        AND NOT public.is_blocked_between(sender_id, recipient_id)
    );

DROP POLICY IF EXISTS "Call participants delete signaling" ON public.call_signals;
DROP POLICY IF EXISTS "Call participants delete call signals" ON public.call_signals;
CREATE POLICY "Call participants delete call signals"
    ON public.call_signals FOR DELETE TO authenticated
    USING (
        (sender_id = (SELECT auth.uid()) OR recipient_id = (SELECT auth.uid()))
        AND NOT public.is_blocked_between(sender_id, recipient_id)
    );

INSERT INTO storage.buckets (
    id, name, public, file_size_limit, allowed_mime_types
)
VALUES (
    'campus-private-media',
    'campus-private-media',
    FALSE,
    524288000,
    ARRAY['image/*', 'video/*']
)
ON CONFLICT (id) DO UPDATE
SET public = FALSE,
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
        )
    );

DROP POLICY IF EXISTS "Users delete own private social media" ON storage.objects;
CREATE POLICY "Users delete own private social media"
    ON storage.objects FOR DELETE TO authenticated
    USING (
        bucket_id = 'campus-private-media'
        AND (storage.foldername(name))[1] = (SELECT auth.uid())::TEXT
    );

COMMIT;

-- ================ PART 4/17: migrations/20261011_student_interactions_and_calls.sql ================
BEGIN;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS is_discoverable BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS public.call_signals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    call_id UUID NOT NULL,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('offer', 'answer', 'ice', 'end', 'reject', 'busy')),
    payload JSONB NOT NULL DEFAULT '{}'::JSONB
        CHECK (
            jsonb_typeof(payload) = 'object'
            AND octet_length(payload::TEXT) <= 65536
        ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (sender_id <> recipient_id)
);

CREATE INDEX IF NOT EXISTS call_signals_recipient_created_idx
    ON public.call_signals (recipient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS call_signals_sender_created_idx
    ON public.call_signals (sender_id, created_at DESC);

ALTER TABLE public.call_signals ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, DELETE ON public.call_signals TO authenticated;

DROP POLICY IF EXISTS "Call participants view signaling"
    ON public.call_signals;
CREATE POLICY "Call participants view signaling"
    ON public.call_signals
    FOR SELECT TO authenticated
    USING (
        (SELECT auth.uid()) = sender_id
        OR (SELECT auth.uid()) = recipient_id
    );

DROP POLICY IF EXISTS "Call senders create signaling"
    ON public.call_signals;
CREATE POLICY "Call senders create signaling"
    ON public.call_signals
    FOR INSERT TO authenticated
    WITH CHECK (
        (SELECT auth.uid()) = sender_id
        AND sender_id <> recipient_id
    );

DROP POLICY IF EXISTS "Call participants delete signaling"
    ON public.call_signals;
CREATE POLICY "Call participants delete signaling"
    ON public.call_signals
    FOR DELETE TO authenticated
    USING (
        (SELECT auth.uid()) = sender_id
        OR (SELECT auth.uid()) = recipient_id
    );

DO $realtime$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'call_signals'
    ) THEN
        ALTER PUBLICATION supabase_realtime
            ADD TABLE public.call_signals;
    END IF;
END;
$realtime$;

DROP POLICY IF EXISTS "Profiles are viewable by authenticated users"
    ON public.profiles;

DO $migration$
DECLARE
    visibility_rule TEXT := $policy$
        auth.uid() = id
        OR is_discoverable
        OR EXISTS (
            SELECT 1
            FROM public.messages AS message
            WHERE (message.sender_id = auth.uid() AND message.receiver_id = profiles.id)
               OR (message.receiver_id = auth.uid() AND message.sender_id = profiles.id)
        )
    $policy$;
BEGIN
    IF to_regclass('public.community_members') IS NOT NULL THEN
        visibility_rule := visibility_rule || $policy$
            OR EXISTS (
            SELECT 1
            FROM public.community_members AS own_membership
            JOIN public.community_members AS peer_membership
                ON peer_membership.community_id = own_membership.community_id
            WHERE own_membership.user_id = auth.uid()
              AND peer_membership.user_id = profiles.id
            )
        $policy$;
    END IF;

    EXECUTE format(
        'CREATE POLICY "Profiles are viewable by authenticated users" '
        'ON public.profiles FOR SELECT TO authenticated USING (%s)',
        visibility_rule
    );
END;
$migration$;

COMMIT;

-- ================ PART 5/17: migrations/20261012_friendships_attachments_notification_preferences.sql ================
BEGIN;

-- Explicit friend requests are separate from the existing one-way follow graph.
CREATE TABLE IF NOT EXISTS public.friend_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (requester_id <> recipient_id),
    UNIQUE (requester_id, recipient_id)
);

CREATE INDEX IF NOT EXISTS friend_requests_recipient_status_idx
    ON public.friend_requests (recipient_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS friend_requests_requester_status_idx
    ON public.friend_requests (requester_id, status, created_at DESC);

CREATE TABLE IF NOT EXISTS public.message_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE,
    community_message_id UUID REFERENCES public.community_messages(id) ON DELETE CASCADE,
    uploader_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    file_name TEXT NOT NULL CHECK (char_length(file_name) BETWEEN 1 AND 255),
    mime_type TEXT NOT NULL CHECK (char_length(mime_type) BETWEEN 1 AND 160),
    file_size BIGINT NOT NULL CHECK (file_size > 0 AND file_size <= 524288000),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (num_nonnulls(message_id, community_message_id) = 1),
    UNIQUE (storage_path)
);

CREATE INDEX IF NOT EXISTS message_attachments_message_idx
    ON public.message_attachments (message_id, created_at);
CREATE INDEX IF NOT EXISTS message_attachments_community_message_idx
    ON public.message_attachments (community_message_id, created_at);
CREATE INDEX IF NOT EXISTS message_attachments_uploader_idx
    ON public.message_attachments (uploader_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.notification_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    messages BOOLEAN NOT NULL DEFAULT TRUE,
    friend_requests BOOLEAN NOT NULL DEFAULT TRUE,
    follows BOOLEAN NOT NULL DEFAULT TRUE,
    post_activity BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.friend_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.friend_requests TO authenticated;
REVOKE UPDATE ON public.friend_requests FROM authenticated;
GRANT UPDATE (status) ON public.friend_requests TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.message_attachments TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.notification_preferences TO authenticated;

DROP POLICY IF EXISTS "Users view their own friend requests" ON public.friend_requests;
CREATE POLICY "Users view their own friend requests"
    ON public.friend_requests FOR SELECT TO authenticated
    USING (requester_id = (SELECT auth.uid()) OR recipient_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users send friend requests as themselves" ON public.friend_requests;
CREATE POLICY "Users send friend requests as themselves"
    ON public.friend_requests FOR INSERT TO authenticated
    WITH CHECK (
        requester_id = (SELECT auth.uid())
        AND requester_id <> recipient_id
        AND status = 'pending'
        AND NOT public.is_blocked_between(requester_id, recipient_id)
    );

DROP POLICY IF EXISTS "Recipients respond to friend requests" ON public.friend_requests;
CREATE POLICY "Recipients respond to friend requests"
    ON public.friend_requests FOR UPDATE TO authenticated
    USING (recipient_id = (SELECT auth.uid()) AND status = 'pending')
    WITH CHECK (
        recipient_id = (SELECT auth.uid())
        AND status IN ('accepted', 'declined')
    );

DROP POLICY IF EXISTS "Requesters cancel pending friend requests" ON public.friend_requests;
CREATE POLICY "Requesters cancel pending friend requests"
    ON public.friend_requests FOR DELETE TO authenticated
    USING (requester_id = (SELECT auth.uid()) AND status = 'pending');

DROP POLICY IF EXISTS "Chat participants view attachments" ON public.message_attachments;
CREATE POLICY "Chat participants view attachments"
    ON public.message_attachments FOR SELECT TO authenticated
    USING (
        uploader_id = (SELECT auth.uid())
        OR EXISTS (
            SELECT 1 FROM public.messages AS message
            WHERE message.id = message_attachments.message_id
              AND (message.sender_id = (SELECT auth.uid()) OR message.receiver_id = (SELECT auth.uid()))
        )
        OR EXISTS (
            SELECT 1 FROM public.community_messages AS message
            WHERE message.id = message_attachments.community_message_id
              AND public.is_community_member(message.community_id)
        )
    );

DROP POLICY IF EXISTS "Users attach files to their own messages" ON public.message_attachments;
CREATE POLICY "Users attach files to their own messages"
    ON public.message_attachments FOR INSERT TO authenticated
    WITH CHECK (
        uploader_id = (SELECT auth.uid())
        AND (
            EXISTS (
                SELECT 1 FROM public.messages AS message
                WHERE message.id = message_attachments.message_id
                  AND message.sender_id = (SELECT auth.uid())
            )
            OR EXISTS (
                SELECT 1 FROM public.community_messages AS message
                WHERE message.id = message_attachments.community_message_id
                  AND message.sender_id = (SELECT auth.uid())
                  AND public.is_community_member(message.community_id)
            )
        )
    );

DROP POLICY IF EXISTS "Users remove their uploaded attachments" ON public.message_attachments;
CREATE POLICY "Users remove their uploaded attachments"
    ON public.message_attachments FOR DELETE TO authenticated
    USING (uploader_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users view their notification preferences" ON public.notification_preferences;
CREATE POLICY "Users view their notification preferences"
    ON public.notification_preferences FOR SELECT TO authenticated
    USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users create their notification preferences" ON public.notification_preferences;
CREATE POLICY "Users create their notification preferences"
    ON public.notification_preferences FOR INSERT TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users update their notification preferences" ON public.notification_preferences;
CREATE POLICY "Users update their notification preferences"
    ON public.notification_preferences FOR UPDATE TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

CREATE OR REPLACE FUNCTION public.notify_friend_request()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.notifications (recipient_id, actor_id, kind)
    VALUES (NEW.recipient_id, NEW.requester_id, 'friend_request');
    RETURN NEW;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'public.notifications'::REGCLASS
          AND conname = 'notifications_kind_check'
    ) THEN
        ALTER TABLE public.notifications
            ADD CONSTRAINT notifications_kind_check
            CHECK (kind IN ('reaction', 'comment', 'follow', 'message', 'friend_request'));
    ELSE
        ALTER TABLE public.notifications DROP CONSTRAINT notifications_kind_check;
        ALTER TABLE public.notifications
            ADD CONSTRAINT notifications_kind_check
            CHECK (kind IN ('reaction', 'comment', 'follow', 'message', 'friend_request'));
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS friend_requests_notify_recipient ON public.friend_requests;
CREATE TRIGGER friend_requests_notify_recipient
    AFTER INSERT ON public.friend_requests
    FOR EACH ROW EXECUTE FUNCTION public.notify_friend_request();
REVOKE ALL ON FUNCTION public.notify_friend_request() FROM PUBLIC, anon, authenticated;

COMMIT;

-- ================ PART 6/17: migrations/20261012_respond_to_chat_invitations.sql ================
BEGIN;

-- Let a recipient accept or decline a one-way follow invitation. Accepting
-- creates the reciprocal follow used by the app's mutual-connection checks.
CREATE OR REPLACE FUNCTION public.respond_to_chat_invitation(
    p_inviter_id UUID,
    p_accept BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    current_user_id UUID := auth.uid();
    invitation_exists BOOLEAN;
    blocked BOOLEAN := FALSE;
BEGIN
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'You must be signed in to respond to invitations.';
    END IF;
    IF p_inviter_id IS NULL OR p_inviter_id = current_user_id OR p_accept IS NULL THEN
        RAISE EXCEPTION 'This invitation is invalid.';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.follows
        WHERE follower_id = p_inviter_id
          AND following_id = current_user_id
    ) INTO invitation_exists;

    IF NOT invitation_exists THEN
        RAISE EXCEPTION 'This invitation is no longer pending.';
    END IF;

    -- The blocking migration is optional on older deployments. Check it when
    -- its table exists without making this function depend on that migration.
    IF to_regclass('public.user_blocks') IS NOT NULL THEN
        EXECUTE
            'SELECT EXISTS (
                SELECT 1 FROM public.user_blocks
                WHERE (blocker_id = $1 AND blocked_id = $2)
                   OR (blocker_id = $2 AND blocked_id = $1)
            )'
            INTO blocked
            USING current_user_id, p_inviter_id;
    END IF;

    IF p_accept THEN
        IF blocked THEN
            RAISE EXCEPTION 'Unblock this member before accepting the invitation.';
        END IF;

        INSERT INTO public.follows (follower_id, following_id)
        VALUES (current_user_id, p_inviter_id)
        ON CONFLICT (follower_id, following_id) DO NOTHING;
    ELSE
        DELETE FROM public.follows
        WHERE follower_id = p_inviter_id
          AND following_id = current_user_id;
    END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.respond_to_chat_invitation(UUID, BOOLEAN)
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.respond_to_chat_invitation(UUID, BOOLEAN)
    TO authenticated;

-- A member can view the profile and avatar of accounts that follow them,
-- including accounts hidden from global search. Blocks still override access.
DROP POLICY IF EXISTS "Members view profiles of their followers" ON public.profiles;
DO $migration$
DECLARE
    follower_visibility TEXT := $policy$
        (SELECT auth.uid()) IS NOT NULL
        AND EXISTS (
            SELECT 1
            FROM public.follows AS relationship
            WHERE relationship.follower_id = public.profiles.id
              AND relationship.following_id = (SELECT auth.uid())
        )
    $policy$;
BEGIN
    IF to_regclass('public.user_blocks') IS NOT NULL THEN
        follower_visibility := follower_visibility || $policy$
            AND NOT EXISTS (
                SELECT 1
                FROM public.user_blocks AS block
                WHERE (block.blocker_id = (SELECT auth.uid()) AND block.blocked_id = public.profiles.id)
                   OR (block.blocker_id = public.profiles.id AND block.blocked_id = (SELECT auth.uid()))
            )
        $policy$;
    END IF;

    EXECUTE format(
        'CREATE POLICY "Members view profiles of their followers" '
        'ON public.profiles FOR SELECT TO authenticated USING (%s)',
        follower_visibility
    );
END;
$migration$;

COMMIT;

-- ================ PART 7/17: migrations/20261013_find_people.sql ================
-- ============================================================
-- STEP 1 / FINDING PEOPLE
-- Makes members discoverable by default, lets a user claim a unique
-- username, and lets an invite link resolve a username to a member.
--
-- Safe to run more than once: every statement is IF NOT EXISTS,
-- CREATE OR REPLACE, or an idempotent ALTER/GRANT.
-- Run this file AFTER database/schema.sql and AFTER every file in
-- database/migrations/.
-- ============================================================


-- ------------------------------------------------------------
-- 1. BE DISCOVERABLE BY DEFAULT
-- profiles.is_discoverable was added with DEFAULT FALSE, so nobody
-- could appear in search. New accounts now start discoverable.
-- ------------------------------------------------------------

ALTER TABLE public.profiles
    ALTER COLUMN is_discoverable SET DEFAULT TRUE;


-- ------------------------------------------------------------
-- 2. EXISTING MEMBERS
-- Without this, every account that already exists stays invisible and
-- "can't find each other" continues for your current users.
-- Delete this single statement if you would rather people opt in.
-- ------------------------------------------------------------

UPDATE public.profiles
    SET is_discoverable = TRUE
    WHERE is_discoverable IS DISTINCT FROM TRUE;


-- ------------------------------------------------------------
-- 3. USERNAME LOOKUP SUPPORT
-- No index work needed: username already has a UNIQUE constraint, a
-- CHECK that stores it lowercase, and a trigram index
-- (profiles_username_search_idx) from schema.sql. Invite links do an
-- exact match, which the UNIQUE constraint already serves.
-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- 4. CHECK A USERNAME IS FREE AND WELL FORMED
-- SECURITY DEFINER: a plain SELECT cannot see rows the caller may not
-- read, so uniqueness could not be verified otherwise. The function
-- only reveals "taken / free", never who owns it.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.username_available(p_username TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    candidate TEXT := LOWER(TRIM(COALESCE(p_username, '')));
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN FALSE;
    END IF;

    IF candidate !~ '^[a-z0-9_]{3,30}$' THEN
        RETURN FALSE;
    END IF;

    RETURN NOT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE LOWER(username) = candidate
          AND id <> auth.uid()
    );
END;
$$;

REVOKE ALL ON FUNCTION public.username_available(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.username_available(TEXT) TO authenticated;


-- ------------------------------------------------------------
-- 5. CHANGE MY USERNAME
-- Validates shape first so a bad value cannot reach the table CHECK,
-- then updates only the caller's own row.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_my_username(p_username TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    candidate TEXT := LOWER(TRIM(COALESCE(p_username, '')));
    updated_username TEXT;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Sign in to choose a username.'
            USING ERRCODE = '28000';
    END IF;

    IF candidate !~ '^[a-z0-9_]{3,30}$' THEN
        RAISE EXCEPTION 'Usernames are 3-30 characters: a-z, 0-9, underscore.'
            USING ERRCODE = '22023';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.profiles
        WHERE LOWER(username) = candidate AND id <> auth.uid()
    ) THEN
        RAISE EXCEPTION 'That username is already taken.'
            USING ERRCODE = '23505';
    END IF;

    UPDATE public.profiles
        SET username = candidate
        WHERE id = auth.uid()
        RETURNING public.profiles.username INTO updated_username;

    RETURN updated_username;
END;
$$;

REVOKE ALL ON FUNCTION public.set_my_username(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_my_username(TEXT) TO authenticated;


-- ------------------------------------------------------------
-- 6. RESOLVE AN INVITE LINK
-- No function needed. The client selects the profile row by username,
-- and the existing "Profiles are viewable by authenticated users"
-- policy already decides the outcome: a member who turned "hide me
-- from search" off returns no row, and so does a member who blocked
-- the visitor. Doing it in the policy means one code path and no extra
-- SECURITY DEFINER surface.
-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- 7. RELOAD THE API SCHEMA CACHE
-- ------------------------------------------------------------

NOTIFY pgrst, 'reload schema';


-- ------------------------------------------------------------
-- 8. VERIFY
-- Expected: 3 rows, all result = 'ok'.
-- ------------------------------------------------------------

SELECT 'discoverable_default' AS check_name,
       CASE WHEN (
           SELECT column_default
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'profiles'
             AND column_name = 'is_discoverable'
       ) LIKE '%true%' THEN 'ok' ELSE 'FAILED' END AS result
UNION ALL
SELECT 'functions_created',
       CASE WHEN COUNT(*) = 2 THEN 'ok' ELSE 'FAILED (' || COUNT(*) || '/2)' END
FROM pg_proc AS p
JOIN pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('username_available', 'set_my_username')
UNION ALL
SELECT 'everyone_discoverable',
       CASE WHEN COUNT(*) = 0 THEN 'ok' ELSE 'FAILED (' || COUNT(*) || ' hidden)' END
FROM public.profiles
WHERE is_discoverable IS DISTINCT FROM TRUE;

-- ================ PART 8/17: migrations/20261014_roles_and_admin.sql ================
-- ============================================================
-- CAMPUS CONNECT — ROLES, APPROVAL, AND ADMIN
-- Kabarak University: Student / Lecturer / Security / Admin.
--
-- Idempotent: safe to run more than once. Uses DROP ... IF EXISTS,
-- CREATE OR REPLACE, ADD COLUMN IF NOT EXISTS, and catalog checks
-- around index creation.
--
-- RUN ORDER
--   1. database/schema.sql
--   2. every file in database/migrations/ that already exists
--   3. database/migrations/20261013_find_people.sql
--   4. THIS FILE
-- ============================================================


-- ------------------------------------------------------------
-- 1. ROLE COLUMNS ON PROFILES
-- Existing members become students and stay approved, so nothing that
-- works today breaks after this runs.
-- ------------------------------------------------------------

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'student';

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS verification_status TEXT NOT NULL DEFAULT 'approved';

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS requested_role TEXT NOT NULL DEFAULT '';

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS university TEXT NOT NULL DEFAULT '';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'profiles_role_check' AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_role_check
            CHECK (role IN ('student', 'lecturer', 'security', 'admin'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'profiles_verification_status_check'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_verification_status_check
            CHECK (verification_status IN ('pending', 'approved', 'rejected'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'profiles_requested_role_check'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_requested_role_check
            CHECK (requested_role IN ('', 'student', 'lecturer', 'security'));
    END IF;
END;
$$;

-- Rows that existed before this migration already carry the new column
-- defaults (student, approved). An UPDATE here used to force every role
-- back to student, which silently demoted admins and lecturers whenever
-- the setup was run a second time, so it is deliberately not done.


-- ------------------------------------------------------------
-- 2. REGISTRATION NUMBERS LIVE IN THEIR OWN TABLE
-- The profile screen reads profiles with select('*). Keeping the
-- number there would hand it to anyone allowed to read the row.
-- In its own table, Row Level Security can limit it to the owner and
-- to admins, which is what stops anyone browsing student numbers.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.student_registrations (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    registration_number TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT student_registrations_number_format_check
        CHECK (registration_number ~ '^[A-Za-z0-9][-./ A-Za-z0-9]{2,31}$')
);

CREATE UNIQUE INDEX IF NOT EXISTS student_registrations_number_key
    ON public.student_registrations (registration_number);

ALTER TABLE public.student_registrations ENABLE ROW LEVEL SECURITY;


-- ------------------------------------------------------------
-- 3. WHO AM I — admin check that does not recurse through RLS
-- SECURITY DEFINER so reading profiles.role is allowed inside the
-- policies that themselves consult profiles.role.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT COALESCE(
        (SELECT p.role = 'admin' FROM public.profiles AS p WHERE p.id = auth.uid()),
        FALSE
    );
$$;

CREATE OR REPLACE FUNCTION public.my_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT COALESCE(
        (SELECT p.role FROM public.profiles AS p WHERE p.id = auth.uid()),
        'student'
    );
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.my_role() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.my_role() TO authenticated;


-- ------------------------------------------------------------
-- 4. A MEMBER CANNOT PROMOTE THEMSELF
-- This is the whole point of the feature: without it, anyone could set
-- role='security' and read every found ID. RLS policies alone cannot
-- compare old and new column values, so a trigger does it.
--
-- On INSERT the role is forced to student. A person who wants lecturer
-- or security access only ever stores a REQUEST, which an admin acts on.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.enforce_profile_role_integrity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
-- Any request coming through the API carries a signed-in user, so
-- auth.uid() is set. It is NULL only for the SQL Editor, the service
-- key, and migrations like the admin seed in section 9 — the app owner
-- working directly in the database. Anonymous API traffic never reaches
-- this trigger, because every policy on profiles is TO authenticated.
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF public.is_admin() AND NEW.role IS NOT NULL THEN
            RETURN NEW;
        END IF;
        -- Sign-up can carry a request, never a role.
        NEW.role := 'student';
        IF NEW.requested_role IN ('lecturer', 'security') THEN
            NEW.verification_status := 'pending';
        ELSE
            NEW.verification_status := 'approved';
            NEW.requested_role := '';
        END IF;
        RETURN NEW;
    END IF;

    -- A member may ask for a role; only an admin may grant one.
    IF NEW.requested_role IS DISTINCT FROM OLD.requested_role THEN
        -- Withdrawing a request puts a plain student back in good
        -- standing. This grants nothing: student is the baseline role.
        IF NEW.requested_role = ''
           AND OLD.role = 'student'
           AND NOT public.is_admin() THEN
            NEW.verification_status := 'approved';
            RETURN NEW;
        END IF;

        IF NEW.requested_role <> '' AND NOT public.is_admin() THEN
            IF OLD.verification_status = 'rejected' AND OLD.requested_role = NEW.requested_role THEN
                RAISE EXCEPTION 'An admin already rejected that role request.'
                    USING ERRCODE = '42501';
            END IF;
            -- The request only marks the account pending. NEW.role keeps
            -- its old value, so asking for another role can never promote
            -- the sender and can never demote one an admin already granted.
            NEW.verification_status := 'pending';
            RETURN NEW;
        END IF;
    END IF;

    IF NEW.role IS DISTINCT FROM OLD.role
       OR NEW.verification_status IS DISTINCT FROM OLD.verification_status THEN
        IF NOT public.is_admin() THEN
            RAISE EXCEPTION 'Only an admin can change a role or approval status.'
                USING ERRCODE = '42501';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_profile_role_integrity() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS profiles_enforce_role_integrity ON public.profiles;
CREATE TRIGGER profiles_enforce_role_integrity
    BEFORE INSERT OR UPDATE
    ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_profile_role_integrity();


-- ------------------------------------------------------------
-- 5. ADMIN ACTION LOG
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.admin_action_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    target_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    detail TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT admin_action_log_action_check
        CHECK (action IN ('approve', 'reject', 'set_role', 'reset_role_request'))
);

CREATE INDEX IF NOT EXISTS admin_action_log_target_idx
    ON public.admin_action_log (target_user_id, created_at DESC);

ALTER TABLE public.admin_action_log ENABLE ROW LEVEL SECURITY;


-- ------------------------------------------------------------
-- 6. POLICIES
-- ------------------------------------------------------------

-- Own registration row; admins see all so they can verify a claimant.
DROP POLICY IF EXISTS "Members manage their own registration number"
    ON public.student_registrations;
CREATE POLICY "Members manage their own registration number"
    ON public.student_registrations
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins view all registration numbers"
    ON public.student_registrations;
CREATE POLICY "Admins view all registration numbers"
    ON public.student_registrations
    FOR SELECT TO authenticated
    USING (public.is_admin());

-- The registration number is immutable once set, so a member cannot
-- trade it around; only an admin may move it.
CREATE OR REPLACE FUNCTION public.enforce_registration_immutable()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.registration_number IS DISTINCT FROM OLD.registration_number
       AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only an admin can change a registration number.'
            USING ERRCODE = '42501';
    END IF;
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_registration_immutable() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS student_registrations_enforce_immutable ON public.student_registrations;
CREATE TRIGGER student_registrations_enforce_immutable
    BEFORE UPDATE
    ON public.student_registrations
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_registration_immutable();

-- Admins may read every profile, including members hidden from search,
-- so they can review a pending request.
DROP POLICY IF EXISTS "Admins view all profiles"
    ON public.profiles;
CREATE POLICY "Admins view all profiles"
    ON public.profiles
    FOR SELECT TO authenticated
    USING (public.is_admin());

DROP POLICY IF EXISTS "Admins view audit log"
    ON public.admin_action_log;
CREATE POLICY "Admins view audit log"
    ON public.admin_action_log
    FOR SELECT TO authenticated
    USING (public.is_admin());


-- ------------------------------------------------------------
-- 7. ADMIN-ONLY CHANGES RUN AS DEFINER
-- Deliberately narrow: an admin gets these three operations, not a
-- blanket right to edit anyone's profile.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.approve_membership(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only an admin can approve a role request.'
            USING ERRCODE = '42501';
    END IF;

    UPDATE public.profiles
        SET verification_status = 'approved',
            role = CASE WHEN requested_role IN ('lecturer', 'security')
                        THEN requested_role ELSE role END
        WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No such member.' USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO public.admin_action_log (actor_id, target_user_id, action)
        VALUES (auth.uid(), p_user_id, 'approve');
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_membership(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only an admin can reject a role request.'
            USING ERRCODE = '42501';
    END IF;

    UPDATE public.profiles
        SET verification_status = 'rejected'
        WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No such member.' USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO public.admin_action_log (actor_id, target_user_id, action)
        VALUES (auth.uid(), p_user_id, 'reject');
END;
$$;

CREATE OR REPLACE FUNCTION public.set_user_role(p_user_id UUID, p_role TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only an admin can change a role.'
            USING ERRCODE = '42501';
    END IF;

    IF p_role NOT IN ('student', 'lecturer', 'security', 'admin') THEN
        RAISE EXCEPTION 'Unknown role.' USING ERRCODE = '22023';
    END IF;

    -- Refuse to lock everybody out of the admin screen.
    IF p_role <> 'admin'
       AND (SELECT role FROM public.profiles WHERE id = p_user_id) = 'admin'
       AND (SELECT COUNT(*) FROM public.profiles WHERE role = 'admin') <= 1 THEN
        RAISE EXCEPTION 'That is the last admin. Appoint another admin first.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE public.profiles
        SET role = p_role,
            verification_status = 'approved',
            requested_role = ''
        WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No such member.' USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO public.admin_action_log (actor_id, target_user_id, action, detail)
        VALUES (auth.uid(), p_user_id, 'set_role', p_role);
END;
$$;

REVOKE ALL ON FUNCTION public.approve_membership(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.reject_membership(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.set_user_role(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.approve_membership(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_membership(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_user_role(UUID, TEXT) TO authenticated;


-- ------------------------------------------------------------
-- 8. TABLE GRANTS
-- ------------------------------------------------------------

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.student_registrations TO authenticated;
GRANT SELECT ON public.admin_action_log TO authenticated;


-- ------------------------------------------------------------
-- 9. SEED THE FIRST ADMIN
-- A chicken-and-egg problem: only an admin can appoint an admin, so the
-- very first one has to be written in by hand. Replace the placeholder
-- below with YOUR OWN login email, then run this block. It is safe to
-- repeat. Skip it entirely if you would rather do it later.
-- ------------------------------------------------------------

DO $$
DECLARE
    admin_email TEXT := 'REPLACE-WITH-YOUR-EMAIL';
    admin_id UUID;
BEGIN
    IF admin_email LIKE 'REPLACE-WITH%' THEN
        RAISE NOTICE 'Admin seed skipped: replace the placeholder email first.';
        RETURN;
    END IF;

    SELECT u.id INTO admin_id FROM auth.users AS u WHERE LOWER(u.email) = LOWER(admin_email);
    IF admin_id IS NULL THEN
        RAISE EXCEPTION 'No auth user with email %', admin_email;
    END IF;

    INSERT INTO public.profiles (id, username, full_name)
        VALUES (admin_id, 'admin' || LEFT(admin_id::TEXT, 6), 'Admin')
        ON CONFLICT (id) DO NOTHING;

    UPDATE public.profiles
        SET role = 'admin', verification_status = 'approved', requested_role = ''
        WHERE id = admin_id;

    RAISE NOTICE 'Seeded admin %', admin_email;
END;
$$;


-- ------------------------------------------------------------
-- 10. RELOAD THE API SCHEMA CACHE
-- ------------------------------------------------------------

NOTIFY pgrst, 'reload schema';


-- ------------------------------------------------------------
-- 11. VERIFY
-- Expected: five rows, all result = 'ok'.
-- ------------------------------------------------------------

SELECT 'role_columns' AS check_name,
       CASE WHEN COUNT(*) = 4 THEN 'ok'
            ELSE 'FAILED (' || COUNT(*) || '/4)' END AS result
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'profiles'
  AND column_name IN ('role', 'verification_status', 'requested_role', 'university')
UNION ALL
SELECT 'role_guard_trigger',
       CASE WHEN COUNT(*) = 1 THEN 'ok' ELSE 'FAILED (missing)' END
FROM pg_trigger WHERE tgname = 'profiles_enforce_role_integrity' AND NOT tgisinternal
UNION ALL
SELECT 'admin_rpc_count',
       CASE WHEN COUNT(*) = 3 THEN 'ok' ELSE 'FAILED (' || COUNT(*) || '/3)' END
FROM pg_proc AS p JOIN pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('approve_membership', 'reject_membership', 'set_user_role')
UNION ALL
SELECT 'registrations_table',
       CASE WHEN COUNT(*) = 1 THEN 'ok' ELSE 'FAILED (missing)' END
FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'student_registrations'
UNION ALL
SELECT 'at_least_one_admin',
       CASE WHEN COUNT(*) > 0 THEN 'ok' ELSE 'NONE YET (run section 9)' END
FROM public.profiles WHERE role = 'admin';

-- ============ PART 9/17: migrations/20261014_message_edit_delete.sql ============
-- ============================================================
-- MESSAGE EDIT + DELETE (run this whole file in Supabase SQL Editor)
-- Rules enforced inside the database, not just the app:
--   * sender may edit own text messages within 20 minutes
--   * sender may delete for everyone within 15 minutes
--   * any participant may hide a message for themselves, any time
-- Safe to run repeatedly.
-- ============================================================

ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS edited_at timestamptz,
    ADD COLUMN IF NOT EXISTS deleted_for_everyone boolean NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS deleted_by uuid[] NOT NULL DEFAULT '{}';

DROP POLICY IF EXISTS "Recipients mark messages as read" ON public.messages;
DROP POLICY IF EXISTS "Participants update their messages" ON public.messages;

CREATE POLICY "Participants update their messages"
    ON public.messages FOR UPDATE TO authenticated
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id)
    WITH CHECK (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE OR REPLACE FUNCTION public.protect_message_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
    actor uuid := auth.uid();
BEGIN
    IF NEW.id IS DISTINCT FROM OLD.id
       OR NEW.sender_id IS DISTINCT FROM OLD.sender_id
       OR NEW.receiver_id IS DISTINCT FROM OLD.receiver_id
       OR NEW.created_at IS DISTINCT FROM OLD.created_at
    THEN
        RAISE EXCEPTION 'Message id, sender, receiver and creation time cannot be changed.';
    END IF;

    IF NEW.deleted_for_everyone IS DISTINCT FROM OLD.deleted_for_everyone THEN
        IF NEW.deleted_for_everyone <> TRUE
           OR actor IS DISTINCT FROM OLD.sender_id
           OR OLD.deleted_for_everyone
           OR OLD.created_at <= now() - interval '15 minutes'
        THEN
            RAISE EXCEPTION 'Only the sender can delete for everyone within 15 minutes.';
        END IF;
        NEW.content := NULL;
        NEW.media_url := NULL;
    ELSIF NEW.media_url IS DISTINCT FROM OLD.media_url THEN
        RAISE EXCEPTION 'Message media cannot be changed.';
    ELSIF NEW.content IS DISTINCT FROM OLD.content THEN
        IF actor IS DISTINCT FROM OLD.sender_id
           OR OLD.deleted_for_everyone
           OR OLD.created_at <= now() - interval '20 minutes'
        THEN
            RAISE EXCEPTION 'Only the sender can edit a message within 20 minutes.';
        END IF;
        NEW.edited_at := now();
    END IF;

    IF NEW.deleted_by IS DISTINCT FROM OLD.deleted_by THEN
        IF actor IS NULL
           OR (actor <> OLD.sender_id AND actor <> OLD.receiver_id)
           OR NOT (OLD.deleted_by <@ NEW.deleted_by)
           OR NOT (actor = ANY (NEW.deleted_by))
           OR coalesce(array_length(NEW.deleted_by, 1), 0) <>
              coalesce(array_length(OLD.deleted_by, 1), 0) + 1
        THEN
            RAISE EXCEPTION 'A participant can only hide a message for themselves.';
        END IF;
    END IF;

    IF NEW.edited_at IS DISTINCT FROM OLD.edited_at
       AND NOT (NEW.content IS DISTINCT FROM OLD.content)
    THEN
        RAISE EXCEPTION 'The edit timestamp changes only with an actual edit.';
    END IF;

    IF NEW.is_read IS DISTINCT FROM OLD.is_read THEN
        IF OLD.is_read = TRUE AND NEW.is_read = FALSE THEN
            RAISE EXCEPTION 'A read message cannot be marked unread.';
        END IF;
        IF NEW.is_read = TRUE AND NEW.read_at IS NULL THEN
            NEW.read_at := NOW();
        END IF;
    END IF;

    IF NEW.is_read = FALSE THEN
        NEW.read_at := NULL;
    END IF;

    RETURN NEW;
END;
$$;

-- The trigger already exists from schema.sql; reattach to pick up the new body.
DROP TRIGGER IF EXISTS protect_message_fields_trigger ON public.messages;
CREATE TRIGGER protect_message_fields_trigger
    BEFORE UPDATE ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_message_fields();


-- ============ PART 10/17: migrations/20261015_programmes_units_classes.sql ============
-- ============================================================
-- CAMPUS CONNECT — PROGRAMMES, UNITS, AND CLASS TIMETABLES
-- Kabarak University course system:
--   * programmes: schools and degrees (seeded below)
--   * units: course units per programme/year/semester (lecturers add)
--   * class_sessions: weekly class plan (time, room, or online link)
--   * profiles: each member can attach programme + year + semester
--     which the app shows as 1.1, 2.2, M1.1, ...
-- Idempotent: safe to run more than once.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.programmes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school TEXT NOT NULL,
    name TEXT NOT NULL,
    level TEXT NOT NULL DEFAULT 'undergraduate',
    max_year INT NOT NULL DEFAULT 4,
    campus TEXT NOT NULL DEFAULT 'Main',
    specializations TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT programmes_level_check
        CHECK (level IN ('certificate', 'diploma', 'undergraduate', 'masters', 'phd')),
    CONSTRAINT programmes_school_name_key UNIQUE (school, name)
);

ALTER TABLE public.programmes
    ADD COLUMN IF NOT EXISTS campus TEXT NOT NULL DEFAULT 'Main',
    ADD COLUMN IF NOT EXISTS specializations TEXT NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS public.units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    programme_id UUID NOT NULL REFERENCES public.programmes(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    title TEXT NOT NULL,
    study_year INT NOT NULL CHECK (study_year BETWEEN 1 AND 6),
    semester INT NOT NULL CHECK (semester IN (1, 2)),
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT units_code_format_check CHECK (code ~ '^[A-Za-z0-9][-./ A-Za-z0-9]{1,15}$'),
    CONSTRAINT units_title_length_check CHECK (char_length(title) BETWEEN 2 AND 120),
    CONSTRAINT units_programme_code_key UNIQUE (programme_id, code)
);

CREATE TABLE IF NOT EXISTS public.class_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id UUID NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
    lecturer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    weekday INT NOT NULL CHECK (weekday BETWEEN 1 AND 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    mode TEXT NOT NULL DEFAULT 'physical',
    location TEXT NOT NULL DEFAULT '',
    link TEXT NOT NULL DEFAULT '',
    note TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT class_sessions_mode_check CHECK (mode IN ('physical', 'online')),
    CONSTRAINT class_sessions_time_order_check CHECK (end_time > start_time),
    CONSTRAINT class_sessions_link_length_check CHECK (char_length(link) <= 300)
);

CREATE INDEX IF NOT EXISTS units_programme_year_semester_idx
    ON public.units (programme_id, study_year, semester);
CREATE INDEX IF NOT EXISTS class_sessions_lecturer_idx
    ON public.class_sessions (lecturer_id, weekday, start_time);
CREATE INDEX IF NOT EXISTS class_sessions_unit_idx
    ON public.class_sessions (unit_id);

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS programme_id UUID REFERENCES public.programmes(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS study_year INT CHECK (study_year BETWEEN 1 AND 6),
    ADD COLUMN IF NOT EXISTS semester INT CHECK (semester IN (1, 2));

CREATE INDEX IF NOT EXISTS profiles_programme_idx
    ON public.profiles (programme_id, study_year, semester);

-- ------------------------------------------------------------
-- ROW LEVEL SECURITY
-- Members read everything that belongs to the public catalogue;
-- only lecturers and admins may write units and class plans,
-- and only their own rows.
-- ------------------------------------------------------------

ALTER TABLE public.programmes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members view programmes" ON public.programmes;
CREATE POLICY "Members view programmes"
    ON public.programmes FOR SELECT TO authenticated
    USING (TRUE);

DROP POLICY IF EXISTS "Members view units" ON public.units;
CREATE POLICY "Members view units"
    ON public.units FOR SELECT TO authenticated
    USING (TRUE);

DROP POLICY IF EXISTS "Lecturers add units" ON public.units;
CREATE POLICY "Lecturers add units"
    ON public.units FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = created_by
        AND public.my_role() IN ('lecturer', 'admin')
    );

DROP POLICY IF EXISTS "Owners and admins curate units" ON public.units;
CREATE POLICY "Owners and admins curate units"
    ON public.units FOR UPDATE TO authenticated
    USING (auth.uid() = created_by OR public.is_admin())
    WITH CHECK (
        auth.uid() = created_by
        AND public.my_role() IN ('lecturer', 'admin')
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "Owners and admins remove units" ON public.units;
CREATE POLICY "Owners and admins remove units"
    ON public.units FOR DELETE TO authenticated
    USING (auth.uid() = created_by OR public.is_admin());

DROP POLICY IF EXISTS "Members view class sessions" ON public.class_sessions;
CREATE POLICY "Members view class sessions"
    ON public.class_sessions FOR SELECT TO authenticated
    USING (TRUE);

DROP POLICY IF EXISTS "Lecturers plan their classes" ON public.class_sessions;
CREATE POLICY "Lecturers plan their classes"
    ON public.class_sessions FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = lecturer_id
        AND public.my_role() IN ('lecturer', 'admin')
    );

DROP POLICY IF EXISTS "Owners and admins edit class plans" ON public.class_sessions;
CREATE POLICY "Owners and admins edit class plans"
    ON public.class_sessions FOR UPDATE TO authenticated
    USING (auth.uid() = lecturer_id OR public.is_admin())
    WITH CHECK (
        auth.uid() = lecturer_id
        AND public.my_role() IN ('lecturer', 'admin')
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "Owners and admins remove class plans" ON public.class_sessions;
CREATE POLICY "Owners and admins remove class plans"
    ON public.class_sessions FOR DELETE TO authenticated
    USING (auth.uid() = lecturer_id OR public.is_admin());

GRANT SELECT ON public.programmes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.units TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.class_sessions TO authenticated;

-- ------------------------------------------------------------
-- SEED: KABARAK UNIVERSITY SCHOOLS AND PROGRAMMES
-- Full official list (school, level, programme, campus,
-- specializations/options). Lecturers add the unit lists in the app.
-- ON CONFLICT keeps edits made later in the app when this file is
-- run again.
-- ------------------------------------------------------------

INSERT INTO public.programmes (school, name, level, max_year, campus, specializations) VALUES
    -- School of Business and Economics
    ('School of Business and Economics', 'Doctor of Philosophy in Business Administration', 'phd', 3, 'Nakuru City', 'Accounting; Strategic Management; Human Resource Management; Finance; Marketing; Entrepreneurship; Management Information Systems; Operations Management'),
    ('School of Business and Economics', 'Doctor of Philosophy in Finance', 'phd', 3, 'Nakuru City', ''),
    ('School of Business and Economics', 'Master of Science in Finance', 'masters', 2, 'Nakuru City', 'Finance and Investment Analysis; Finance and Banking Management'),
    ('School of Business and Economics', 'Master of Business Administration (MBA)', 'masters', 2, 'Nakuru City', 'Accounting; Strategic Management; Human Resource Management; Finance; Marketing; Entrepreneurship; Management Information Systems; Operations Management'),
    ('School of Business and Economics', 'Master of Science in Project Management', 'masters', 2, 'Nakuru City', ''),
    ('School of Business and Economics', 'Master of Science in Human Resource Management', 'masters', 2, 'Nakuru City', ''),
    ('School of Business and Economics', 'Master of Organizational Development', 'masters', 2, 'Nakuru City', ''),
    ('School of Business and Economics', 'Bachelor of Science in Hospitality Management', 'undergraduate', 4, 'Main', ''),
    ('School of Business and Economics', 'Bachelor of Business Management and Information Technology (BMIT)', 'undergraduate', 4, 'Main; Nakuru City', ''),
    ('School of Business and Economics', 'Bachelor of Business Information Technology (BBIT)', 'undergraduate', 4, 'Main; Nakuru City', ''),
    ('School of Business and Economics', 'Bachelor of Commerce', 'undergraduate', 4, 'Main; Nakuru City', 'Accounting; Banking and Finance; Technology, Innovation and Entrepreneurship; Finance; Human Resource Management; Insurance; Marketing; Operations Management'),
    ('School of Business and Economics', 'Bachelor of Management Information Systems', 'undergraduate', 4, 'Main', ''),
    ('School of Business and Economics', 'Bachelor of Science in Economics and Mathematics', 'undergraduate', 4, 'Main', ''),
    ('School of Business and Economics', 'Bachelor of Science in Economics', 'undergraduate', 4, 'Main', ''),
    ('School of Business and Economics', 'Bachelor of Science in Economics and Statistics', 'undergraduate', 4, 'Main', ''),
    ('School of Business and Economics', 'Bachelor of Procurement and Logistics Management', 'undergraduate', 4, 'Main; Nakuru City', ''),
    ('School of Business and Economics', 'Bachelor of Science in Economics and Finance', 'undergraduate', 4, 'Main', ''),
    ('School of Business and Economics', 'Bachelor of Science in Agribusiness Management', 'undergraduate', 4, 'Main', ''),
    ('School of Business and Economics', 'Diploma in Business Administration', 'diploma', 2, 'Nakuru City', ''),
    ('School of Business and Economics', 'Diploma in Procurement and Logistics Management', 'diploma', 2, 'Nakuru City', ''),
    ('School of Business and Economics', 'Diploma in Business Management', 'diploma', 2, 'Nakuru City', ''),
    ('School of Business and Economics', 'Diploma in Business Information Technology', 'diploma', 2, 'Nakuru City', ''),
    ('School of Business and Economics', 'Diploma in Hospitality Management', 'diploma', 2, 'Main', ''),
    ('School of Business and Economics', 'Diploma in Tourism Management', 'diploma', 2, 'Main', ''),
    ('School of Business and Economics', 'Diploma in Human Resource Management', 'diploma', 2, 'Nakuru City', ''),
    ('School of Business and Economics', 'Diploma in Sales and Marketing', 'diploma', 2, 'Nakuru City', ''),
    ('School of Business and Economics', 'Diploma in Banking and Finance', 'diploma', 2, 'Nakuru City', ''),
    ('School of Business and Economics', 'Diploma in Monitoring and Evaluation', 'diploma', 2, 'Nakuru City', ''),
    ('School of Business and Economics', 'Diploma in Project Management', 'diploma', 2, 'Nakuru City', ''),

    -- School of Science, Engineering and Technology
    ('School of Science, Engineering and Technology', 'Doctor of Philosophy in IT', 'phd', 3, 'Nakuru City', ''),
    ('School of Science, Engineering and Technology', 'Doctor of Philosophy in IT Security and Audit', 'phd', 3, 'Nakuru City', ''),
    ('School of Science, Engineering and Technology', 'Master of Science in Information Technology', 'masters', 2, 'Nakuru City', ''),
    ('School of Science, Engineering and Technology', 'Master of Science in Physics', 'masters', 2, 'Main', ''),
    ('School of Science, Engineering and Technology', 'Master of Science in IT Security and Audit', 'masters', 2, 'Nakuru City', ''),
    ('School of Science, Engineering and Technology', 'Master of Science in Environmental Science', 'masters', 2, 'Nakuru City', ''),
    ('School of Science, Engineering and Technology', 'Bachelor of Science in Computer Science', 'undergraduate', 4, 'Main', ''),
    ('School of Science, Engineering and Technology', 'Bachelor of Science in Information Technology', 'undergraduate', 4, 'Main; Nakuru City', ''),
    ('School of Science, Engineering and Technology', 'Bachelor of Science in Telecommunications', 'undergraduate', 4, 'Main', ''),
    ('School of Science, Engineering and Technology', 'Bachelor of Science in Actuarial Science', 'undergraduate', 4, 'Main', ''),
    ('School of Science, Engineering and Technology', 'Bachelor of Science in Computer Security and Forensics', 'undergraduate', 4, 'Main', ''),
    ('School of Science, Engineering and Technology', 'Bachelor of Science', 'undergraduate', 4, 'Main', 'Mathematics; Zoology; Botany; Chemistry; Physics'),
    ('School of Science, Engineering and Technology', 'Bachelor of Science in Environmental Science', 'undergraduate', 4, 'Main', ''),
    ('School of Science, Engineering and Technology', 'Diploma in Computer Science', 'diploma', 2, 'Nakuru City', ''),
    ('School of Science, Engineering and Technology', 'Diploma in Information Technology', 'diploma', 2, 'Nakuru City', ''),
    ('School of Science, Engineering and Technology', 'Certificate in Information Technology', 'certificate', 1, 'Nakuru City', ''),
    ('School of Science, Engineering and Technology', 'Certificate in Environmental Impact Assessment', 'certificate', 1, 'Nakuru City', ''),

    -- School of Education, Humanities and Social Sciences
    ('School of Education, Humanities and Social Sciences', 'Doctor of Philosophy in Education', 'phd', 3, 'All campuses', 'Management and Leadership; Guidance and Counseling; Education Communication Technology; Educational Psychology; Curriculum Studies'),
    ('School of Education, Humanities and Social Sciences', 'Master of Education in Management and Leadership of Education', 'masters', 2, 'All campuses', ''),
    ('School of Education, Humanities and Social Sciences', 'Master of Education in Guidance and Counseling', 'masters', 2, 'All campuses', ''),
    ('School of Education, Humanities and Social Sciences', 'Master of Education in Curriculum Studies', 'masters', 2, 'All campuses', ''),
    ('School of Education, Humanities and Social Sciences', 'Bachelor of Agricultural Education and Extension', 'undergraduate', 4, 'Main', ''),
    ('School of Education, Humanities and Social Sciences', 'Bachelor of Arts in Chaplaincy', 'undergraduate', 4, 'Main; Nakuru City', ''),
    ('School of Education, Humanities and Social Sciences', 'Bachelor of Education (Science)', 'undergraduate', 4, 'Main', 'Mathematics; Biology; Chemistry; Agriculture; Computer; Physics'),
    ('School of Education, Humanities and Social Sciences', 'Bachelor of Education (Arts)', 'undergraduate', 4, 'Main', 'English; Literature; History; Music; Geography; Kiswahili; CRE; Business'),
    ('School of Education, Humanities and Social Sciences', 'Bachelor of Theology', 'undergraduate', 4, 'Main', ''),
    ('School of Education, Humanities and Social Sciences', 'Diploma in Theology', 'diploma', 2, 'Main; Nakuru City', ''),
    ('School of Education, Humanities and Social Sciences', 'Diploma in Chaplaincy', 'diploma', 2, 'Main; Nakuru City', ''),
    ('School of Education, Humanities and Social Sciences', 'Diploma in Education (Science)', 'diploma', 2, 'Main', ''),
    ('School of Education, Humanities and Social Sciences', 'Diploma in Education (Arts)', 'diploma', 2, 'Main', ''),
    ('School of Education, Humanities and Social Sciences', 'Diploma in Education (Early Childhood Development Education)', 'diploma', 2, 'Main', ''),
    ('School of Education, Humanities and Social Sciences', 'Certificate in Education (Early Childhood Education)', 'certificate', 1, 'Main', ''),

    -- School of Law
    ('School of Law', 'Bachelor of Laws (LLB)', 'undergraduate', 4, 'Main', ''),

    -- School of Medicine and Health Sciences
    ('School of Medicine and Health Sciences', 'Master of Medicine in Family Medicine', 'masters', 3, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Master of Science in Human Nutrition and Dietetics', 'masters', 2, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Master of Public Health', 'masters', 2, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Master of Science in Nursing', 'masters', 2, 'Main', 'Midwifery and Reproductive Health Nursing; Oncology and Palliative Care Nursing; Nursing Education; Leadership and Management in Nursing; Critical Care Nursing; Neonatal and Pediatric Health Nursing'),
    ('School of Medicine and Health Sciences', 'Master of Science in Clinical Medicine (Child and Adolescent Health)', 'masters', 2, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Bachelor of Science in Nursing (Direct Entry)', 'undergraduate', 4, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Bachelor of Science in Nursing (In-Service)', 'undergraduate', 3, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Bachelor of Science in Clinical Medicine', 'undergraduate', 5, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Bachelor of Science in Clinical Medicine (In-Service)', 'undergraduate', 4, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Bachelor of Science in Public Health', 'undergraduate', 4, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Bachelor of Science in Human Nutrition and Dietetics', 'undergraduate', 4, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Diploma in Human Nutrition and Dietetics', 'diploma', 2, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Diploma in Environmental Health', 'diploma', 2, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Diploma in Medical Laboratory Sciences', 'diploma', 3, 'Main', ''),
    ('School of Medicine and Health Sciences', 'Diploma in Clinical Medicine and Surgery', 'diploma', 3, 'Main', ''),

    -- School of Music and Media
    ('School of Music and Media', 'Doctor of Philosophy in Music', 'phd', 3, 'Main', 'Music Education; Music Composition; Ethnomusicology; Musicology; Church Music and Music Therapy; Music Production Technology'),
    ('School of Music and Media', 'Master of Music', 'masters', 2, 'Main', 'Music Education; Musicology; Music Composition; Church Music'),
    ('School of Music and Media', 'Bachelor of Music Production Technology', 'undergraduate', 4, 'Main', ''),
    ('School of Music and Media', 'Bachelor of Music Theory and Composition', 'undergraduate', 4, 'Main', ''),
    ('School of Music and Media', 'Bachelor of Mass Communication', 'undergraduate', 4, 'Main', 'Media; Public Relations'),
    ('School of Music and Media', 'Diploma in Mass Communication', 'diploma', 2, 'Main', 'Media; Public Relations'),
    ('School of Music and Media', 'Diploma in Music', 'diploma', 2, 'Main', ''),
    ('School of Music and Media', 'Diploma in Music Production Technology', 'diploma', 2, 'Main', ''),
    ('School of Music and Media', 'Diploma in Theatre Arts', 'diploma', 2, 'Main', ''),
    ('School of Music and Media', 'Diploma in Electronic Media', 'diploma', 2, 'Main', ''),
    ('School of Music and Media', 'Diploma in Film and Theatre', 'diploma', 2, 'Main', ''),
    ('School of Music and Media', 'Certificate in Music', 'certificate', 1, 'Main', ''),
    ('School of Music and Media', 'Certificate in Music Production Technology', 'certificate', 1, 'Main', ''),
    ('School of Music and Media', 'Certificate in Mass Communication', 'certificate', 1, 'Main', ''),
    ('School of Music and Media', 'Certificate in Film and Theatre', 'certificate', 1, 'Main', ''),

    -- School of Pharmacy
    ('School of Pharmacy', 'Bachelor of Pharmacy', 'undergraduate', 5, 'Main', '')
ON CONFLICT (school, name) DO NOTHING;

-- ==================== PART 11/17: friend names (contact_names) ==========
CREATE TABLE IF NOT EXISTS public.contact_names (
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    peer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(name) BETWEEN 1 AND 80),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (author_id, peer_id),
    CHECK (author_id <> peer_id)
);

CREATE INDEX IF NOT EXISTS contact_names_peer_idx
    ON public.contact_names (peer_id);

ALTER TABLE public.contact_names ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.contact_names TO authenticated;

DROP POLICY IF EXISTS "Users view their own contact names" ON public.contact_names;
CREATE POLICY "Users view their own contact names"
    ON public.contact_names FOR SELECT TO authenticated
    USING (author_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users save their own contact names" ON public.contact_names;
CREATE POLICY "Users save their own contact names"
    ON public.contact_names FOR INSERT TO authenticated
    WITH CHECK (
        author_id = (SELECT auth.uid())
        AND author_id <> peer_id
    );

DROP POLICY IF EXISTS "Users update their own contact names" ON public.contact_names;
CREATE POLICY "Users update their own contact names"
    ON public.contact_names FOR UPDATE TO authenticated
    USING (author_id = (SELECT auth.uid()))
    WITH CHECK (author_id = (SELECT auth.uid()) AND author_id <> peer_id);

DROP POLICY IF EXISTS "Users delete their own contact names" ON public.contact_names;
CREATE POLICY "Users delete their own contact names"
    ON public.contact_names FOR DELETE TO authenticated
    USING (author_id = (SELECT auth.uid()));

NOTIFY pgrst, 'reload schema';
-- Campus Connect — message reactions, stars and replies (v36)
-- Safe to paste again (re-runnable). Paste in:
-- https://supabase.com/dashboard/project/jvqnwkekbpaynpppjeyf/sql/new
-- The app works without this file too, but then reactions and stars are only
-- visible on your own phone. After pasting, both sides see them.
BEGIN;

-- 1. Emoji reactions on a chat message (visible to both participants).
CREATE TABLE IF NOT EXISTS public.message_reactions (
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    emoji TEXT NOT NULL CHECK (char_length(emoji) BETWEEN 1 AND 8),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (message_id, user_id)
);

CREATE INDEX IF NOT EXISTS message_reactions_message_idx
    ON public.message_reactions (message_id);

ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, DELETE ON public.message_reactions TO authenticated;

DROP POLICY IF EXISTS "Participants view message reactions" ON public.message_reactions;
CREATE POLICY "Participants view message reactions"
    ON public.message_reactions FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.messages AS m
            WHERE m.id = message_reactions.message_id
              AND (m.sender_id = (SELECT auth.uid()) OR m.receiver_id = (SELECT auth.uid()))
        )
    );

DROP POLICY IF EXISTS "Users add their own message reaction" ON public.message_reactions;
CREATE POLICY "Users add their own message reaction"
    ON public.message_reactions FOR INSERT TO authenticated
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.messages AS m
            WHERE m.id = message_reactions.message_id
              AND (m.sender_id = (SELECT auth.uid()) OR m.receiver_id = (SELECT auth.uid()))
        )
    );

DROP POLICY IF EXISTS "Users remove their own message reaction" ON public.message_reactions;
CREATE POLICY "Users remove their own message reaction"
    ON public.message_reactions FOR DELETE TO authenticated
    USING (user_id = (SELECT auth.uid()));

-- 2. Starred messages (a private bookmark: only the owner sees them).
CREATE TABLE IF NOT EXISTS public.message_stars (
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (message_id, user_id)
);

CREATE INDEX IF NOT EXISTS message_stars_user_idx
    ON public.message_stars (user_id, created_at DESC);

ALTER TABLE public.message_stars ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, DELETE ON public.message_stars TO authenticated;

DROP POLICY IF EXISTS "Users view their own starred messages" ON public.message_stars;
CREATE POLICY "Users view their own starred messages"
    ON public.message_stars FOR SELECT TO authenticated
    USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users star their own messages" ON public.message_stars;
CREATE POLICY "Users star their own messages"
    ON public.message_stars FOR INSERT TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users unstar their own messages" ON public.message_stars;
CREATE POLICY "Users unstar their own messages"
    ON public.message_stars FOR DELETE TO authenticated
    USING (user_id = (SELECT auth.uid()));

-- 3. Reply-to: a small snapshot of the quoted message so the quote box still
--    renders even if the original message is later deleted.
ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS reply_to UUID REFERENCES public.messages(id) ON DELETE SET NULL;

ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS reply_preview JSONB;

DO $do$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'messages_reply_preview_size_check'
          AND conrelid = 'public.messages'::REGCLASS
    ) THEN
        ALTER TABLE public.messages DROP CONSTRAINT messages_reply_preview_size_check;
    END IF;
END
$do$;

ALTER TABLE public.messages
    ADD CONSTRAINT messages_reply_preview_size_check
    CHECK (reply_preview IS NULL OR octet_length(reply_preview::TEXT) <= 4096);

COMMIT;

-- ============ PART 12/17: migrations/20261016_lecturer_credentials.sql ============
-- ============================================================
-- CAMPUS CONNECT — LECTURER CREDENTIALS, STUDY MODE, STAFF LOG
-- Kabarak University rules this adds:
--   * a lecturer must prove themselves with a National ID number, a
--     staff ID card number, and the registration number written on
--     their letter of introduction — plus a photo of each
--   * until an admin approves those documents the account cannot post,
--     chat, comment or call: the university system stays shut
--   * a staff ID card number may only ever belong to one person, so a
--     lecturer who left and comes back must be issued a NEW card
--   * students are tagged normal, retake, or online
--   * a lecturer who is no longer at the university goes passive and
--     drops out of the active staff, but the record is kept
-- Idempotent: safe to run more than once.
-- ============================================================


-- ------------------------------------------------------------
-- 1. NEW COLUMNS ON PROFILES
-- staff_id_number and employment_status are university facts, so only
-- an admin (or a migration) may write them — see section 5.
-- ------------------------------------------------------------

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS staff_id_number TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS employment_status TEXT NOT NULL DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS study_mode TEXT NOT NULL DEFAULT 'normal',
    ADD COLUMN IF NOT EXISTS lecturer_since TIMESTAMPTZ;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'profiles_staff_id_number_length_check'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_staff_id_number_length_check
            CHECK (char_length(staff_id_number) <= 32);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'profiles_employment_status_check'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_employment_status_check
            CHECK (employment_status IN ('active', 'passive'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'profiles_study_mode_check'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_study_mode_check
            CHECK (study_mode IN ('normal', 'retake', 'online'));
    END IF;
END;
$$;

-- One card, one person — for good. A passive lecturer keeps their number
-- here, which is exactly what stops it being handed out again.
CREATE UNIQUE INDEX IF NOT EXISTS profiles_staff_id_key
    ON public.profiles (staff_id_number)
    WHERE staff_id_number <> '';

CREATE INDEX IF NOT EXISTS profiles_staff_room_idx
    ON public.profiles (role, employment_status, lecturer_since DESC);


-- ------------------------------------------------------------
-- 1b. ONE SHAPE FOR EVERY NUMBER
-- "abc-1", "ABC-1" and "ABC 1" are the same card. Normalising before a
-- unique index ever looks at a value is what stops a second person
-- claiming a number that only differs in case or spacing.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.normalize_id_number(p_value TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
    SELECT UPPER(REGEXP_REPLACE(BTRIM(COALESCE(p_value, '')), ' +', ' ', 'g'))
$$;

REVOKE ALL ON FUNCTION public.normalize_id_number(TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.normalize_id_number(TEXT) TO authenticated;


-- ------------------------------------------------------------
-- 2. THE DOCUMENT BAG
-- One row per claim, with the three numbers and the three files. It is
-- never edited in place: an admin approves or rejects it, and a person
-- who was rejected simply submits another one.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.lecturer_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    national_id_number TEXT NOT NULL,
    staff_id_number TEXT NOT NULL,
    introduction_letter_number TEXT NOT NULL,
    national_id_path TEXT NOT NULL,
    staff_id_path TEXT NOT NULL,
    introduction_letter_path TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    review_note TEXT NOT NULL DEFAULT '',
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT lecturer_submissions_national_id_check
        CHECK (national_id_number ~ '^[0-9]{5,12}$'),
    CONSTRAINT lecturer_submissions_staff_id_check
        CHECK (staff_id_number ~ '^[A-Za-z0-9][-./ A-Za-z0-9]{2,31}$'),
    CONSTRAINT lecturer_submissions_letter_check
        CHECK (introduction_letter_number ~ '^[A-Za-z0-9][-./ A-Za-z0-9]{2,47}$'),
    CONSTRAINT lecturer_submissions_status_check
        CHECK (status IN ('pending', 'approved', 'rejected')),
    CONSTRAINT lecturer_submissions_files_check
        CHECK (national_id_path <> '' AND staff_id_path <> ''
               AND introduction_letter_path <> ''),
    CONSTRAINT lecturer_submissions_note_length_check
        CHECK (char_length(review_note) <= 300)
);

CREATE INDEX IF NOT EXISTS lecturer_submissions_status_idx
    ON public.lecturer_submissions (status, created_at DESC);
CREATE INDEX IF NOT EXISTS lecturer_submissions_user_idx
    ON public.lecturer_submissions (user_id, created_at DESC);

-- Two people cannot queue the same card at once, and an approved claim
-- keeps the number reserved for as long as the record exists.
CREATE UNIQUE INDEX IF NOT EXISTS lecturer_submissions_staff_id_key
    ON public.lecturer_submissions (staff_id_number)
    WHERE status IN ('pending', 'approved');

-- One live request per person, so the admin queue cannot fill with copies.
CREATE UNIQUE INDEX IF NOT EXISTS lecturer_submissions_one_pending_key
    ON public.lecturer_submissions (user_id)
    WHERE status = 'pending';

ALTER TABLE public.lecturer_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members view their own lecturer submissions" ON public.lecturer_submissions;
CREATE POLICY "Members view their own lecturer submissions"
    ON public.lecturer_submissions FOR SELECT TO authenticated
    USING (user_id = (SELECT auth.uid()) OR public.is_admin());

-- Every new claim goes through submit_lecturer_credentials(), which owns
-- the format and duplicate checks. This policy only says nobody may file
-- a claim on behalf of someone else.
DROP POLICY IF EXISTS "Members file their own lecturer submissions" ON public.lecturer_submissions;
CREATE POLICY "Members file their own lecturer submissions"
    ON public.lecturer_submissions FOR INSERT TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Admins update lecturer submissions" ON public.lecturer_submissions;
CREATE POLICY "Admins update lecturer submissions"
    ON public.lecturer_submissions FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());


-- ------------------------------------------------------------
-- 3. THE PROOF FILES LIVE IN THE PRIVATE BUCKET
-- Same bucket as private chat media, but in a fixed subfolder, and an
-- admin can only open a file that a claim actually points at. Nobody
-- else can reach a document — not even a mutual connection.
-- ------------------------------------------------------------

UPDATE storage.buckets
    SET allowed_mime_types = ARRAY[
        'image/*',
        'video/*',
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]
    WHERE id = 'campus-private-media';

DROP POLICY IF EXISTS "Admins view lecturer proof files" ON storage.objects;
CREATE POLICY "Admins view lecturer proof files"
    ON storage.objects FOR SELECT TO authenticated
    USING (
        bucket_id = 'campus-private-media'
        AND public.is_admin()
        AND EXISTS (
            SELECT 1
            FROM public.lecturer_submissions AS s
            WHERE 'private-media:' || storage.objects.name IN (
                s.national_id_path, s.staff_id_path, s.introduction_letter_path
            )
        )
    );


-- ------------------------------------------------------------
-- 4. IS THIS ACCOUNT LOCKED OUT?
-- One place decides it, so the gate cannot drift from the trigger.
-- Only the member themselves, or an admin, may ask.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.account_blocked(p_user UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT COALESCE(
        (
            SELECT p.verification_status = 'rejected'
                OR (p.requested_role = 'lecturer' AND p.verification_status = 'pending')
                OR (
                    p.role = 'lecturer'
                    AND (
                        p.employment_status = 'passive'
                        OR p.staff_id_number = ''
                        OR p.verification_status <> 'approved'
                    )
                )
            FROM public.profiles AS p
            WHERE p.id = p_user
        ),
        FALSE
    )
    AND COALESCE(p_user = auth.uid() OR public.is_admin(), FALSE);
$$;

-- RLS can compare a row to auth.uid(), but it cannot look at what the
-- profile says about the person, so a trigger does. It checks the writer,
-- never the row owner: a student receiving a message from a lecturer who
-- has just been locked out must still be able to read and mark it.
CREATE OR REPLACE FUNCTION public.refuse_blocked_member_writes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    -- The SQL Editor, the service key and migrations run without a
    -- signed-in user. The app never does.
    IF auth.uid() IS NULL THEN
        RETURN NEW;
    END IF;

    IF public.account_blocked(auth.uid()) THEN
        RAISE EXCEPTION 'University access is not open for this account yet. A lecturer must verify a National ID, a staff ID card and the letter of introduction with an admin.'
            USING ERRCODE = '42501';
    END IF;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.refuse_blocked_member_writes() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS refuse_blocked_writes ON public.posts;
CREATE TRIGGER refuse_blocked_writes
    BEFORE INSERT OR UPDATE ON public.posts
    FOR EACH ROW EXECUTE FUNCTION public.refuse_blocked_member_writes();

DROP TRIGGER IF EXISTS refuse_blocked_writes ON public.comments;
CREATE TRIGGER refuse_blocked_writes
    BEFORE INSERT OR UPDATE ON public.comments
    FOR EACH ROW EXECUTE FUNCTION public.refuse_blocked_member_writes();

DROP TRIGGER IF EXISTS refuse_blocked_writes ON public.stories;
CREATE TRIGGER refuse_blocked_writes
    BEFORE INSERT OR UPDATE ON public.stories
    FOR EACH ROW EXECUTE FUNCTION public.refuse_blocked_member_writes();

DROP TRIGGER IF EXISTS refuse_blocked_writes ON public.messages;
CREATE TRIGGER refuse_blocked_writes
    BEFORE INSERT OR UPDATE ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.refuse_blocked_member_writes();

DROP TRIGGER IF EXISTS refuse_blocked_writes ON public.community_messages;
CREATE TRIGGER refuse_blocked_writes
    BEFORE INSERT OR UPDATE ON public.community_messages
    FOR EACH ROW EXECUTE FUNCTION public.refuse_blocked_member_writes();

DROP TRIGGER IF EXISTS refuse_blocked_writes ON public.friend_requests;
CREATE TRIGGER refuse_blocked_writes
    BEFORE INSERT OR UPDATE ON public.friend_requests
    FOR EACH ROW EXECUTE FUNCTION public.refuse_blocked_member_writes();

DROP TRIGGER IF EXISTS refuse_blocked_writes ON public.call_signals;
CREATE TRIGGER refuse_blocked_writes
    BEFORE INSERT ON public.call_signals
    FOR EACH ROW EXECUTE FUNCTION public.refuse_blocked_member_writes();


-- ------------------------------------------------------------
-- 5. A MEMBER CANNOT WRITE THEIR OWN STAFF RECORD
-- study_mode is theirs to choose; the university facts are not.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.enforce_profile_staff_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF auth.uid() IS NULL OR public.is_admin() THEN
        RETURN NEW;
    END IF;

    IF NEW.staff_id_number IS DISTINCT FROM OLD.staff_id_number
       OR NEW.employment_status IS DISTINCT FROM OLD.employment_status
       OR NEW.lecturer_since IS DISTINCT FROM OLD.lecturer_since THEN
        RAISE EXCEPTION 'Only an admin can set a staff ID number or an employment status.'
            USING ERRCODE = '42501';
    END IF;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_profile_staff_fields() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS profiles_enforce_staff_fields ON public.profiles;
CREATE TRIGGER profiles_enforce_staff_fields
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.enforce_profile_staff_fields();


-- ------------------------------------------------------------
-- 6. SUBMIT THE PROOF
-- Called by the person asking to be a lecturer. It checks the numbers,
-- insists the files are their own, and refuses a card that is already on
-- record — that is the rule that forces a returning lecturer to bring a
-- new staff ID card.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.submit_lecturer_credentials(
    p_national_id_number TEXT,
    p_staff_id_number TEXT,
    p_introduction_letter_number TEXT,
    p_national_id_path TEXT,
    p_staff_id_path TEXT,
    p_introduction_letter_path TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    actor UUID := auth.uid();
    own_folder TEXT;
    submission_id UUID;
BEGIN
    IF actor IS NULL THEN
        RAISE EXCEPTION 'Sign in first.' USING ERRCODE = '42501';
    END IF;

    own_folder := 'private-media:' || actor::TEXT || '/lecturer-credentials/';
    p_national_id_number := public.normalize_id_number(p_national_id_number);
    p_staff_id_number := public.normalize_id_number(p_staff_id_number);
    p_introduction_letter_number := public.normalize_id_number(p_introduction_letter_number);

    IF p_national_id_number !~ '^[0-9]{5,12}$' THEN
        RAISE EXCEPTION 'A National ID number is 5 to 12 digits.'
            USING ERRCODE = '22023';
    END IF;
    IF p_staff_id_number !~ '^[A-Za-z0-9][-./ A-Za-z0-9]{2,31}$' THEN
        RAISE EXCEPTION 'A staff ID card number is 3 to 32 letters or digits.'
            USING ERRCODE = '22023';
    END IF;
    IF p_introduction_letter_number !~ '^[A-Za-z0-9][-./ A-Za-z0-9]{2,47}$' THEN
        RAISE EXCEPTION 'The registration number on the letter of introduction is 3 to 48 characters.'
            USING ERRCODE = '22023';
    END IF;

    IF LEFT(p_national_id_path, LENGTH(own_folder)) <> own_folder
       OR LEFT(p_staff_id_path, LENGTH(own_folder)) <> own_folder
       OR LEFT(p_introduction_letter_path, LENGTH(own_folder)) <> own_folder THEN
        RAISE EXCEPTION 'Take a photo of each document first.'
            USING ERRCODE = '22023';
    END IF;

    -- The card may belong to nobody but this person. Their own profile row
    -- already holds the number they gave at sign-up, so it is not a clash.
    IF EXISTS (
        SELECT 1 FROM public.profiles AS p
        WHERE p.staff_id_number = p_staff_id_number
          AND p.id <> actor
    ) OR EXISTS (
        SELECT 1 FROM public.lecturer_submissions AS s
        WHERE public.normalize_id_number(s.staff_id_number) = p_staff_id_number
          AND s.status IN ('pending', 'approved')
          AND s.user_id <> actor
    ) THEN
        RAISE EXCEPTION 'That staff ID card is already on the university record. A lecturer coming back is given a new card.'
            USING ERRCODE = '23505';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.profiles AS p
        WHERE p.id = actor
          AND p.role = 'lecturer'
          AND p.employment_status = 'active'
          AND p.staff_id_number <> ''
    ) THEN
        RAISE EXCEPTION 'Your staff record is already verified.'
            USING ERRCODE = '22023';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.lecturer_submissions AS s
        WHERE s.user_id = actor AND s.status = 'pending'
    ) THEN
        RAISE EXCEPTION 'An admin is already looking at your documents.'
            USING ERRCODE = '22023';
    END IF;

    INSERT INTO public.lecturer_submissions (
        user_id, national_id_number, staff_id_number,
        introduction_letter_number, national_id_path,
        staff_id_path, introduction_letter_path
    )
    VALUES (
        actor, p_national_id_number, p_staff_id_number,
        p_introduction_letter_number, p_national_id_path,
        p_staff_id_path, p_introduction_letter_path
    )
    RETURNING id INTO submission_id;

    RETURN submission_id;
END;
$$;


-- ------------------------------------------------------------
-- 7. THE ADMIN DECIDES
-- Approving is the only way to become a lecturer, and the only way a
-- passive lecturer comes back: through a fresh card.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.review_lecturer_submission(
    p_submission_id UUID,
    p_approve BOOLEAN,
    p_note TEXT DEFAULT ''
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    claim public.lecturer_submissions%ROWTYPE;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only an admin can review a staff record.'
            USING ERRCODE = '42501';
    END IF;

    SELECT * INTO claim
        FROM public.lecturer_submissions
        WHERE id = p_submission_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No such request.' USING ERRCODE = 'P0002';
    END IF;

    IF claim.status <> 'pending' THEN
        RAISE EXCEPTION 'That request was already reviewed.'
            USING ERRCODE = '22023';
    END IF;

    UPDATE public.lecturer_submissions
        SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
            review_note = LEFT(trim(coalesce(p_note, '')), 300),
            reviewed_by = auth.uid(),
            reviewed_at = NOW(),
            updated_at = NOW()
        WHERE id = claim.id;

    IF p_approve THEN
        IF EXISTS (
            SELECT 1 FROM public.profiles AS p
            WHERE p.staff_id_number = claim.staff_id_number
              AND p.id <> claim.user_id
        ) THEN
            RAISE EXCEPTION 'Another lecturer already uses that staff ID card.'
                USING ERRCODE = '23505';
        END IF;

        UPDATE public.profiles
            SET role = 'lecturer',
                verification_status = 'approved',
                requested_role = '',
                staff_id_number = claim.staff_id_number,
                employment_status = 'active',
                lecturer_since = COALESCE(lecturer_since, NOW())
            WHERE id = claim.user_id;

        INSERT INTO public.admin_action_log (actor_id, target_user_id, action, detail)
            VALUES (auth.uid(), claim.user_id, 'lecturer_approve', claim.staff_id_number);
    ELSE
        -- A lecturer who left stays passive: they are already locked out,
        -- and rejecting a new card must not erase that.
        UPDATE public.profiles
            SET verification_status = 'rejected'
            WHERE id = claim.user_id
              AND employment_status = 'active';

        INSERT INTO public.admin_action_log (actor_id, target_user_id, action, detail)
            VALUES (auth.uid(), claim.user_id, 'lecturer_reject', claim.staff_id_number);
    END IF;
END;
$$;

-- Retiring keeps the row and the card number. It only takes the person
-- out of the active staff, which is what hides them from the lecturer
-- lists the students see.
CREATE OR REPLACE FUNCTION public.archive_lecturer(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only an admin can retire a lecturer.'
            USING ERRCODE = '42501';
    END IF;

    UPDATE public.profiles
        SET employment_status = 'passive'
        WHERE id = p_user_id AND role = 'lecturer' AND employment_status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No active lecturer with that account.'
            USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO public.admin_action_log (actor_id, target_user_id, action, detail)
        VALUES (auth.uid(), p_user_id, 'archive_lecturer', '');
END;
$$;

-- Students pick their own study mode; an admin can overrule it from the
-- member screen.
CREATE OR REPLACE FUNCTION public.set_member_study_mode(p_user_id UUID, p_mode TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only an admin can change a study mode.'
            USING ERRCODE = '42501';
    END IF;

    IF p_mode NOT IN ('normal', 'retake', 'online') THEN
        RAISE EXCEPTION 'Unknown study mode.' USING ERRCODE = '22023';
    END IF;

    UPDATE public.profiles SET study_mode = p_mode WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No such member.' USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO public.admin_action_log (actor_id, target_user_id, action, detail)
        VALUES (auth.uid(), p_user_id, 'study_mode', p_mode);
END;
$$;

-- The action log has to know about the new decisions.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'admin_action_log_action_check'
          AND conrelid = 'public.admin_action_log'::regclass
    ) THEN
        ALTER TABLE public.admin_action_log
            DROP CONSTRAINT admin_action_log_action_check;
    END IF;
END;
$$;

ALTER TABLE public.admin_action_log
    ADD CONSTRAINT admin_action_log_action_check
    CHECK (action IN ('approve', 'reject', 'set_role', 'reset_role_request',
                      'lecturer_approve', 'lecturer_reject', 'archive_lecturer',
                      'study_mode'));


-- ------------------------------------------------------------
-- 8. WHO MAY CALL WHAT
-- ------------------------------------------------------------

REVOKE ALL ON FUNCTION public.account_blocked(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.submit_lecturer_credentials(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.review_lecturer_submission(UUID, BOOLEAN, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.archive_lecturer(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.set_member_study_mode(UUID, TEXT) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.account_blocked(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_lecturer_credentials(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_lecturer_submission(UUID, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.archive_lecturer(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_member_study_mode(UUID, TEXT) TO authenticated;

GRANT SELECT, INSERT, UPDATE ON public.lecturer_submissions TO authenticated;


-- ------------------------------------------------------------
-- 9. RELOAD THE API SCHEMA CACHE
-- ------------------------------------------------------------

NOTIFY pgrst, 'reload schema';

-- ============ PART 13/17: migrations/20261016_one_number_one_account.sql ============

-- ============================================================
-- CAMPUS CONNECT — ONE NUMBER, ONE ACCOUNT
-- Kabarak University rules this adds:
--   * the number is claimed while the account is created, inside the same
--     database transaction, so a second account cannot get past a number
--     the system already knows — even when both people share a name
--   * a student registers with their registration number, a lecturer or
--     security member with their staff ID card number
--   * "abc-1" and "ABC  1" are the same number: everything is normalised
--     before a unique index ever sees it
--   * someone who is none of those can still use the app as a plain
--     member, but a member has no university record, so units, class
--     plans and the lecturer lists stay closed
--   * re-running the whole setup no longer demotes lecturers and admins
-- Idempotent: safe to run more than once.
-- ============================================================


-- ------------------------------------------------------------
-- 1. ONE IDENTITY MORE: A PLAIN MEMBER
-- Someone who is not a student, a lecturer or security can still use the
-- app. (The old "reset every profile to student" statement in the roles
-- migration has been dropped from this setup, because running the setup
-- twice quietly demoted admins and lecturers.)
-- ------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'profiles_role_check'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles DROP CONSTRAINT profiles_role_check;
    END IF;
    ALTER TABLE public.profiles
        ADD CONSTRAINT profiles_role_check
        CHECK (role IN ('student', 'lecturer', 'security', 'admin', 'member'));
END;
$$;


-- ------------------------------------------------------------
-- 2. EVERY NUMBER IS WRITTEN THE SAME WAY
-- Without this, "ku-01" and "KU-01" are two different people holding one
-- card. The triggers sit before the checks and the unique indexes, so no
-- caller can slip an unnormalised value in.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.normalize_member_numbers()
RETURNS TRIGGER
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
BEGIN
    NEW.staff_id_number := public.normalize_id_number(NEW.staff_id_number);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_normalize_staff_id ON public.profiles;
CREATE TRIGGER profiles_normalize_staff_id
    BEFORE INSERT OR UPDATE
    ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.normalize_member_numbers();

CREATE OR REPLACE FUNCTION public.normalize_submission_numbers()
RETURNS TRIGGER
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
BEGIN
    NEW.national_id_number := public.normalize_id_number(NEW.national_id_number);
    NEW.staff_id_number := public.normalize_id_number(NEW.staff_id_number);
    NEW.introduction_letter_number := public.normalize_id_number(NEW.introduction_letter_number);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS lecturer_submissions_normalize_numbers ON public.lecturer_submissions;
CREATE TRIGGER lecturer_submissions_normalize_numbers
    BEFORE INSERT OR UPDATE
    ON public.lecturer_submissions
    FOR EACH ROW
    EXECUTE FUNCTION public.normalize_submission_numbers();

CREATE OR REPLACE FUNCTION public.normalize_registration_number()
RETURNS TRIGGER
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
BEGIN
    NEW.registration_number := public.normalize_id_number(NEW.registration_number);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS student_registrations_normalize_number ON public.student_registrations;
CREATE TRIGGER student_registrations_normalize_number
    BEFORE INSERT OR UPDATE
    ON public.student_registrations
    FOR EACH ROW
    EXECUTE FUNCTION public.normalize_registration_number();


-- ------------------------------------------------------------
-- 3. THE NUMBER IS CLAIMED WHILE THE ACCOUNT IS BORN
-- This trigger already creates the profile row. It now also takes the
-- number from the sign-up data. A clash aborts the insert, so the
-- account is never created — which is what "the system refuses" means.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    username_base TEXT;
    candidate_username TEXT;
    attempt INTEGER;
    metadata JSONB;
    account_kind TEXT;
    claimed_number TEXT;
    claimed_card TEXT;
    clash_name TEXT;
BEGIN
    metadata := COALESCE(NEW.raw_user_meta_data, '{}'::JSONB);
    account_kind := LOWER(BTRIM(COALESCE(metadata->>'account_kind', '')));
    claimed_number := public.normalize_id_number(metadata->>'registration_number');
    claimed_card := public.normalize_id_number(metadata->>'staff_id_number');

    -- Whatever an older app version sends, the number is only ever
    -- claimed once, and a member never has one.
    IF account_kind = 'member' THEN
        claimed_number := '';
        claimed_card := '';
    END IF;

    username_base := LOWER(
        REGEXP_REPLACE(
            COALESCE(
                metadata->>'username',
                SPLIT_PART(COALESCE(NEW.email, NEW.phone, 'student'), '@', 1)
            ),
            '[^a-zA-Z0-9_]',
            '',
            'g'
        )
    );
    username_base := LEFT(username_base, 20);
    IF char_length(username_base) < 3 THEN
        username_base := 'student';
    END IF;

    FOR attempt IN 0..5 LOOP
        candidate_username := CASE
            WHEN attempt = 0 THEN username_base
            ELSE LEFT(username_base, 19) || '_' || LEFT(NEW.id::TEXT, 8) ||
                 CASE WHEN attempt > 1 THEN '_' || (attempt - 1)::TEXT ELSE '' END
        END;

        BEGIN
            INSERT INTO public.profiles (
                id,
                username,
                full_name,
                course,
                role,
                staff_id_number
            )
            VALUES (
                NEW.id,
                candidate_username,
                LEFT(COALESCE(metadata->>'full_name', 'Member'), 100),
                LEFT(COALESCE(metadata->>'course', ''), 120),
                CASE WHEN account_kind = 'member' THEN 'member' ELSE 'student' END,
                CASE WHEN account_kind IN ('lecturer', 'security') THEN claimed_card ELSE '' END
            )
            ON CONFLICT (id) DO NOTHING;
            EXIT;
        EXCEPTION WHEN unique_violation THEN
            GET STACKED DIAGNOSTICS clash_name = CONSTRAINT_NAME;
            IF clash_name = 'profiles_staff_id_key' THEN
                RAISE EXCEPTION 'That staff ID card already belongs to another account. Nobody can register twice with one card.'
                    USING ERRCODE = '23505';
            END IF;
            IF attempt = 5 THEN
                RAISE;
            END IF;
        END;
    END LOOP;

    IF account_kind = 'student' OR account_kind = '' THEN
        IF claimed_number <> '' THEN
            BEGIN
                INSERT INTO public.student_registrations (user_id, registration_number)
                VALUES (NEW.id, claimed_number);
            EXCEPTION WHEN unique_violation THEN
                RAISE EXCEPTION 'That registration number is already known to the university system. Check it, or ask an admin. Even two people with the same name cannot share one number.'
                    USING ERRCODE = '23505';
            END;
        END IF;
    END IF;

    IF account_kind = 'lecturer' AND claimed_card = '' THEN
        RAISE EXCEPTION 'A lecturer registers with the number on their staff ID card.'
            USING ERRCODE = '22023';
    END IF;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.normalize_member_numbers() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.normalize_submission_numbers() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.normalize_registration_number() FROM PUBLIC, anon, authenticated;

-- Sign-up happens before anyone is authenticated, so only the service
-- role path (the trigger itself) may run it; nothing new is granted.


-- ------------------------------------------------------------
-- 4. WHO MAY OPEN UNITS, CLASS PLANS AND LECTURER LISTS
-- A member has no university record. A student who has never given a
-- number is still new to this rule, so the Classes screen asks them for
-- it instead of failing with a permission error.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.may_use_classes()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT COALESCE((
        SELECT p.role = 'admin'
            OR (p.role = 'security' AND p.employment_status = 'active')
            OR (p.role = 'lecturer' AND p.employment_status = 'active')
            OR (p.role = 'student' AND EXISTS (
                    SELECT 1 FROM public.student_registrations AS r
                    WHERE r.user_id = p.id
                ))
        FROM public.profiles AS p
        WHERE p.id = auth.uid()
    ), FALSE);
$$;

REVOKE ALL ON FUNCTION public.may_use_classes() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.may_use_classes() TO authenticated;

DROP POLICY IF EXISTS "Members view units" ON public.units;
CREATE POLICY "Members view units"
    ON public.units FOR SELECT TO authenticated
    USING (public.may_use_classes());

DROP POLICY IF EXISTS "Members view class sessions" ON public.class_sessions;
CREATE POLICY "Members view class sessions"
    ON public.class_sessions FOR SELECT TO authenticated
    USING (public.may_use_classes());


-- ------------------------------------------------------------
-- 5. AN ADMIN CAN MOVE A NUMBER WHEN IT IS PROVEN WRONG
-- The unique claim stays; only an admin may break it, and every move is
-- written to the action log.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_member_registration_number(
    p_user_id UUID,
    p_number TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    number TEXT := public.normalize_id_number(p_number);
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only an admin can move a registration number.'
            USING ERRCODE = '42501';
    END IF;

    IF number !~ '^[A-Za-z0-9][-./ A-Za-z0-9]{2,31}$' THEN
        RAISE EXCEPTION 'A registration number is 3 to 32 letters or digits.'
            USING ERRCODE = '22023';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'No such member.' USING ERRCODE = 'P0002';
    END IF;

    BEGIN
        INSERT INTO public.student_registrations (user_id, registration_number)
        VALUES (p_user_id, number)
        ON CONFLICT (user_id) DO UPDATE
            SET registration_number = EXCLUDED.registration_number,
                updated_at = NOW();
    EXCEPTION WHEN unique_violation THEN
        RAISE EXCEPTION 'That registration number already belongs to another account.'
            USING ERRCODE = '23505';
    END;

    INSERT INTO public.admin_action_log (actor_id, target_user_id, action, detail)
        VALUES (auth.uid(), p_user_id, 'registration_number', number);
END;
$$;

REVOKE ALL ON FUNCTION public.set_member_registration_number(UUID, TEXT)
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_member_registration_number(UUID, TEXT) TO authenticated;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'admin_action_log_action_check'
          AND conrelid = 'public.admin_action_log'::regclass
    ) THEN
        ALTER TABLE public.admin_action_log
            DROP CONSTRAINT admin_action_log_action_check;
    END IF;
END;
$$;

ALTER TABLE public.admin_action_log
    ADD CONSTRAINT admin_action_log_action_check
    CHECK (action IN ('approve', 'reject', 'set_role', 'reset_role_request',
                      'lecturer_approve', 'lecturer_reject', 'archive_lecturer',
                      'study_mode', 'registration_number'));


-- ------------------------------------------------------------
-- 6. TELL POSTGREST THE SHAPE CHANGED
-- ------------------------------------------------------------

NOTIFY pgrst, 'reload schema';


-- ============ PART 14/17: migrations/20261017_bulletins.sql ============

-- ============================================================
-- CAMPUS CONNECT — THE BULLETIN BOARD
-- An account that is not a student (a parent, a guardian, a relative
-- abroad, a well-wisher) gets information instead of a campus: news
-- written from inside the app about the world, the university and
-- the people in it.
--   * every signed-in account can read the board
--   * only a campus account may write, and only under its own author_id.
--     may_use_classes() is exactly that test: an admin, an active
--     lecturer or security member, or a student whose registration
--     number is on file
--   * an author can correct or remove its own item; anyone can report it
--     by simply telling an admin
--   * a section is 'world', 'university' or 'people'
-- Idempotent: safe to run more than once.
-- ============================================================


-- ------------------------------------------------------------
-- 1. THE BOARD
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.bulletins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    section TEXT NOT NULL DEFAULT 'university'
        CHECK (section IN ('world', 'university', 'people')),
    title TEXT NOT NULL CHECK (char_length(BTRIM(title)) BETWEEN 3 AND 120),
    body TEXT NOT NULL CHECK (char_length(BTRIM(body)) BETWEEN 1 AND 4000),
    link_url TEXT CHECK (link_url IS NULL OR link_url ~ '^https?://'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS bulletins_section_created_idx
    ON public.bulletins (section, created_at DESC);


-- ------------------------------------------------------------
-- 2. KEEP updated_at HONEST
-- ------------------------------------------------------------

DROP TRIGGER IF EXISTS bulletins_set_updated_at ON public.bulletins;
CREATE TRIGGER bulletins_set_updated_at
    BEFORE UPDATE ON public.bulletins
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();


-- ------------------------------------------------------------
-- 3. WHO MAY SEE AND WRITE
-- ------------------------------------------------------------

ALTER TABLE public.bulletins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS bulletins_readable ON public.bulletins;
CREATE POLICY bulletins_readable ON public.bulletins
    FOR SELECT TO authenticated
    USING (TRUE);

DROP POLICY IF EXISTS bulletins_campus_write ON public.bulletins;
CREATE POLICY bulletins_campus_write ON public.bulletins
    FOR INSERT TO authenticated
    WITH CHECK (author_id = auth.uid() AND public.may_use_classes());

DROP POLICY IF EXISTS bulletins_author_edit ON public.bulletins;
CREATE POLICY bulletins_author_edit ON public.bulletins
    FOR UPDATE TO authenticated
    USING (author_id = auth.uid())
    WITH CHECK (author_id = auth.uid());

DROP POLICY IF EXISTS bulletins_author_remove ON public.bulletins;
CREATE POLICY bulletins_author_remove ON public.bulletins
    FOR DELETE TO authenticated
    USING (author_id = auth.uid() OR public.is_admin());


-- ------------------------------------------------------------
-- 4. TELL POSTGREST THE SHAPE CHANGED
-- ------------------------------------------------------------

GRANT SELECT, INSERT, UPDATE, DELETE ON public.bulletins TO authenticated;

NOTIFY pgrst, 'reload schema';


-- ============ PART 15/17: migrations/20261017_companies.sql ============

-- ============================================================
-- CAMPUS CONNECT — THE COMPANY DIRECTORY
-- A university is not the only place a person belongs. A director,
-- a manager or an employee of any company in the world registers with
-- the company's name, and the app then leads their feed with the people
-- they work with, exactly the way a campus zone leads a student with
-- their own school.
--   * the directory is world-wide: name, country, city, industry, website
--   * every signed-in account may read it and search it
--   * any signed-in account may ADD a company that is missing, and the row
--     remembers who added it
--   * only an admin may correct or remove a company, so one person's
--     typing cannot rename everybody's employer
--   * a member claims a company by writing its name on their own profile
--     (profiles.company). The name is kept as text, not as a foreign key,
--     for the same reason profiles.university is: a person must be able to
--     say where they belong before the directory happens to hold them.
--   * an account that carries a company may also write announcements, so a
--     company board is not locked behind a campus
-- Idempotent: safe to run more than once.
-- ============================================================


-- ------------------------------------------------------------
-- 1. THE DIRECTORY
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL CHECK (char_length(BTRIM(name)) BETWEEN 2 AND 120),
    name_key TEXT GENERATED ALWAYS AS (LOWER(BTRIM(name))) STORED,
    country TEXT CHECK (country IS NULL OR char_length(BTRIM(country)) <= 80),
    city TEXT CHECK (city IS NULL OR char_length(BTRIM(city)) <= 80),
    industry TEXT CHECK (industry IS NULL OR char_length(BTRIM(industry)) <= 80),
    website TEXT CHECK (website IS NULL OR website ~ '^https?://'),
    note TEXT CHECK (note IS NULL OR char_length(BTRIM(note)) <= 400),
    added_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT companies_name_key_unique UNIQUE (name_key)
);

CREATE INDEX IF NOT EXISTS companies_country_idx
    ON public.companies (LOWER(BTRIM(country)));

CREATE INDEX IF NOT EXISTS companies_industry_idx
    ON public.companies (LOWER(BTRIM(industry)));


-- ------------------------------------------------------------
-- 2. KEEP updated_at HONEST
-- ------------------------------------------------------------

DROP TRIGGER IF EXISTS companies_set_updated_at ON public.companies;
CREATE TRIGGER companies_set_updated_at
    BEFORE UPDATE ON public.companies
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();


-- ------------------------------------------------------------
-- 3. WHO MAY SEE AND WRITE
-- Reading is for every signed-in account: a directory of companies is
-- public information and a parent may look up where their child works.
-- Adding is open to everyone because a company missing from the list is
-- a company that cannot be claimed. Correcting is not.
-- ------------------------------------------------------------

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS companies_readable ON public.companies;
CREATE POLICY companies_readable ON public.companies
    FOR SELECT TO authenticated
    USING (TRUE);

DROP POLICY IF EXISTS companies_anyone_may_add ON public.companies;
CREATE POLICY companies_anyone_may_add ON public.companies
    FOR INSERT TO authenticated
    WITH CHECK (added_by = auth.uid());

DROP POLICY IF EXISTS companies_admin_edit ON public.companies;
CREATE POLICY companies_admin_edit ON public.companies
    FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS companies_admin_remove ON public.companies;
CREATE POLICY companies_admin_remove ON public.companies
    FOR DELETE TO authenticated
    USING (public.is_admin());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies TO authenticated;


-- ------------------------------------------------------------
-- 4. WHICH COMPANY A MEMBER BELONGS TO
-- Two plain columns, so an account that has never mentioned a company is
-- simply blank rather than broken, and the feed treats a blank as
-- "has not answered" instead of "works somewhere else".
-- ------------------------------------------------------------

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS company TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS company_role TEXT;

COMMENT ON COLUMN public.profiles.company IS
    'The company this member claims, spelled as it is in public.companies.';
COMMENT ON COLUMN public.profiles.company_role IS
    'director, staff or member - what they do there, nothing else.';

CREATE INDEX IF NOT EXISTS profiles_company_idx
    ON public.profiles (LOWER(BTRIM(company)));


-- ------------------------------------------------------------
-- 5. A COMPANY ACCOUNT MAY WRITE ANNOUNCEMENTS
-- The bulletin board itself (PART 14) only lets a campus account write.
-- A director who is not a student has nothing to say on a campus board,
-- so a second, separate policy opens the same table to a member who
-- carries a company. Postgres treats these two INSERT policies as
-- alternatives, so adding one takes nothing away from the other.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_company_member()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT COALESCE((
        SELECT BTRIM(COALESCE(p.company, '')) <> ''
        FROM public.profiles AS p
        WHERE p.id = auth.uid()
    ), FALSE);
$$;

REVOKE ALL ON FUNCTION public.is_company_member() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_company_member() TO authenticated;

DROP POLICY IF EXISTS bulletins_company_write ON public.bulletins;
CREATE POLICY bulletins_company_write ON public.bulletins
    FOR INSERT TO authenticated
    WITH CHECK (author_id = auth.uid() AND public.is_company_member());

-- The board sorts into columns. A company writes into one of its own.
-- This is the constraint Postgres named by itself when the column was
-- created, so dropping it by that name is the whole edit.
ALTER TABLE public.bulletins
    DROP CONSTRAINT IF EXISTS bulletins_section_check;
ALTER TABLE public.bulletins
    ADD CONSTRAINT bulletins_section_check CHECK (
        section IN ('world', 'university', 'people', 'company')
    );


-- ------------------------------------------------------------
-- 6. TELL POSTGREST THE SHAPE CHANGED
-- ------------------------------------------------------------

NOTIFY pgrst, 'reload schema';


-- ============ PART 16/17: migrations/20261017_realtime_broadcast.sql ============

-- PART 16: realtime broadcast for the typing / recording indicators.
--
-- "typing…" and "recording a voice message…" are never stored: they ride as
-- realtime broadcast frames, so there is no table to build here. Supabase
-- decides who may send and receive those frames with row-level security on its
-- internal realtime.messages table, and a project that was never given a policy
-- drops the frames quietly. Two policies fix that: signed-in users only, and
-- only on the chat-activity-* channels this app opens.
--
-- Everything is wrapped so a project that lacks the table, the column or the
-- grant prints a notice instead of aborting the rest of the paste.

DO $do$
DECLARE
    channel_column text;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'realtime' AND table_name = 'messages'
    ) THEN
        RAISE NOTICE 'realtime.messages is missing: typing indicators will not appear.';
        RETURN;
    END IF;

    SELECT c.column_name INTO channel_column
    FROM information_schema.columns AS c
    WHERE c.table_schema = 'realtime'
      AND c.table_name = 'messages'
      AND c.column_name IN ('channel_name', 'topic')
    ORDER BY array_position(ARRAY['channel_name', 'topic'], c.column_name)
    LIMIT 1;

    IF channel_column IS NULL THEN
        RAISE NOTICE 'realtime.messages has no channel column: typing indicators will not appear.';
        RETURN;
    END IF;

    -- realtime.messages belongs to Supabase itself, so the role running this may
    -- not be allowed to policy it. That must not stop the rest of the paste.
    BEGIN
        DROP POLICY IF EXISTS chat_activity_broadcast_read ON realtime.messages;
        EXECUTE format(
            'CREATE POLICY chat_activity_broadcast_read ON realtime.messages
                 FOR SELECT TO authenticated USING (%I LIKE ''chat-activity-%%'')',
            channel_column
        );

        DROP POLICY IF EXISTS chat_activity_broadcast_write ON realtime.messages;
        EXECUTE format(
            'CREATE POLICY chat_activity_broadcast_write ON realtime.messages
                 FOR INSERT TO authenticated WITH CHECK (%I LIKE ''chat-activity-%%'')',
            channel_column
        );

        RAISE NOTICE 'Broadcast policies created on realtime.messages using %.', channel_column;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Could not add the broadcast policies: %. The typing indicator may stay silent.', SQLERRM;
    END;
END
$do$;

DO $do$
BEGIN
    GRANT SELECT, INSERT ON realtime.messages TO authenticated;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not re-grant realtime.messages (already granted, or not permitted): %', SQLERRM;
END
$do$;

NOTIFY pgrst, 'reload schema';


-- ============ PART 17/17: migrations/20261017_private_groups.sql ============

-- PART 17: private group chats, the WhatsApp shape.
--
-- The community tables already exist, but everything they made was public: the
-- is_public default was TRUE and the only way to put a person in a group was
-- for that person to walk in themselves. A group you make with four friends is
-- the other shape — nobody can see its name, its members or its messages
-- unless you are in it. So this part flips the default, adds a function that
-- creates a group with a chosen list of people, and a function that hands the
-- chat list everything it needs in one call.
--
-- A member row for someone else still cannot be inserted through the plain
-- policies (they only let you add yourself), which is why the adding runs
-- inside SECURITY DEFINER functions that check the role first.

ALTER TABLE public.communities
    ALTER COLUMN is_public SET DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS public.community_reads (
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    last_read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (community_id, user_id)
);

ALTER TABLE public.community_reads ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE ON public.community_reads TO authenticated;

DROP POLICY IF EXISTS "Members own their own read marker"
    ON public.community_reads;
CREATE POLICY "Members own their own read marker"
    ON public.community_reads FOR ALL TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

CREATE INDEX IF NOT EXISTS community_reads_user_idx
    ON public.community_reads (user_id, last_read_at DESC);

CREATE OR REPLACE FUNCTION public.create_group(
    p_name TEXT,
    p_member_ids UUID[] DEFAULT ARRAY[]::UUID[]
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    new_community_id UUID;
    current_user_id UUID := auth.uid();
BEGIN
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'You must be signed in to create a group.';
    END IF;
    IF char_length(trim(COALESCE(p_name, ''))) NOT BETWEEN 3 AND 80 THEN
        RAISE EXCEPTION 'Group names must be between 3 and 80 characters.';
    END IF;
    IF COALESCE(array_length(p_member_ids, 1), 0) > 200 THEN
        RAISE EXCEPTION 'A group takes at most 200 people at a time.';
    END IF;

    INSERT INTO public.communities (owner_id, name, description, kind, is_public)
    VALUES (current_user_id, trim(p_name), '', 'group', FALSE)
    RETURNING id INTO new_community_id;

    INSERT INTO public.community_members (community_id, user_id, role)
    VALUES (new_community_id, current_user_id, 'owner')
    ON CONFLICT (community_id, user_id) DO NOTHING;

    /* Only a real account can be pulled in, and a block on either side keeps
       the person out: nobody ends up in a group with someone they blocked. */
    INSERT INTO public.community_members (community_id, user_id, role)
    SELECT new_community_id, candidate.user_id, 'member'
    FROM unnest(COALESCE(p_member_ids, ARRAY[]::UUID[])) AS candidate(user_id)
    WHERE candidate.user_id <> current_user_id
      AND EXISTS (
          SELECT 1
          FROM public.profiles AS profile
          WHERE profile.id = candidate.user_id
      )
      AND NOT EXISTS (
          SELECT 1
          FROM public.user_blocks AS blocker
          WHERE (blocker.blocker_id = current_user_id AND blocker.blocked_id = candidate.user_id)
             OR (blocker.blocker_id = candidate.user_id AND blocker.blocked_id = current_user_id)
      )
    ON CONFLICT (community_id, user_id) DO NOTHING;

    RETURN new_community_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.add_group_members(
    p_community_id UUID,
    p_user_ids UUID[]
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    current_user_id UUID := auth.uid();
    total_members INT;
BEGIN
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'You must be signed in to add people.';
    END IF;
    IF NOT public.can_manage_community(p_community_id) THEN
        RAISE EXCEPTION 'Only the owner or an admin can add people to this group.';
    END IF;
    IF COALESCE(array_length(p_user_ids, 1), 0) > 200 THEN
        RAISE EXCEPTION 'A group takes at most 200 people at a time.';
    END IF;

    INSERT INTO public.community_members (community_id, user_id, role)
    SELECT p_community_id, candidate.user_id, 'member'
    FROM unnest(COALESCE(p_user_ids, ARRAY[]::UUID[])) AS candidate(user_id)
    WHERE candidate.user_id <> current_user_id
      AND EXISTS (
          SELECT 1
          FROM public.profiles AS profile
          WHERE profile.id = candidate.user_id
      )
      AND NOT EXISTS (
          SELECT 1
          FROM public.user_blocks AS blocker
          WHERE (blocker.blocker_id = current_user_id AND blocker.blocked_id = candidate.user_id)
             OR (blocker.blocker_id = candidate.user_id AND blocker.blocked_id = current_user_id)
      )
    ON CONFLICT (community_id, user_id) DO NOTHING;

    SELECT count(*) INTO total_members
    FROM public.community_members AS member
    WHERE member.community_id = p_community_id;

    RETURN total_members;
END;
$$;

/* One call paints the whole chat list: every group I am in with who made it,
   how many are inside, the last message and how many I have not read. Reading
   it through the plain tables would take four round trips per group. */
CREATE OR REPLACE FUNCTION public.my_groups()
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    owner_id UUID,
    my_role TEXT,
    member_count BIGINT,
    last_message_at TIMESTAMPTZ,
    last_sender_id UUID,
    last_content TEXT,
    last_media_url TEXT,
    unread_count BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT community.id,
           community.name,
           community.description,
           community.owner_id,
           membership.role,
           counter.member_count,
           latest.created_at,
           latest.sender_id,
           latest.content,
           latest.media_url,
           COALESCE(unread.unread_count, 0)
    FROM public.community_members AS membership
    JOIN public.communities AS community
        ON community.id = membership.community_id
    CROSS JOIN LATERAL (
        SELECT count(*) AS member_count
        FROM public.community_members AS every_member
        WHERE every_member.community_id = community.id
    ) AS counter
    LEFT JOIN public.community_reads AS marker
        ON marker.community_id = community.id
       AND marker.user_id = membership.user_id
    LEFT JOIN LATERAL (
        SELECT message.created_at,
               message.sender_id,
               message.content,
               message.media_url
        FROM public.community_messages AS message
        WHERE message.community_id = community.id
        ORDER BY message.created_at DESC
        LIMIT 1
    ) AS latest ON TRUE
    LEFT JOIN LATERAL (
        SELECT count(*) AS unread_count
        FROM public.community_messages AS message
        WHERE message.community_id = community.id
          AND message.sender_id <> membership.user_id
          AND message.created_at >
              COALESCE(marker.last_read_at, 'epoch'::TIMESTAMPTZ)
    ) AS unread ON TRUE
    WHERE membership.user_id = (SELECT auth.uid())
      AND community.kind = 'group';
$$;

CREATE OR REPLACE FUNCTION public.mark_group_read(p_community_id UUID)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
    INSERT INTO public.community_reads (community_id, user_id, last_read_at)
    VALUES (p_community_id, (SELECT auth.uid()), NOW())
    ON CONFLICT (community_id, user_id)
    DO UPDATE SET last_read_at =
        GREATEST(community_reads.last_read_at, EXCLUDED.last_read_at);
$$;

REVOKE ALL ON FUNCTION public.create_group(TEXT, UUID[]) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.add_group_members(UUID, UUID[]) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.my_groups() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.mark_group_read(UUID) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.create_group(TEXT, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_group_members(UUID, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.my_groups() TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_group_read(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';


-- ===================================================================
-- FINAL CHECK: every row should read ok
-- ===================================================================
SELECT 'publication: ' || t.table_name AS check_name,
       CASE WHEN pt.tablename IS NOT NULL THEN 'ok' ELSE 'NOT PUBLISHED FOR REALTIME' END AS result
FROM (VALUES ('messages'), ('community_messages'), ('call_signals'), ('notifications')) AS t(table_name)
LEFT JOIN pg_publication_tables AS pt
       ON pt.pubname = 'supabase_realtime'
      AND pt.schemaname = 'public'
      AND pt.tablename = t.table_name
UNION ALL
SELECT 'table: ' || t.table_name,
       CASE WHEN tb.table_name IS NOT NULL THEN 'ok' ELSE 'MISSING' END
FROM (VALUES ('user_blocks'), ('user_presence'), ('call_signals'), ('friend_requests'),
             ('message_attachments'), ('notification_preferences'), ('student_registrations'),
             ('contact_names'), ('message_reactions'), ('message_stars'), ('lecturer_submissions'),
             ('programmes'), ('units'), ('class_sessions'), ('bulletins'), ('companies'),
             ('community_reads')) AS t(table_name)
LEFT JOIN information_schema.tables AS tb
       ON tb.table_schema = 'public' AND tb.table_name = t.table_name
UNION ALL
SELECT 'group function: ' || f.function_name,
       CASE WHEN x.specific_name IS NOT NULL THEN 'ok' ELSE 'MISSING (groups will not work)' END
FROM (VALUES ('create_group'), ('add_group_members'), ('my_groups'), ('mark_group_read')) AS f(function_name)
LEFT JOIN information_schema.routines AS x
       ON x.routine_schema = 'public' AND x.routine_name = f.function_name
UNION ALL
SELECT 'column: messages.' || c.column_name,
       CASE WHEN x.column_name IS NOT NULL THEN 'ok' ELSE 'MISSING' END
FROM (VALUES ('edited_at'), ('deleted_for_everyone'), ('deleted_by'), ('reply_to'), ('reply_preview')) AS c(column_name)
LEFT JOIN information_schema.columns AS x
       ON x.table_schema = 'public' AND x.table_name = 'messages' AND x.column_name = c.column_name
UNION ALL
SELECT 'column: profiles.' || c.column_name,
       CASE WHEN x.column_name IS NOT NULL THEN 'ok' ELSE 'MISSING' END
FROM (VALUES ('role'), ('verification_status'), ('is_discoverable'), ('university'),
               ('staff_id_number'), ('employment_status'), ('study_mode'), ('lecturer_since'), ('company'), ('company_role')) AS c(column_name)
LEFT JOIN information_schema.columns AS x
       ON x.table_schema = 'public' AND x.table_name = 'profiles' AND x.column_name = c.column_name
ORDER BY check_name;
