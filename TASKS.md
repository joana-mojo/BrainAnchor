# Brain Anchor — Supabase Auth & Registration Tasks

## Relevant Files

- `lib/services/supabase_config.dart` - Initializes Supabase connection.
- `lib/services/auth_service.dart` - Handles OTP, login, Google sign-in, and sessions.
- `lib/services/patient_service.dart` - Saves and retrieves patient data, MPIN.
- `lib/services/provider_service.dart` - Saves provider data and approval status.
- `lib/services/storage_service.dart` - Handles license/ID document upload.
- `lib/screens/auth/signup/step1_mobile_screen.dart` - Patient phone number input screen.
- `lib/screens/auth/signup/step2_otp_screen.dart` - OTP verification screen (signup).
- `lib/screens/auth/signup/step3_personal_info_screen.dart` - Patient personal information form.
- `lib/screens/auth/signup/step4_create_mpin_screen.dart` - MPIN creation screen.
- `lib/screens/auth/signup/step5_confirm_mpin_screen.dart` - MPIN confirmation + save.
- `lib/screens/auth/login_screen.dart` - Combined login (patient phone / provider email+password).
- `lib/screens/auth/login_otp_screen.dart` - OTP screen for login flow.
- `lib/screens/auth/login_mpin_screen.dart` - MPIN login screen after OTP.
- `lib/screens/auth/doctor_signup_screen.dart` - Provider account creation (email+password).
- `lib/screens/auth/doctor_complete_profile_screen.dart` - Provider professional profile + license upload.
- `lib/screens/auth/role_redirect_screen.dart` - Redirects users based on role and provider approval status.
- `supabase/schema.sql` - SQL commands for creating Supabase tables and policies.

## Notes

- Plain passwords are never stored; Supabase Auth handles them.
- MPIN is hashed with SHA-256 before storing in `user_mpin`.
- Provider accounts default to `approval_status = 'pending'` until an admin approves.
- Compliant with the Philippine Data Privacy Act (RA 10173) - explicit consent checkbox.

## Tasks

- [x] 0.0 Create feature branch
  - [x] 0.1 Create and checkout `feature/supabase-auth-registration`

- [x] 1.0 Set up Supabase authentication and database connection
  - [x] 1.1 Supabase project provisioned (URL/key in `.env`).
  - [x] 1.2 Supabase URL and anon key loaded from `.env` in `main.dart`.
  - [x] 1.3 Required tables: `profiles`, `patients`, `providers`, `user_mpin`, `otp_verifications`, `provider_documents`.
  - [x] 1.4 Row Level Security policies enabled on all auth/profile tables.
  - [x] 1.5 `lib/services/supabase_config.dart` exposes `SupabaseConfig.client`.

- [x] 2.0 Implement patient registration flow
  - [x] 2.1 Phone number input screen (`step1_mobile_screen.dart`).
  - [x] 2.2 Philippine mobile number validation (10 digits after `+63`, starts with 9).
  - [x] 2.3 OTP verification screen (`step2_otp_screen.dart`).
  - [x] 2.4 Patient personal information form (`step3_personal_info_screen.dart`).
  - [x] 2.5 Terms of Use & Privacy Policy consent checkbox.
  - [x] 2.6 Save patient data to `profiles` and `patients` (in `step5_confirm_mpin_screen.dart`).

- [x] 3.0 Implement provider registration and verification flow
  - [x] 3.1 Provider registration form (`doctor_signup_screen.dart`).
  - [x] 3.2 Required fields collected across signup + complete profile screens.
  - [x] 3.3 Password confirmation validation in `doctor_signup_screen.dart`.
  - [x] 3.4 ID/license document upload in `doctor_complete_profile_screen.dart`.
  - [x] 3.5 Document uploaded to Supabase Storage `provider_documents` bucket.
  - [x] 3.6 Provider data saved to `profiles`, `providers`, `provider_documents`.
  - [x] 3.7 Provider `approval_status` defaults to `pending`.

- [x] 4.0 Implement login, OTP, Google sign-in, and MPIN access
  - [x] 4.1 Patient phone login (`login_screen.dart` -> `login_otp_screen.dart`).
  - [x] 4.2 Provider email/password login (`login_screen.dart`).
  - [x] 4.3 Google sign-in entry point (Supabase OAuth, requires GCP client IDs).
  - [x] 4.4 MPIN creation screen.
  - [x] 4.5 MPIN confirmation screen.
  - [x] 4.6 MPIN hashed (SHA-256) before saving to `user_mpin`.
  - [x] 4.7 MPIN login screen after successful OTP login.
  - [x] 4.8 MPIN validated before granting dashboard access.

- [x] 5.0 Apply validation, security, and role-based redirection
  - [x] 5.1 `RoleRedirectScreen` checks role from `profiles`.
  - [x] 5.2 Patients are redirected to `PatientMainScreen`.
  - [x] 5.3 Approved providers are redirected to `DoctorMainScreen`.
  - [x] 5.4 Pending providers see a pending approval screen.
  - [x] 5.5 Rejected providers see a rejection screen.
  - [x] 5.6 Loading states + error messages throughout the flow.
  - [ ] 5.7 Manual end-to-end test of registration, login, OTP, MPIN, upload, redirection.
        (Code is wired up; run the app against a Supabase project that has SMS provider configured to test.)
