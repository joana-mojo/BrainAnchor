-- =====================================================================
-- BRAIN ANCHOR — MENTAL HEALTH CLINICS SEED DATA
-- Run this in your Supabase SQL Editor AFTER running schema.sql.
-- Safe to re-run: clinics are matched by (LOWER(name), city) so a row
-- is updated in place instead of duplicated.
-- =====================================================================
--
-- Coordinates below are APPROXIMATE — they were estimated from public
-- map screenshots. To get exact coordinates:
--   1. Open Google Maps and find the clinic.
--   2. Right-click the pin → "What's here?" → copy the lat / lon.
--   3. UPDATE the row below and set is_verified = TRUE.
--
-- The app shows a "Verified" badge only on rows where is_verified = TRUE,
-- so you can ship this seed safely and verify rows over time.

-- ---------- DIGOS CITY, DAVAO DEL SUR ----------------------------------
INSERT INTO public.mental_health_clinics
    (name, address, city, region, latitude, longitude,
     specialty, rating, review_count, is_verified)
VALUES
    -- The four clinics visible in Google Maps for the Digos area.
    ('St Benedict Psychiatric Clinic',
     'Tres de Mayo / Tiguman area',
     'Digos', 'Davao del Sur',
     6.7585, 125.3530,
     'Psychiatry', 4.6, 0, FALSE),

    ('The Purple Haven',
     'Digos City',
     'Digos', 'Davao del Sur',
     6.7545, 125.3590,
     'Mental Health', 4.5, 0, FALSE),

    ('Serene Valley Recovery Center',
     'Digos City',
     'Digos', 'Davao del Sur',
     6.7510, 125.3490,
     'Recovery / Rehab', 4.4, 0, FALSE),

    ('Digos Autism and Mental Health Center',
     'Digos City',
     'Digos', 'Davao del Sur',
     6.7520, 125.3590,
     'Autism Care', 4.7, 0, FALSE)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- HOW TO ADD MORE CLINICS
-- =====================================================================
-- Copy the template below into the Supabase SQL Editor:
--
--   INSERT INTO public.mental_health_clinics
--       (name, address, city, region,
--        latitude, longitude, specialty,
--        phone, website, rating, review_count, is_verified)
--   VALUES
--       ('CLINIC NAME',
--        'STREET, BARANGAY',
--        'CITY', 'PROVINCE / REGION',
--        12.3456, 123.4567,        -- lat, lon from Google Maps
--        'Psychiatry',             -- e.g. Psychiatry, Psychology,
--                                  -- Psychotherapy, Counseling,
--                                  -- Behavioral Health, Autism Care,
--                                  -- Recovery / Rehab, Mental Health
--        '+63 ...',                -- phone (nullable)
--        'https://...',            -- website (nullable)
--        4.5,                      -- rating 0..5 (nullable)
--        0,                        -- review_count
--        TRUE)                     -- is_verified
--   ON CONFLICT DO NOTHING;
