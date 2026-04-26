import 'package:brain_anchor/services/supabase_config.dart';

class ProviderService {
  final _supabase = SupabaseConfig.client;

  /// Creates a provider profile in 'profiles' and 'providers' tables
  Future<void> createProviderProfile({
    required String userId,
    required String firstName,
    String? middleName,
    required String lastName,
    String? suffix,
    required DateTime birthday,
    required String gender,
    required String email,
    required String licenseNumber,
    required String specialization,
    required int yearsOfExperience,
    String? verificationFileUrl,
  }) async {
    // 1. Insert into profiles (role = provider)
    await _supabase.from('profiles').upsert({
      'id': userId,
      'role': 'provider',
    });

    // 2. Insert into providers
    await _supabase.from('providers').upsert({
      'id': userId,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'suffix': suffix,
      'birthday': birthday.toIso8601String().split('T')[0],
      'gender': gender,
      'email': email,
      'license_number': licenseNumber,
      'specialization': specialization,
      'years_of_experience': yearsOfExperience,
      'approval_status': 'pending', // default status
      'verification_file_url': verificationFileUrl,
    });
  }

  /// Fetches the approval status of the provider
  Future<String?> getProviderStatus(String userId) async {
    try {
      final response = await _supabase
          .from('providers')
          .select('approval_status')
          .eq('id', userId)
          .maybeSingle();
      
      return response?['approval_status'] as String?;
    } catch (e) {
      return null;
    }
  }
}
