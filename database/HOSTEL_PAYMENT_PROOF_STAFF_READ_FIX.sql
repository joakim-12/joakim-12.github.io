CREATE POLICY hostel_payment_proofs_staff_read_fix ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'hostel-payment-proofs'
        AND EXISTS (
            SELECT 1
              FROM public.hostel_bookings b
              JOIN public.hostel_rooms r ON r.id = b.room_id
              JOIN public.hostels h ON h.id = r.hostel_id
             WHERE b.id::TEXT = (storage.foldername(storage.objects.name))[2]
               AND public.is_school_staff(h.school_key)
        )
    );
NOTIFY pgrst, 'reload schema';
