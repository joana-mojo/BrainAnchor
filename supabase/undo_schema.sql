-- =====================================================================
-- BRAIN ANCHOR — UNDO SUPABASE SCHEMA
-- Run this in your Supabase SQL Editor to roll back schema.sql.
-- CAUTION: this deletes ALL data in these tables.
-- =====================================================================

-- 1. Drop RPC functions ----------------------------------------------
DROP FUNCTION IF EXISTS public.reset_patient_mpin(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.patient_email_exists(TEXT);
DROP FUNCTION IF EXISTS public.provider_email_exists(TEXT);

-- 1a. Drop policies on storage.objects --------------------------------
DROP POLICY IF EXISTS "Providers can upload their own license" ON storage.objects;
DROP POLICY IF EXISTS "Providers can read their own license"   ON storage.objects;
DROP POLICY IF EXISTS "Patients can upload their own avatar"   ON storage.objects;
DROP POLICY IF EXISTS "Patients can update their own avatar"   ON storage.objects;
DROP POLICY IF EXISTS "Public can read patient avatars"        ON storage.objects;

-- 2. Drop triggers ---------------------------------------------------
DROP TRIGGER IF EXISTS profiles_set_updated_at  ON public.profiles;
DROP TRIGGER IF EXISTS patients_set_updated_at  ON public.patients;
DROP TRIGGER IF EXISTS providers_set_updated_at ON public.providers;
DROP TRIGGER IF EXISTS user_mpin_set_updated_at ON public.user_mpin;
DROP TRIGGER IF EXISTS patient_moods_set_updated_at ON public.patient_moods;
DROP TRIGGER IF EXISTS wellness_checkins_set_updated_at ON public.wellness_checkins;
DROP FUNCTION IF EXISTS public.touch_updated_at();

-- 3. Drop tables (CASCADE removes policies + dependents) -------------
DROP TABLE IF EXISTS public.mental_health_clinics CASCADE;
DROP TABLE IF EXISTS public.wellness_checkins      CASCADE;
DROP TABLE IF EXISTS public.patient_moods          CASCADE;
DROP TABLE IF EXISTS public.otp_verifications     CASCADE;
DROP TABLE IF EXISTS public.user_mpin             CASCADE;
DROP TABLE IF EXISTS public.provider_documents    CASCADE;
DROP TABLE IF EXISTS public.providers             CASCADE;
DROP TABLE IF EXISTS public.patients              CASCADE;
DROP TABLE IF EXISTS public.profiles              CASCADE;

-- 4. Reminder --------------------------------------------------------
-- Remove storage buckets created by schema.sql (if present).
DELETE FROM storage.buckets WHERE id IN ('provider_documents', 'patient_avatars');
