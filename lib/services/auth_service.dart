import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brain_anchor/services/supabase_config.dart';

class AuthService {
  final _supabase = SupabaseConfig.client;

  /// Per-app constant prefixed before the MPIN when deriving the Supabase
  /// password. This means rainbow tables built against generic 4-digit PINs
  /// won't match the stored hashes.
  static const String _mpinPepper = 'brainanchor-mpin-v1:';

  /// Maps a 4-digit user MPIN to a 64-char SHA-256 hex string that we use
  /// as the actual Supabase password.
  ///
  /// Rationale: Supabase Auth requires a password (no built-in "PIN login").
  /// By deriving the password deterministically from the MPIN, the user
  /// only ever has to remember 4 digits, but the value sent to Supabase is
  /// long enough to satisfy any password-length requirement and isn't a
  /// trivially guessable string.
  ///
  /// Security note: the *secret entropy* is still only 4 digits (10,000
  /// combinations). Supabase's auth rate limit is the main brute-force
  /// defence here. Don't use this scheme for high-value accounts.
  static String deriveMpinPassword(String mpin) {
    final bytes = utf8.encode('$_mpinPepper$mpin');
    return sha256.convert(bytes).toString();
  }

  // --- Patient Auth (Email + MPIN) ---

  /// Signs up a new patient. The Supabase password is derived from [mpin],
  /// so logging in later only requires the email + MPIN.
  Future<AuthResponse> signUpPatientWithMpin({
    required String email,
    required String mpin,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: deriveMpinPassword(mpin),
      data: {'role': 'patient'},
    );
  }

  /// Logs a patient in using their email + MPIN.
  Future<AuthResponse> signInPatientWithMpin({
    required String email,
    required String mpin,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: deriveMpinPassword(mpin),
    );
  }

  /// Returns `true` if [email] belongs to a patient account.
  ///
  /// Calls the `patient_email_exists` RPC, which checks `auth.users` joined
  /// with `profiles.role = 'patient'`. Used by the login screen to warn
  /// the user before they type their MPIN, instead of failing later with a
  /// generic "invalid email or MPIN" error.
  Future<bool> isPatientEmailRegistered(String email) async {
    final result = await _supabase.rpc(
      'patient_email_exists',
      params: {'p_email': email.trim().toLowerCase()},
    );
    return result == true;
  }

  /// Returns `true` if [email] belongs to a provider (doctor) account.
  ///
  /// Used by the doctor login screen to show a clear warning when the
  /// email isn't registered, instead of the generic "Invalid login
  /// credentials" error you'd otherwise get after the password attempt.
  Future<bool> isProviderEmailRegistered(String email) async {
    final result = await _supabase.rpc(
      'provider_email_exists',
      params: {'p_email': email.trim().toLowerCase()},
    );
    return result == true;
  }

  /// Resets a patient's MPIN by verifying their recovery password.
  ///
  /// Calls the `reset_patient_mpin` RPC, which:
  ///   - looks up the auth user by [email],
  ///   - verifies SHA-256([recoveryPassword]) against the stored hash,
  ///   - updates the Supabase auth password to derive([newMpin]),
  ///   - updates user_mpin.hashed_mpin.
  ///
  /// Returns `true` if the reset succeeded, `false` if the email or
  /// recovery password didn't match.
  Future<bool> resetMpinWithRecoveryPassword({
    required String email,
    required String recoveryPassword,
    required String newMpin,
  }) async {
    final result = await _supabase.rpc(
      'reset_patient_mpin',
      params: {
        'p_email': email.trim().toLowerCase(),
        'p_recovery_password': recoveryPassword,
        'p_new_mpin': newMpin,
      },
    );
    return result == true;
  }

  // --- Provider Auth (Email + Password) ---

  /// Signs up a new provider with email and password.
  Future<AuthResponse> signUpProvider({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'role': 'provider'},
    );
  }

  /// Signs in a provider using email and password.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // --- Common Auth ---

  /// Starts a Supabase OAuth flow with Google.
  Future<bool> signInWithGoogle() async {
    return _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.brainanchor://login-callback/',
    );
  }

  /// Stream of auth state changes (sign-in, sign-out, token refresh).
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Signs out the current user.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Gets the current logged-in user, if any.
  User? get currentUser => _supabase.auth.currentUser;

  /// Fetches the user's role from the `profiles` table.
  Future<String?> getCurrentUserRole() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      return null;
    }
  }
}
