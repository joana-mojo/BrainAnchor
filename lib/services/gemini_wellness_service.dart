import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiWellnessResult {
  final String riskLevel;
  final String summary;
  final List<String> suggestions;
  final String reminder;

  const GeminiWellnessResult({
    required this.riskLevel,
    required this.summary,
    required this.suggestions,
    required this.reminder,
  });
}

class GeminiWellnessService {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  final http.Client _httpClient;

  GeminiWellnessService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<GeminiWellnessResult> generateRelaxationSuggestions({
    required String mood,
    required String stress,
    required String sleep,
    required String energy,
    required String emotion,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY in .env');
    }

    final prompt = '''
You are a mental wellness reflection assistant inside a healthcare app.

Your role is to analyze the user's wellness check-in answers and generate a safe, gentle conclusion and suggestions.

You are NOT allowed to diagnose, predict, or confirm any mental health condition.

Analyze the answers based on the actual meaning of the user's responses. Do not assume distress if the answers are positive.

INPUT DATA:
Mood: $mood
Stress Level: $stress/10
Sleep Quality: $sleep
Energy Level: $energy
Emotional State: $emotion

ANALYSIS RULES:
1. If mood is positive, stress is low, sleep is good, energy is high, and emotional state is calm:
   Conclusion must be positive.
2. If mood is neutral, stress is moderate, sleep is light/interrupted, or energy is moderate:
   Conclusion should be balanced.
3. If mood is sad/stressed, stress is high, sleep is poor, energy is low, or emotional state includes anxiety/sadness/overwhelm:
   Conclusion should mention emotional strain gently.
4. If user mentions self-harm, suicide, hopelessness, or danger:
   Do not give normal suggestions. Provide crisis support immediately.
5. Never contradict the user’s answers.

OUTPUT FORMAT:
Return only valid JSON:
{
  "riskLevel": "low | moderate | high | crisis",
  "conclusion": "Short gentle conclusion based on the user's actual answers.",
  "suggestions": ["Suggestion 1", "Suggestion 2", "Suggestion 3"],
  "disclaimer": "This is a wellness reflection only and not a medical diagnosis."
}
''';

    final response = await _httpClient
        .post(
          Uri.parse('$_endpoint?key=$apiKey'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.6,
              'maxOutputTokens': 320,
              'responseMimeType': 'application/json',
            }
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Gemini returned empty content');
    }

    final text = (parts.first['text'] as String? ?? '').trim();
    if (text.isEmpty) throw Exception('Gemini returned empty text');

    try {
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      final risk = (parsed['riskLevel'] as String? ?? 'moderate').trim().toLowerCase();
      final conclusion = (parsed['conclusion'] as String? ?? '').trim();
      final suggestionsRaw = parsed['suggestions'] as List?;
      final disclaimer = (parsed['disclaimer'] as String? ?? '').trim();

      final suggestions = (suggestionsRaw ?? const [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList();

      return GeminiWellnessResult(
        riskLevel: ['low', 'moderate', 'high', 'crisis'].contains(risk)
            ? risk
            : 'moderate',
        summary: conclusion.isNotEmpty
            ? conclusion
            : _fallbackResult(mood: mood, stress: stress, sleep: sleep, energy: energy, emotion: emotion).summary,
        suggestions: suggestions.isNotEmpty
            ? suggestions
            : _fallbackResult(mood: mood, stress: stress, sleep: sleep, energy: energy, emotion: emotion).suggestions,
        reminder: disclaimer.isNotEmpty
            ? disclaimer
            : 'This is a wellness reflection only and not a medical diagnosis.',
      );
    } catch (_) {
      return _fallbackResult(
        mood: mood,
        stress: stress,
        sleep: sleep,
        energy: energy,
        emotion: emotion,
      );
    }
  }

  GeminiWellnessResult _fallbackResult({
    required String mood,
    required String stress,
    required String sleep,
    required String energy,
    required String emotion,
  }) {
    final moodL = mood.toLowerCase();
    final sleepL = sleep.toLowerCase();
    final energyL = energy.toLowerCase();
    final emotionL = emotion.toLowerCase();
    final stressInt = int.tryParse(stress) ?? 5;

    final crisis = emotionL.contains('suicide') ||
        emotionL.contains('self-harm') ||
        emotionL.contains('hopeless') ||
        emotionL.contains('danger');

    if (crisis) {
      return const GeminiWellnessResult(
        riskLevel: 'crisis',
        summary: 'You may be in severe emotional distress right now and immediate support is important.',
        suggestions: [
          'Please contact emergency services or a crisis hotline immediately.',
          'Reach out to a trusted person and stay with them while you seek help.',
          'If possible, avoid staying alone until support is with you.',
        ],
        reminder: 'This is a wellness reflection only and not a medical diagnosis.',
      );
    }

    final positiveMood = moodL.contains('great') || moodL.contains('good') || moodL.contains('calm');
    final lowStress = stressInt <= 3;
    final goodSleep = sleepL.contains('restful') || sleepL.contains('good');
    final highEnergy = energyL.contains('high');
    final calmEmotion = emotionL.contains('calm') || emotionL.contains('none');

    if (positiveMood && lowStress && goodSleep && highEnergy && calmEmotion) {
      return const GeminiWellnessResult(
        riskLevel: 'low',
        summary: 'You seem calm, rested, and emotionally steady today.',
        suggestions: [
          'Keep your current routine and continue checking in with your mood daily.',
          'Try a short gratitude note to reinforce what is helping you feel well.',
          'Use a brief breathing pause to maintain your calm through the day.',
        ],
        reminder: 'This is a wellness reflection only and not a medical diagnosis.',
      );
    }

    final highRisk = moodL.contains('sad') ||
        moodL.contains('stressed') ||
        stressInt >= 8 ||
        sleepL.contains('poor') ||
        sleepL.contains('interrupted') ||
        energyL.contains('low') ||
        emotionL.contains('anxiety') ||
        emotionL.contains('sadness') ||
        emotionL.contains('overwhelm');

    if (highRisk) {
      return const GeminiWellnessResult(
        riskLevel: 'high',
        summary: 'You may be feeling emotionally tired or overwhelmed today.',
        suggestions: [
          'Try a grounding pause now: name 5 things you can see, 4 you can feel, and breathe slowly.',
          'Consider booking a consultation or reaching out to a trusted professional for support.',
          'Prioritize rest and hydration, and reduce non-essential tasks for today.',
        ],
        reminder: 'This is a wellness reflection only and not a medical diagnosis.',
      );
    }

    return const GeminiWellnessResult(
      riskLevel: 'moderate',
      summary: 'You may be managing okay, and a bit of rest and reflection could still help.',
      suggestions: [
        'Take a short guided relaxation break to reset your mind and body.',
        'Journal a few lines about what is helping and what is draining your energy.',
        'Talk with someone you trust if your stress builds later in the day.',
      ],
      reminder: 'This is a wellness reflection only and not a medical diagnosis.',
    );
  }
}
