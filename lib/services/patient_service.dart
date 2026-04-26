import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:brain_anchor/services/supabase_config.dart';

class PatientService {
  final _supabase = SupabaseConfig.client;

  /// Creates a patient profile in 'profiles' and 'patients' tables
  Future<void> createPatientProfile({
    required String userId,
    required String phoneNumber,
    required String firstName,
    String? middleName,
    required String lastName,
    required String nickname,
    String? suffix,
    required DateTime birthday,
    required String sexAssignedAtBirth,
    String? genderIdentity,
    String? email,
  }) async {
    // 1. Insert into profiles (role = patient)
    await _supabase.from('profiles').upsert({
      'id': userId,
      'role': 'patient',
    });

    // 2. Insert into patients
    await _supabase.from('patients').upsert({
      'id': userId,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'nickname': nickname,
      'suffix': suffix,
      'birthday': birthday.toIso8601String().split('T')[0], // YYYY-MM-DD
      'sex_assigned_at_birth': sexAssignedAtBirth,
      'gender_identity': genderIdentity,
      'email': email,
    });
  }

  /// Hashes the MPIN and saves it to 'user_mpin' table
  Future<void> saveMpin({
    required String userId,
    required String mpin,
  }) async {
    final hashedMpin = _hashMpin(mpin);
    
    await _supabase.from('user_mpin').upsert({
      'user_id': userId,
      'hashed_mpin': hashedMpin,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Verifies if the provided MPIN matches the saved hash
  Future<bool> verifyMpin({
    required String userId,
    required String mpin,
  }) async {
    final hashedMpin = _hashMpin(mpin);

    try {
      final response = await _supabase
          .from('user_mpin')
          .select('hashed_mpin')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return false;
      return response['hashed_mpin'] == hashedMpin;
    } catch (e) {
      return false;
    }
  }

  /// Helper to hash MPIN using SHA-256
  String _hashMpin(String mpin) {
    final bytes = utf8.encode(mpin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
