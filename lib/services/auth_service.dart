import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brain_anchor/services/supabase_config.dart';

class AuthService {
  final _supabase = SupabaseConfig.client;

  // --- Patient Auth (OTP) ---
  
  /// Sends an OTP to the given phone number (e.g. +639123456789)
  Future<void> signInWithOtp(String phoneNumber) async {
    await _supabase.auth.signInWithOtp(
      phone: phoneNumber,
    );
  }

  /// Verifies the OTP sent to the phone number
  Future<AuthResponse> verifyOtp(String phoneNumber, String token) async {
    return await _supabase.auth.verifyOTP(
      phone: phoneNumber,
      token: token,
      type: OtpType.sms,
    );
  }

  // --- Provider Auth (Email/Password) ---
  
  /// Signs up a new provider with email and password
  Future<AuthResponse> signUpProvider({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Signs in a provider using email and password
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
  
  /// Google Sign-In (Stubbed for now, requires GCP configuration)
  Future<AuthResponse?> signInWithGoogle() async {
    // Note: To implement this fully, you need the Google Sign In package
    // and OAuth Client IDs configured in Supabase.
    // For now, returning null or throwing unimplemented error.
    throw UnimplementedError('Google Sign-In requires GCP configuration.');
  }

  /// Signs out the current user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Gets the current logged-in user
  User? get currentUser => _supabase.auth.currentUser;

  /// Fetches the user's role from the 'profiles' table
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
