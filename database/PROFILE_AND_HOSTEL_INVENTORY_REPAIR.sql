-- Data-preserving repair for the Campus Connect profile and hostel screens.
-- Adds missing profile fields and seeds the Kabarak inventory supplied by the
-- app owner. Existing hostels, rooms, and bookings are left in place.
BEGIN;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS staff_id_number TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS employment_status TEXT NOT NULL DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS study_mode TEXT NOT NULL DEFAULT 'normal',
    ADD COLUMN IF NOT EXISTS lecturer_since TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS company TEXT,
    ADD COLUMN IF NOT EXISTS company_role TEXT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'profiles_staff_id_number_length_check'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_staff_id_number_length_check
            CHECK (char_length(staff_id_number) <= 32);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'profiles_employment_status_check'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_employment_status_check
            CHECK (employment_status IN ('active', 'passive'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'profiles_study_mode_check'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_study_mode_check
            CHECK (study_mode IN ('normal', 'retake', 'online'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'profiles_company_role_check'
          AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_company_role_check
            CHECK (company_role IS NULL OR company_role IN ('director', 'staff', 'member'));
    END IF;
END;
$$;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_staff_id_key
    ON public.profiles (staff_id_number)
    WHERE staff_id_number <> '';

CREATE INDEX IF NOT EXISTS profiles_company_idx
    ON public.profiles (LOWER(BTRIM(company)));

-- The four men's hostels already exist. Add the five women's hostels listed
-- by the app owner without overwriting any school-edited hostel records.
INSERT INTO public.hostels (school, name, gender, verified)
VALUES
    ('Kabarak University', 'Sote A', 'women', TRUE),
    ('Kabarak University', 'Sote B', 'women', TRUE),
    ('Kabarak University', 'Kabon', 'women', TRUE),
    ('Kabarak University', 'Central', 'women', TRUE),
    ('Kabarak University', 'Lena Moi', 'women', TRUE)
ON CONFLICT (school_key, name_key) DO NOTHING;

-- The owner specified room counts but not room-by-room sharing capacities.
-- Seed each numbered room at capacity 1 to avoid overbooking. The housing
-- office can edit actual capacity/sharing before approving shared occupancy.
INSERT INTO public.hostel_rooms (hostel_id, label, sharing, capacity, note)
SELECT h.id,
       LPAD(room_number::TEXT, 3, '0'),
       'other',
       1,
       'Initial capacity placeholder: housing office must confirm actual sharing capacity.'
  FROM public.hostels AS h
 CROSS JOIN LATERAL GENERATE_SERIES(
       1,
       CASE WHEN h.gender = 'women' THEN 135 ELSE 90 END
 ) AS rooms(room_number)
 WHERE h.school_key = 'kabarak university'
   AND h.gender IN ('men', 'women')
ON CONFLICT (hostel_id, label) DO NOTHING;

NOTIFY pgrst, 'reload schema';
COMMIT;
