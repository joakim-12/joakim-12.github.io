-- Let direct-message recipients and community members read attachments shared
-- in their conversations. Objects remain private and only messages that point
-- at an exact object path grant access.
DROP POLICY IF EXISTS "Chat recipients view private message media" ON storage.objects;
CREATE POLICY "Chat recipients view private message media"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'campus-private-media'
    AND (
        EXISTS (
            SELECT 1
            FROM public.messages AS m
            WHERE m.receiver_id = (SELECT auth.uid())
              AND m.media_url = 'private-media:' || objects.name
        )
        OR EXISTS (
            SELECT 1
            FROM public.community_messages AS cm
            JOIN public.community_members AS member
              ON member.community_id = cm.community_id
            WHERE member.user_id = (SELECT auth.uid())
              AND cm.media_url = 'private-media:' || objects.name
        )
    )
);
