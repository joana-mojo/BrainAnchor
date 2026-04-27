import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:brain_anchor/services/supabase_config.dart';

class PatientService {
  final _supabase = SupabaseConfig.client;

  String _sha256Hex(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  /// Creates a patient profile in 'profiles' and 'patients' tables.
  ///
  /// Either [phoneNumber] or [email] should be set so the patient can be
  /// contacted. Both columns are nullable in the schema.
  Future<void> createPatientProfile({
    required String userId,
    String? phoneNumber,
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
    await _supabase.from('profiles').upsert({
      'id': userId,
      'role': 'patient',
    });

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

  /// Stores the patient's hashed MPIN and recovery password hash in
  /// `user_mpin`. Both values are SHA-256 hashes — the plain values never
  /// touch the database.
  ///
  /// The recovery password hash is later checked by the `reset_patient_mpin`
  /// RPC during the "Forgot MPIN" flow.
  Future<void> saveMpinAndRecovery({
    required String userId,
    required String mpin,
    required String recoveryPassword,
  }) async {
    await _supabase.from('user_mpin').upsert({
      'user_id': userId,
      'hashed_mpin': _sha256Hex(mpin),
      'recovery_password_hash': _sha256Hex(recoveryPassword),
      'failed_attempts': 0,
      'locked_until': null,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Returns `true` if a patient profile row exists for [userId].
  Future<bool> hasPatientProfile(String userId) async {
    try {
      final response = await _supabase
          .from('patients')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return response != null;
    } catch (_) {
      return false;
    }
  }
}
