-- Run once in the Supabase SQL editor to preserve the status reference on each reply.
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS reply_preview JSONB;

NOTIFY pgrst, 'reload schema';
