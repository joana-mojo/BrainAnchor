import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:brain_anchor/services/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      'avatar_url': null,
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

  /// Returns the patient's preferred display name: their nickname if they
  /// set one during signup, otherwise their first name. Returns `null` if
  /// no patient row exists yet (e.g. user is mid-signup).
  Future<String?> getPatientDisplayName(String userId) async {
    try {
      final row = await _supabase
          .from('patients')
          .select('nickname, first_name')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return null;

      final nickname = (row['nickname'] as String?)?.trim();
      if (nickname != null && nickname.isNotEmpty) return nickname;

      final firstName = (row['first_name'] as String?)?.trim();
      if (firstName != null && firstName.isNotEmpty) return firstName;

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches patient profile fields used in UI headers/profile pages.
  Future<PatientProfileData?> getPatientProfileData(String userId) async {
    try {
      final row = await _supabase
          .from('patients')
          .select(
            'first_name, middle_name, last_name, suffix, nickname, email, avatar_url',
          )
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return null;
      return PatientProfileData.fromMap(row);
    } catch (_) {
      return null;
    }
  }

  /// Uploads a patient avatar image to Storage and saves the public URL
  /// in `patients.avatar_url`.
  Future<String> uploadPatientAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final safeExt = fileExtension.trim().toLowerCase().replaceAll('.', '');
    final ext = safeExt.isEmpty ? 'jpg' : safeExt;
    final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await _supabase.storage.from('patient_avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
    } on StorageException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('bucket not found') || e.statusCode == '404') {
        throw Exception(
          'Storage bucket "patient_avatars" is missing. '
          'Create it in Supabase Storage first.',
        );
      }
      rethrow;
    }

    final publicUrl = _supabase.storage.from('patient_avatars').getPublicUrl(path);
    await _supabase.from('patients').update({'avatar_url': publicUrl}).eq('id', userId);

    return publicUrl;
  }

  /// Clears the stored avatar URL so UI falls back to initials.
  Future<void> clearPatientAvatar(String userId) async {
    await _supabase.from('patients').update({'avatar_url': null}).eq('id', userId);
  }
}

class PatientProfileData {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? suffix;
  final String? nickname;
  final String? email;
  final String? avatarUrl;

  const PatientProfileData({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.suffix,
    required this.nickname,
    required this.email,
    required this.avatarUrl,
  });

  factory PatientProfileData.fromMap(Map<String, dynamic> map) {
    return PatientProfileData(
      firstName: (map['first_name'] as String? ?? '').trim(),
      middleName: (map['middle_name'] as String?)?.trim(),
      lastName: (map['last_name'] as String? ?? '').trim(),
      suffix: (map['suffix'] as String?)?.trim(),
      nickname: (map['nickname'] as String?)?.trim(),
      email: (map['email'] as String?)?.trim(),
      avatarUrl: (map['avatar_url'] as String?)?.trim(),
    );
  }

  String get displayName {
    final nick = nickname?.trim() ?? '';
    if (nick.isNotEmpty) return nick;
    return firstName;
  }

  String get fullName {
    final parts = <String>[
      firstName,
      if ((middleName ?? '').isNotEmpty) middleName!,
      lastName,
      if ((suffix ?? '').isNotEmpty) suffix!,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(' ').trim();
  }
}
