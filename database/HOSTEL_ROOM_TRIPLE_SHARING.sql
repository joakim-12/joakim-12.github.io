ALTER TABLE public.hostel_rooms DROP CONSTRAINT hostel_rooms_sharing_check;
ALTER TABLE public.hostel_rooms ADD CONSTRAINT hostel_rooms_sharing_check CHECK (sharing IN ('single','twin','double','triple','four','other'));
NOTIFY pgrst, 'reload schema';
