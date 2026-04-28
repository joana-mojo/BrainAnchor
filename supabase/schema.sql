-- =====================================================================
-- BRAIN ANCHOR — SUPABASE SCHEMA
-- Run this entire script in your Supabase SQL Editor.
-- Idempotent: tables are guarded with IF NOT EXISTS, policies are
-- DROP'd then re-CREATE'd so the script can be re-run safely.
-- =====================================================================

-- 0. Required extensions ----------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. profiles --------------------------------------------------------------
-- Shared base row for both patients and providers. The `id` matches the
-- corresponding row in `auth.users`, which Supabase Auth manages.
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    role TEXT NOT NULL CHECK (role IN ('patient', 'provider', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 2. patients --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.patients (
    id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    phone_number TEXT UNIQUE,
    first_name TEXT NOT NULL,
    middle_name TEXT,
    last_name TEXT NOT NULL,
    nickname TEXT NOT NULL,
    suffix TEXT,
    birthday DATE NOT NULL,
    sex_assigned_at_birth TEXT NOT NULL CHECK (sex_assigned_at_birth IN ('Male', 'Female')),
    gender_identity TEXT,
    email TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

ALTER TABLE public.patients
    ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 3. providers -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.providers (
    id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    first_name TEXT NOT NULL,
    middle_name TEXT,
    last_name TEXT NOT NULL,
    suffix TEXT,
    birthday DATE NOT NULL,
    gender TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    license_number TEXT UNIQUE NOT NULL,
    specialization TEXT NOT NULL,
    years_of_experience INTEGER NOT NULL DEFAULT 0,
    approval_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    verification_file_url TEXT,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 4. provider_documents ----------------------------------------------------
-- Metadata for the files stored in the `provider_documents` storage bucket.
CREATE TABLE IF NOT EXISTS public.provider_documents (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    provider_id UUID REFERENCES public.providers(id) ON DELETE CASCADE NOT NULL,
    file_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 5. user_mpin -------------------------------------------------------------
-- Hashed (SHA-256) 4-digit MPIN per user. The plain MPIN never touches the DB.
-- `recovery_password_hash` is a SHA-256 hash of the user's chosen recovery
-- password — used by the `reset_patient_mpin` RPC to let a user reset their
-- MPIN if they forget it.
CREATE TABLE IF NOT EXISTS public.user_mpin (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    hashed_mpin TEXT NOT NULL,
    recovery_password_hash TEXT,
    failed_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- For older databases that already have user_mpin without the new column.
ALTER TABLE public.user_mpin
    ADD COLUMN IF NOT EXISTS recovery_password_hash TEXT;

-- 6. otp_verifications -----------------------------------------------------
-- Audit log of OTP attempts. Supabase Auth itself stores the active OTP, but
-- we track verification events for compliance and rate-limit visibility.
CREATE TABLE IF NOT EXISTS public.otp_verifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number TEXT NOT NULL,
    purpose TEXT NOT NULL DEFAULT 'login'
        CHECK (purpose IN ('signup', 'login', 'reset')),
    status TEXT NOT NULL DEFAULT 'sent'
        CHECK (status IN ('sent', 'verified', 'expired', 'failed')),
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS otp_verifications_phone_idx
    ON public.otp_verifications(phone_number);

-- 7. patient_moods ----------------------------------------------------------
-- Stores one mood snapshot per patient per day. Home mood check-in and
-- Mood Journal both read/write this same table so data stays in sync.
CREATE TABLE IF NOT EXISTS public.patient_moods (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    mood_label TEXT NOT NULL
        CHECK (mood_label IN ('Amazing', 'Good', 'Okay', 'Sad', 'Stressed')),
    mood_score INTEGER NOT NULL CHECK (mood_score BETWEEN 1 AND 5),
    note TEXT,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    source TEXT NOT NULL DEFAULT 'home'
        CHECK (source IN ('home', 'journal')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE (user_id, entry_date)
);

CREATE INDEX IF NOT EXISTS patient_moods_user_date_idx
    ON public.patient_moods (user_id, entry_date DESC);

-- 8. wellness_checkins ------------------------------------------------------
-- One Wellness Check-in per user per day. Stores AI summary and suggestions
-- so the "History" view can show prior check-ins and allow deletion.
CREATE TABLE IF NOT EXISTS public.wellness_checkins (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    checkin_date DATE NOT NULL DEFAULT CURRENT_DATE,
    answers JSONB NOT NULL DEFAULT '{}'::jsonb,
    ai_summary TEXT NOT NULL DEFAULT '',
    ai_suggestions JSONB NOT NULL DEFAULT '[]'::jsonb,
    ai_reminder TEXT NOT NULL DEFAULT '',
    risk_level TEXT NOT NULL DEFAULT 'low'
        CHECK (risk_level IN ('low', 'moderate', 'high', 'crisis')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE (user_id, checkin_date)
);

CREATE INDEX IF NOT EXISTS wellness_checkins_user_date_idx
    ON public.wellness_checkins (user_id, checkin_date DESC);

-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================

ALTER TABLE public.profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.providers           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_documents  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_mpin           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_verifications   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_moods       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wellness_checkins   ENABLE ROW LEVEL SECURITY;

-- profiles ------------------------------------------------------------
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Users can read their own profile" ON public.profiles;
CREATE POLICY "Users can read their own profile"
    ON public.profiles FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- patients ------------------------------------------------------------
DROP POLICY IF EXISTS "Patients can insert their own data" ON public.patients;
CREATE POLICY "Patients can insert their own data"
    ON public.patients FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Patients can read their own data" ON public.patients;
CREATE POLICY "Patients can read their own data"
    ON public.patients FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Patients can update their own data" ON public.patients;
CREATE POLICY "Patients can update their own data"
    ON public.patients FOR UPDATE USING (auth.uid() = id);

-- providers -----------------------------------------------------------
DROP POLICY IF EXISTS "Providers can insert their own data" ON public.providers;
CREATE POLICY "Providers can insert their own data"
    ON public.providers FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Providers can read their own data" ON public.providers;
CREATE POLICY "Providers can read their own data"
    ON public.providers FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Patients can read approved providers" ON public.providers;
CREATE POLICY "Patients can read approved providers"
    ON public.providers FOR SELECT USING (
        approval_status = 'approved' AND EXISTS (
            SELECT 1
            FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role = 'patient'
        )
    );
DROP POLICY IF EXISTS "Providers can update their own data" ON public.providers;
CREATE POLICY "Providers can update their own data"
    ON public.providers FOR UPDATE USING (auth.uid() = id);

-- provider_documents --------------------------------------------------
DROP POLICY IF EXISTS "Providers can insert their own documents" ON public.provider_documents;
CREATE POLICY "Providers can insert their own documents"
    ON public.provider_documents FOR INSERT WITH CHECK (auth.uid() = provider_id);
DROP POLICY IF EXISTS "Providers can read their own documents" ON public.provider_documents;
CREATE POLICY "Providers can read their own documents"
    ON public.provider_documents FOR SELECT USING (auth.uid() = provider_id);

-- user_mpin -----------------------------------------------------------
DROP POLICY IF EXISTS "Users can insert their own mpin" ON public.user_mpin;
CREATE POLICY "Users can insert their own mpin"
    ON public.user_mpin FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can read their own mpin" ON public.user_mpin;
CREATE POLICY "Users can read their own mpin"
    ON public.user_mpin FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own mpin" ON public.user_mpin;
CREATE POLICY "Users can update their own mpin"
    ON public.user_mpin FOR UPDATE USING (auth.uid() = user_id);

-- otp_verifications --------------------------------------------------
DROP POLICY IF EXISTS "Users can read their own otp logs" ON public.otp_verifications;
CREATE POLICY "Users can read their own otp logs"
    ON public.otp_verifications FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert otp logs for themselves" ON public.otp_verifications;
CREATE POLICY "Users can insert otp logs for themselves"
    ON public.otp_verifications FOR INSERT WITH CHECK (
        auth.uid() = user_id OR user_id IS NULL
    );

-- patient_moods ------------------------------------------------------
DROP POLICY IF EXISTS "Users can insert their own moods" ON public.patient_moods;
CREATE POLICY "Users can insert their own moods"
    ON public.patient_moods FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can read their own moods" ON public.patient_moods;
CREATE POLICY "Users can read their own moods"
    ON public.patient_moods FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own moods" ON public.patient_moods;
CREATE POLICY "Users can update their own moods"
    ON public.patient_moods FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete their own moods" ON public.patient_moods;
CREATE POLICY "Users can delete their own moods"
    ON public.patient_moods FOR DELETE USING (auth.uid() = user_id);

-- wellness_checkins ---------------------------------------------------
DROP POLICY IF EXISTS "Users can insert their own wellness checkins" ON public.wellness_checkins;
CREATE POLICY "Users can insert their own wellness checkins"
    ON public.wellness_checkins FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can read their own wellness checkins" ON public.wellness_checkins;
CREATE POLICY "Users can read their own wellness checkins"
    ON public.wellness_checkins FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own wellness checkins" ON public.wellness_checkins;
CREATE POLICY "Users can update their own wellness checkins"
    ON public.wellness_checkins FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete their own wellness checkins" ON public.wellness_checkins;
CREATE POLICY "Users can delete their own wellness checkins"
    ON public.wellness_checkins FOR DELETE USING (auth.uid() = user_id);

-- =====================================================================
-- STORAGE
-- =====================================================================
-- Run this once in the Supabase Dashboard, or use the bucket policies below.
--
--   Storage > New bucket > name = 'provider_documents' > Private
--   Storage > New bucket > name = 'patient_avatars' > Public
--
-- Then run the policies below so providers can upload to their own folder.

-- Ensure required buckets exist (safe to re-run).
INSERT INTO storage.buckets (id, name, public)
VALUES ('provider_documents', 'provider_documents', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('patient_avatars', 'patient_avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated providers to upload only into their own folder:
--   provider_documents/<auth.uid()>/...
DROP POLICY IF EXISTS "Providers can upload their own license" ON storage.objects;
CREATE POLICY "Providers can upload their own license"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'provider_documents'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "Providers can read their own license" ON storage.objects;
CREATE POLICY "Providers can read their own license"
    ON storage.objects FOR SELECT TO authenticated
    USING (
        bucket_id = 'provider_documents'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Allow patients to upload avatar images into their own folder:
--   patient_avatars/<auth.uid()>/...
DROP POLICY IF EXISTS "Patients can upload their own avatar" ON storage.objects;
CREATE POLICY "Patients can upload their own avatar"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'patient_avatars'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "Patients can update their own avatar" ON storage.objects;
CREATE POLICY "Patients can update their own avatar"
    ON storage.objects FOR UPDATE TO authenticated
    USING (
        bucket_id = 'patient_avatars'
        AND (storage.foldername(name))[1] = auth.uid()::text
    )
    WITH CHECK (
        bucket_id = 'patient_avatars'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "Public can read patient avatars" ON storage.objects;
CREATE POLICY "Public can read patient avatars"
    ON storage.objects FOR SELECT TO public
    USING (bucket_id = 'patient_avatars');

-- =====================================================================
-- HELPFUL TRIGGERS
-- =====================================================================

-- Auto-update `updated_at` on row updates.
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS profiles_set_updated_at ON public.profiles;
CREATE TRIGGER profiles_set_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS patients_set_updated_at ON public.patients;
CREATE TRIGGER patients_set_updated_at
    BEFORE UPDATE ON public.patients
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS providers_set_updated_at ON public.providers;
CREATE TRIGGER providers_set_updated_at
    BEFORE UPDATE ON public.providers
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS user_mpin_set_updated_at ON public.user_mpin;
CREATE TRIGGER user_mpin_set_updated_at
    BEFORE UPDATE ON public.user_mpin
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS patient_moods_set_updated_at ON public.patient_moods;
CREATE TRIGGER patient_moods_set_updated_at
    BEFORE UPDATE ON public.patient_moods
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS wellness_checkins_set_updated_at ON public.wellness_checkins;
CREATE TRIGGER wellness_checkins_set_updated_at
    BEFORE UPDATE ON public.wellness_checkins
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- =====================================================================
-- MPIN RECOVERY RPC
-- =====================================================================
-- Lets a patient reset their MPIN using the recovery password they chose
-- at sign-up. Runs with SECURITY DEFINER so it can read user_mpin and
-- update auth.users for any user — verification of the recovery password
-- is the security boundary.
--
-- Steps:
--   1. Look up the auth user by email.
--   2. Verify SHA-256(p_recovery_password) matches stored recovery_password_hash.
--   3. Update auth.users.encrypted_password to bcrypt(SHA-256("brainanchor-mpin-v1:" || p_new_mpin))
--      so the next email + MPIN login succeeds.
--   4. Update user_mpin.hashed_mpin to SHA-256(p_new_mpin).
-- Returns TRUE on success, FALSE if email or recovery password don't match.

CREATE OR REPLACE FUNCTION public.reset_patient_mpin(
    p_email TEXT,
    p_recovery_password TEXT,
    p_new_mpin TEXT
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_user_id UUID;
    v_stored_hash TEXT;
    v_input_hash TEXT;
    v_derived_password TEXT;
BEGIN
    SELECT u.id INTO v_user_id
    FROM auth.users u
    WHERE u.email = LOWER(p_email)
    LIMIT 1;

    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    SELECT m.recovery_password_hash INTO v_stored_hash
    FROM public.user_mpin m
    WHERE m.user_id = v_user_id;

    IF v_stored_hash IS NULL THEN
        RETURN FALSE;
    END IF;

    v_input_hash := encode(digest(p_recovery_password, 'sha256'), 'hex');
    IF v_input_hash <> v_stored_hash THEN
        RETURN FALSE;
    END IF;

    -- Mirrors AuthService.deriveMpinPassword in lib/services/auth_service.dart
    v_derived_password := encode(
        digest('brainanchor-mpin-v1:' || p_new_mpin, 'sha256'),
        'hex'
    );

    UPDATE auth.users
    SET encrypted_password = crypt(v_derived_password, gen_salt('bf')),
        updated_at = NOW()
    WHERE id = v_user_id;

    UPDATE public.user_mpin
    SET hashed_mpin = encode(digest(p_new_mpin, 'sha256'), 'hex'),
        failed_attempts = 0,
        locked_until = NULL,
        updated_at = NOW()
    WHERE user_id = v_user_id;

    RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.reset_patient_mpin(TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reset_patient_mpin(TEXT, TEXT, TEXT)
    TO anon, authenticated;

-- =====================================================================
-- LOGIN HINT RPC
-- =====================================================================
-- Lets the patient login screen tell the user "that email isn't
-- registered" before they type their MPIN, instead of showing a generic
-- "invalid email or MPIN" error. Returns TRUE only when an auth.users row
-- exists for the email AND it has a `profiles.role = 'patient'` record.
--
-- Security note: this knowingly enables email-enumeration for patient
-- accounts, which is the trade-off needed for the friendlier UX.

CREATE OR REPLACE FUNCTION public.patient_email_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM auth.users u
    JOIN public.profiles p ON p.id = u.id
    WHERE u.email = LOWER(p_email)
      AND p.role = 'patient';
    RETURN v_count > 0;
END;
$$;

REVOKE ALL ON FUNCTION public.patient_email_exists(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.patient_email_exists(TEXT)
    TO anon, authenticated;

-- Mirrors `patient_email_exists` for the doctor / provider login screen.
-- Returns TRUE only when the auth user has `profiles.role = 'provider'`,
-- so the warning correctly says "no provider account found" and doesn't
-- leak whether a patient with that email exists.
CREATE OR REPLACE FUNCTION public.provider_email_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM auth.users u
    JOIN public.profiles p ON p.id = u.id
    WHERE u.email = LOWER(p_email)
      AND p.role = 'provider';
    RETURN v_count > 0;
END;
$$;

REVOKE ALL ON FUNCTION public.provider_email_exists(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.provider_email_exists(TEXT)
    TO anon, authenticated;

-- =====================================================================
-- MENTAL HEALTH CLINICS DIRECTORY
-- =====================================================================
-- Curated directory of real mental-health clinics shown to patients in
-- the "Book Consultation > Clinics" tab. Maintained by admins (or a
-- future provider-submission flow). Public READ so anyone using the app
-- can discover them; writes go through the admin role only.
--
-- We intentionally don't depend on PostGIS here: distance is computed
-- client-side by the Flutter app using the haversine formula in
-- LocationService. Coordinate pair ranges keep bad data out.

CREATE TABLE IF NOT EXISTS public.mental_health_clinics (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT,
    city TEXT,
    region TEXT,
    country TEXT NOT NULL DEFAULT 'Philippines',
    latitude DOUBLE PRECISION NOT NULL
        CHECK (latitude BETWEEN -90 AND 90),
    longitude DOUBLE PRECISION NOT NULL
        CHECK (longitude BETWEEN -180 AND 180),
    specialty TEXT,
    phone TEXT,
    website TEXT,
    rating NUMERIC(3, 2) CHECK (rating IS NULL OR (rating BETWEEN 0 AND 5)),
    review_count INTEGER NOT NULL DEFAULT 0
        CHECK (review_count >= 0),
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE
        DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE
        DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Speeds up distance queries that bound by a lat/lon box first.
CREATE INDEX IF NOT EXISTS mental_health_clinics_lat_lon_idx
    ON public.mental_health_clinics (latitude, longitude);

-- Speeds up name-based search.
CREATE INDEX IF NOT EXISTS mental_health_clinics_name_idx
    ON public.mental_health_clinics (LOWER(name));

ALTER TABLE public.mental_health_clinics ENABLE ROW LEVEL SECURITY;

-- Anyone (including unauthenticated visitors) can browse the directory.
DROP POLICY IF EXISTS "Anyone can read mental health clinics"
    ON public.mental_health_clinics;
CREATE POLICY "Anyone can read mental health clinics"
    ON public.mental_health_clinics FOR SELECT
    USING (TRUE);

-- Only admins (profiles.role = 'admin') can insert / update / delete.
DROP POLICY IF EXISTS "Admins can write mental health clinics"
    ON public.mental_health_clinics;
CREATE POLICY "Admins can write mental health clinics"
    ON public.mental_health_clinics FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

DROP TRIGGER IF EXISTS mental_health_clinics_set_updated_at
    ON public.mental_health_clinics;
CREATE TRIGGER mental_health_clinics_set_updated_at
    BEFORE UPDATE ON public.mental_health_clinics
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
