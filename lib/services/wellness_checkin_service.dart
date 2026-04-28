import 'dart:convert';

import 'package:brain_anchor/services/supabase_config.dart';

class WellnessCheckinService {
  final _supabase = SupabaseConfig.client;

  Future<WellnessCheckin?> getTodayCheckin(String userId) async {
    final today = _dateOnly(DateTime.now());
    final row = await _supabase
        .from('wellness_checkins')
        .select(
          'id, user_id, checkin_date, answers, ai_summary, ai_suggestions, ai_reminder, risk_level, created_at, updated_at',
        )
        .eq('user_id', userId)
        .eq('checkin_date', today)
        .maybeSingle();
    if (row == null) return null;
    return WellnessCheckin.fromMap(row);
  }

  Future<List<WellnessCheckin>> getHistory(String userId, {int limit = 30}) async {
    final rows = await _supabase
        .from('wellness_checkins')
        .select(
          'id, user_id, checkin_date, answers, ai_summary, ai_suggestions, ai_reminder, risk_level, created_at, updated_at',
        )
        .eq('user_id', userId)
        .order('checkin_date', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => WellnessCheckin.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertTodayCheckin({
    required String userId,
    required Map<String, String> answers,
    required String aiSummary,
    required List<String> aiSuggestions,
    required String aiReminder,
    required String riskLevel,
  }) async {
    final now = DateTime.now();
    await _supabase.from('wellness_checkins').upsert({
      'user_id': userId,
      'checkin_date': _dateOnly(now),
      'answers': answers,
      'ai_summary': aiSummary,
      'ai_suggestions': aiSuggestions,
      'ai_reminder': aiReminder,
      'risk_level': riskLevel,
      'updated_at': now.toIso8601String(),
    }, onConflict: 'user_id,checkin_date');
  }

  Future<void> deleteCheckin(String id) async {
    await _supabase.from('wellness_checkins').delete().eq('id', id);
  }

  String _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day).toIso8601String().split('T').first;
}

class WellnessCheckin {
  final String id;
  final String userId;
  final DateTime checkinDate;
  final Map<String, String> answers;
  final String aiSummary;
  final List<String> aiSuggestions;
  final String aiReminder;
  final String riskLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WellnessCheckin({
    required this.id,
    required this.userId,
    required this.checkinDate,
    required this.answers,
    required this.aiSummary,
    required this.aiSuggestions,
    required this.aiReminder,
    required this.riskLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WellnessCheckin.fromMap(Map<String, dynamic> map) {
    final rawAnswers = map['answers'];
    final rawSuggestions = map['ai_suggestions'];
    return WellnessCheckin(
      id: (map['id'] as String?) ?? '',
      userId: (map['user_id'] as String?) ?? '',
      checkinDate: DateTime.tryParse((map['checkin_date'] as String?) ?? '') ??
          DateTime.now(),
      answers: rawAnswers is Map
          ? rawAnswers.map(
              (k, v) => MapEntry(k.toString(), (v ?? '').toString()),
            )
          : const {},
      aiSummary: (map['ai_summary'] as String?) ?? '',
      aiSuggestions: _parseSuggestions(rawSuggestions),
      aiReminder: (map['ai_reminder'] as String?) ?? '',
      riskLevel: (map['risk_level'] as String?) ?? 'low',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((map['updated_at'] as String?) ?? ''),
    );
  }

  static List<String> _parseSuggestions(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => e.toString()).toList();
    final str = value.toString().trim();
    if (str.isEmpty) return const [];
    try {
      final decoded = jsonDecode(str);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
    return const [];
  }
}
