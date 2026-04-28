import 'package:flutter/material.dart';
import '../../services/gemini_wellness_service.dart';
import '../../services/supabase_config.dart';
import '../../services/wellness_checkin_service.dart';
import 'progress_tracking_screen.dart';
import '../../theme/app_theme.dart';

class PatientAiCheckerScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final VoidCallback? onOpenConsults;
  const PatientAiCheckerScreen({
    super.key,
    this.onBackToHome,
    this.onOpenConsults,
  });

  @override
  State<PatientAiCheckerScreen> createState() => _PatientAiCheckerScreenState();
}

class _PatientAiCheckerScreenState extends State<PatientAiCheckerScreen> {
  final _scroll = ScrollController();
  final _gemini = GeminiWellnessService();
  final _historyService = WellnessCheckinService();
  final List<_Msg> _messages = [];
  final Map<String, String> _answers = {};
  List<String> _aiSuggestions = const [];
  String _aiSummary =
      'Based on your responses, it seems like you may be feeling overwhelmed and emotionally drained.';
  String _aiReminder = 'This is not a diagnosis.';
  bool _aiLoading = false;
  String? _aiError;

  int _step = 0;
  bool _typing = false;
  bool _done = false;
  bool _distress = false;
  bool _historyLoading = false;
  double _stressValue = 5;
  String? _selectedOption;

  static const _questions = <(String, String)>[
    ('mood', 'How would you describe your mood today?'),
    ('stress', 'On a scale of 1 to 10, how intense has your stress felt today?\n(1 = very low, 10 = very high)'),
    ('sleep', 'How has your sleep been recently?\n(e.g. restful, light, or interrupted)'),
    ('energy', 'How is your energy level today?\n(low, moderate, or high)'),
    ('emotion', 'Have you been feeling anxiety, sadness, or overwhelm lately?'),
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      _Msg.bot(
        "Hi, I’m here to help you check in with how you’re feeling today.\n\n"
        "This is a wellness check-in, not a diagnosis,\n"
        "but it can help us reflect together.\n\n"
        "💜  How would you describe your mood today?",
      ),
    );
    _loadTodayCheckin();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadTodayCheckin() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    try {
      final today = await _historyService.getTodayCheckin(user.id);
      if (today == null || !mounted) return;

      setState(() {
        _answers
          ..clear()
          ..addAll(today.answers);
        _aiSummary = today.aiSummary;
        _aiSuggestions = today.aiSuggestions;
        _aiReminder = today.aiReminder;
        _distress = today.riskLevel == 'high' || today.riskLevel == 'crisis';
        _done = true;
        _step = _questions.length;
        _messages
          ..clear()
          ..add(
            _Msg.bot(
              "You already completed today's wellness check-in.\n"
              "You can view history or delete today's check-in to create a new one.",
            ),
          );
      });
    } catch (_) {}
  }

  void _submitQuickResponse(String value) {
    if (value.isEmpty || _typing || _done) return;
    setState(() {
      _messages.add(_Msg.user(value));
      _selectedOption = value;
    });
    _scrollToBottom();
    _next(value);
  }

  void _next(String input) {
    final lowered = input.toLowerCase();
    if (lowered.contains('suicide') ||
        lowered.contains('self-harm') ||
        lowered.contains('hopeless') ||
        lowered.contains('want to disappear')) {
      setState(() {
        _done = true;
        _distress = true;
        _messages.add(
          _Msg.bot(
            "I’m really sorry you’re feeling this way.\n"
            "You are not alone.\n\n"
            "Please contact the NCMH Crisis Hotline at 1553 right now.",
          ),
        );
      });
      _scrollToBottom();
      return;
    }

    if (_done) return;

    _answers[_questions[_step].$1] = input;
    _step++;

    if (_step >= _questions.length) {
      final stress = int.tryParse(_answers['stress'] ?? '');
      final mood = (_answers['mood'] ?? '').toLowerCase();
      final emotion = (_answers['emotion'] ?? '').toLowerCase();
      _distress = (stress ?? 0) >= 8 ||
          mood.contains('sad') ||
          mood.contains('drained') ||
          emotion.contains('overwhelm') ||
          emotion.contains('hopeless');
      setState(() {
        _done = true;
      });
      _loadAiSuggestions();
      _scrollToBottom();
      return;
    }

    setState(() => _typing = true);
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _messages.add(_Msg.bot(_questions[_step].$2));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadAiSuggestions() async {
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });

    try {
      final result = await _gemini.generateRelaxationSuggestions(
        mood: _answers['mood'] ?? 'Not shared',
        stress: _answers['stress'] ?? 'Not shared',
        sleep: _answers['sleep'] ?? 'Not shared',
        energy: _answers['energy'] ?? 'Not shared',
        emotion: _answers['emotion'] ?? 'Not shared',
      );

      if (!mounted) return;
      setState(() {
        _distress = result.riskLevel == 'high' || result.riskLevel == 'crisis';
        _aiSummary = result.summary;
        _aiSuggestions = result.suggestions;
        _aiReminder = result.reminder;
        _aiLoading = false;
      });
      await _saveTodayHistory();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _distress = false;
        _aiSummary =
            'You may be managing okay, and a bit of rest and reflection could still help.';
        _aiSuggestions = const [
          'Take a short guided relaxation break to reset your mind and body.',
          'Journal a few lines about what is helping and what is draining your energy.',
          'Talk with someone you trust if your stress builds later in the day.',
        ];
        _aiReminder = 'This is a wellness reflection only and not a medical diagnosis.';
        _aiError = e.toString();
        _aiLoading = false;
      });
      await _saveTodayHistory();
    }
  }

  Future<void> _saveTodayHistory() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    final risk = _distress ? 'high' : 'moderate';
    await _historyService.upsertTodayCheckin(
      userId: user.id,
      answers: Map<String, String>.from(_answers),
      aiSummary: _aiSummary,
      aiSuggestions: _aiSuggestions,
      aiReminder: _aiReminder,
      riskLevel: risk,
    );
  }

  Future<void> _openHistory() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null || _historyLoading) return;
    setState(() => _historyLoading = true);
    try {
      final rows = await _historyService.getHistory(user.id, limit: 60);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: rows.isEmpty
                  ? const Center(
                      child: Text('No wellness check-in history yet.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final date = row.checkinDate;
                        final dateLabel =
                            '${_monthShort(date.month)} ${date.day}, ${date.year}';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(dateLabel),
                            subtitle: Text(
                              row.aiSummary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                await _historyService.deleteCheckin(row.id);
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                await _loadTodayCheckin();
                                if (!mounted) return;
                                final isToday = _isSameDate(
                                  row.checkinDate,
                                  DateTime.now(),
                                );
                                if (isToday) {
                                  _resetForNewCheckin();
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  void _resetForNewCheckin() {
    setState(() {
      _messages
        ..clear()
        ..add(
          _Msg.bot(
            "Hi, I’m here to help you check in with how you’re feeling today.\n\n"
            "This is a wellness check-in, not a diagnosis,\n"
            "but it can help us reflect together.\n\n"
            "💜  How would you describe your mood today?",
          ),
        );
      _answers.clear();
      _aiSuggestions = const [];
      _aiSummary =
          'Based on your responses, it seems like you may be feeling overwhelmed and emotionally drained.';
      _aiReminder = 'This is not a diagnosis.';
      _step = 0;
      _typing = false;
      _done = false;
      _distress = false;
      _stressValue = 5;
      _selectedOption = null;
    });
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthShort(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            _header(),
            const SizedBox(height: 10),
            _subtitleBadge(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ..._messages.map(_messageRow),
                  if (_typing) _typingRow(),
                  if (_done) ...[
                    const SizedBox(height: 10),
                    _summaryCard(),
                    const SizedBox(height: 10),
                    _crisisResourcesCard(),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _quickResponsePanel(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (widget.onBackToHome != null) {
                widget.onBackToHome!.call();
                return;
              }
              Navigator.of(context).maybePop();
            },
            child: const _CircleIcon(
              icon: Icons.arrow_back_ios_new_rounded,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Wellness Check-in',
              style: TextStyle(
                fontSize: 30 / 2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2230),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: TextButton.icon(
              onPressed: _historyLoading ? null : _openHistory,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
              icon: const Icon(
                Icons.history_rounded,
                size: 14,
                color: Color(0xFF7B76D9),
              ),
              label: Text(
                _historyLoading ? 'Loading...' : 'History',
                style: const TextStyle(
                  color: Color(0xFF7B76D9),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subtitleBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF7A73D8)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Supportive check-in only. This tool does not diagnose.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF7A73D8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageRow(_Msg m) {
    final isBot = m.bot;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            const _BotAvatar(),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : const Color(0xFF6A8CE5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.text,
                    style: TextStyle(
                      color: isBot ? AppTheme.textPrimary : Colors.white,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m.time,
                    style: TextStyle(
                      color: isBot
                          ? AppTheme.textSecondary.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingRow() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _BotAvatar(),
          SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Text(
                '...',
                style: TextStyle(fontSize: 24, color: Color(0xFFA8A9B4), height: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF1EDFF), Color(0xFFE6F1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFFFFE6F1),
                child: Text('💗', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thank you for sharing.',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 28 / 2),
                    ),
                    const SizedBox(height: 4),
                    Text(_aiSummary, style: const TextStyle(height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB8C5FF), Color(0xFF96A7F5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Text('🫂', style: TextStyle(fontSize: 30)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('☀️  You’re not alone.', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text(
                  'Taking small steps can make a big difference.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text('Suggested next steps for you', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (_aiLoading)
            const Text(
              'Generating AI relaxation suggestions...',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          if (!_aiLoading && _aiSuggestions.isNotEmpty) ...[
            ..._aiSuggestions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $item',
                  style: const TextStyle(fontSize: 12.5, height: 1.35),
                ),
              ),
            ),
            if (_aiError != null)
              const Padding(
                padding: EdgeInsets.only(top: 2, bottom: 6),
                child: Text(
                  'Using fallback suggestions.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
          ],
          if (!_aiLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _aiReminder,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionChip(
                  icon: '📖',
                  title: 'Start Mood\nJournal',
                  subtitle: 'Write and reflect\nyour feelings',
                  backgroundColor: Color(0xFFF2ECFF),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProgressTrackingScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionChip(
                  icon: '🧘',
                  title: 'Try Guided\nRelaxation',
                  subtitle: 'Calm your mind\nand breathe',
                  backgroundColor: Color(0xFFE8F7F3),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const _GuidedRelaxationScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionChip(
                  icon: '🧑‍⚕️',
                  title: 'Talk to a\nProfessional',
                  subtitle: 'Connect with a\nlicensed doctor',
                  backgroundColor: const Color(0xFFFFF4E4),
                  highlighted: _distress,
                  onTap: () {
                    if (widget.onOpenConsults != null) {
                      widget.onOpenConsults!.call();
                      return;
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _crisisResourcesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE77380)),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('If you’re in crisis or need immediate help', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text(
                  'You can contact these 24/7 support resources.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFD66B78),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('View Resources'),
          ),
        ],
      ),
    );
  }

  Widget _quickResponsePanel() {
    if (_done) return const SizedBox.shrink();
    final key = _questions[_step].$1;

    return Container(
      color: const Color(0xFFF8F8FD),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: key == 'stress' ? _stressControl() : _optionsControl(key),
        ),
      ),
    );
  }

  Widget _stressControl() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stress: ${_stressValue.round()}/10',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Slider(
          value: _stressValue,
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: (v) => setState(() => _stressValue = v),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _submitQuickResponse(_stressValue.round().toString()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B8DE3),
              foregroundColor: Colors.white,
            ),
            child: const Text('Use this response'),
          ),
        ),
      ],
    );
  }

  Widget _optionsControl(String key) {
    final options = switch (key) {
      'mood' => const ['Great', 'Good', 'Okay', 'Sad', 'Stressed'],
      'sleep' => const ['Restful', 'Light', 'Interrupted'],
      'energy' => const ['Low', 'Moderate', 'High'],
      'emotion' => const ['Anxiety', 'Sadness', 'Overwhelmed', 'Hopeless', 'Calm'],
      _ => const ['Continue'],
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (option) => ChoiceChip(
              label: Text(option),
              selected: _selectedOption == option,
              onSelected: (_) => _submitQuickResponse(option),
              selectedColor: const Color(0xFFE3ECFF),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          )
          .toList(),
    );
  }
}

class _Msg {
  final bool bot;
  final String text;
  final DateTime createdAt;

  const _Msg._(this.bot, this.text, this.createdAt);

  factory _Msg.bot(String text) => _Msg._(true, text, DateTime.now());
  factory _Msg.user(String text) => _Msg._(false, text, DateTime.now());

  String get time {
    final h = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final m = createdAt.minute.toString().padLeft(2, '0');
    final period = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const _CircleIcon({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F1F8),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size, color: Color(0xFF7A7D90)),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE9EEFF),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBBC8F8).withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.smart_toy_rounded,
            size: 16,
            color: const Color(0xFF6B7EEA),
          ),
          Positioned(
            right: 5,
            bottom: 5,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF72A9FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final bool highlighted;
  final VoidCallback? onTap;
  const _ActionChip({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
          decoration: BoxDecoration(
            color: highlighted ? const Color(0xFFFFE4EA) : backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: highlighted
                ? Border.all(color: const Color(0xFFE56A80), width: 1.6)
                : null,
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: const Color(0xFFE56A80).withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              if (highlighted)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE56A80),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Recommended',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.2)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 9.8, color: AppTheme.textSecondary, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidedRelaxationScreen extends StatelessWidget {
  const _GuidedRelaxationScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Guided Relaxation')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Take a short calming break',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              '1) Inhale for 4 seconds\n'
              '2) Hold for 2 seconds\n'
              '3) Exhale for 6 seconds\n'
              '4) Repeat for 2-3 minutes',
            ),
          ],
        ),
      ),
    );
  }
}

