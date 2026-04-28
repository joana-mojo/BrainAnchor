import 'package:brain_anchor/services/supabase_config.dart';

class ProviderDirectoryService {
  final _supabase = SupabaseConfig.client;

  Future<List<ApprovedProvider>> fetchApprovedProviders() async {
    final rows = await _supabase
        .from('providers')
        .select(
          'id, first_name, middle_name, last_name, suffix, specialization, years_of_experience, approval_status',
        )
        .eq('approval_status', 'approved')
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => ApprovedProvider.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}

class ApprovedProvider {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? suffix;
  final String specialization;
  final int yearsOfExperience;

  const ApprovedProvider({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.suffix,
    required this.specialization,
    required this.yearsOfExperience,
  });

  factory ApprovedProvider.fromMap(Map<String, dynamic> map) {
    return ApprovedProvider(
      id: map['id'] as String? ?? '',
      firstName: map['first_name'] as String? ?? '',
      middleName: map['middle_name'] as String?,
      lastName: map['last_name'] as String? ?? '',
      suffix: map['suffix'] as String?,
      specialization: map['specialization'] as String? ?? 'Mental Health Provider',
      yearsOfExperience: (map['years_of_experience'] as num?)?.toInt() ?? 0,
    );
  }

  String get displayName {
    final buffer = StringBuffer('Dr. $firstName');
    if ((middleName ?? '').trim().isNotEmpty) {
      buffer.write(' ${middleName!.trim()}');
    }
    if (lastName.trim().isNotEmpty) {
      buffer.write(' $lastName');
    }
    if ((suffix ?? '').trim().isNotEmpty) {
      buffer.write(', ${suffix!.trim()}');
    }
    return buffer.toString();
  }
}
