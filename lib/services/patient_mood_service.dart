import 'package:brain_anchor/services/supabase_config.dart';
import 'package:flutter/foundation.dart';

class PatientMoodService {
  final _supabase = SupabaseConfig.client;
  static final ValueNotifier<PatientMoodEntry?> todayMoodNotifier =
      ValueNotifier<PatientMoodEntry?>(null);

  Future<PatientMoodEntry?> getTodayMood(String userId) async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day)
        .toIso8601String()
        .split('T')
        .first;

    final row = await _supabase
        .from('patient_moods')
        .select(
          'id, user_id, mood_label, mood_score, note, entry_date, source, created_at, updated_at',
        )
        .eq('user_id', userId)
        .eq('entry_date', dateOnly)
        .maybeSingle();

    if (row == null) return null;
    return PatientMoodEntry.fromMap(row);
  }

  Future<List<PatientMoodEntry>> getMoodEntries(
    String userId, {
    int limit = 30,
  }) async {
    final rows = await _supabase
        .from('patient_moods')
        .select(
          'id, user_id, mood_label, mood_score, note, entry_date, source, created_at, updated_at',
        )
        .eq('user_id', userId)
        .order('entry_date', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((row) => PatientMoodEntry.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertTodayMood({
    required String userId,
    required String moodLabel,
    required int moodScore,
    String? note,
    String source = 'home',
  }) async {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day)
        .toIso8601String()
        .split('T')
        .first;

    await _supabase.from('patient_moods').upsert({
      'user_id': userId,
      'entry_date': dateOnly,
      'mood_label': moodLabel,
      'mood_score': moodScore,
      'note': (note ?? '').trim().isEmpty ? null : note!.trim(),
      'source': source,
      'updated_at': now.toIso8601String(),
    }, onConflict: 'user_id,entry_date');

    todayMoodNotifier.value = PatientMoodEntry(
      id: '',
      userId: userId,
      moodLabel: moodLabel,
      moodScore: moodScore,
      note: (note ?? '').trim().isEmpty ? null : note!.trim(),
      entryDate: DateTime(now.year, now.month, now.day),
      source: source,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class PatientMoodEntry {
  final String id;
  final String userId;
  final String moodLabel;
  final int moodScore;
  final String? note;
  final DateTime entryDate;
  final String source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientMoodEntry({
    required this.id,
    required this.userId,
    required this.moodLabel,
    required this.moodScore,
    required this.note,
    required this.entryDate,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientMoodEntry.fromMap(Map<String, dynamic> map) {
    return PatientMoodEntry(
      id: (map['id'] as String?) ?? '',
      userId: (map['user_id'] as String?) ?? '',
      moodLabel: (map['mood_label'] as String?) ?? 'Okay',
      moodScore: (map['mood_score'] as num?)?.toInt() ?? 3,
      note: (map['note'] as String?)?.trim(),
      entryDate: DateTime.tryParse((map['entry_date'] as String?) ?? '') ??
          DateTime.now(),
      source: (map['source'] as String?) ?? 'home',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((map['updated_at'] as String?) ?? ''),
    );
  }
}
