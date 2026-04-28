import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:brain_anchor/services/patient_mood_service.dart';
import 'package:brain_anchor/services/supabase_config.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  final _quickNoteController = TextEditingController();
  final _moodService = PatientMoodService();

  final List<_MoodOption> _moodOptions = const [
    _MoodOption(label: 'Amazing', displayLabel: 'Great', emoji: '😍', score: 5),
    _MoodOption(label: 'Good', emoji: '🙂', score: 4),
    _MoodOption(label: 'Okay', emoji: '😐', score: 3),
    _MoodOption(label: 'Sad', emoji: '😔', score: 2),
    _MoodOption(label: 'Stressed', emoji: '😣', score: 1),
  ];

  bool _loading = true;
  bool _saving = false;
  String _selectedRange = 'This Week';
  _MoodOption? _selectedMood;
  List<PatientMoodEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _loadMoodData();
    PatientMoodService.todayMoodNotifier.addListener(_onMoodSyncUpdated);
  }

  @override
  void dispose() {
    PatientMoodService.todayMoodNotifier.removeListener(_onMoodSyncUpdated);
    _quickNoteController.dispose();
    super.dispose();
  }

  void _onMoodSyncUpdated() {
    final user = SupabaseConfig.client.auth.currentUser;
    final event = PatientMoodService.todayMoodNotifier.value;
    if (user == null || event == null || event.userId != user.id) return;
    _loadMoodData();
  }

  Future<void> _loadMoodData() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    try {
      final rows = await _moodService.getMoodEntries(user.id, limit: 30);
      final today = rows.isNotEmpty ? rows.firstWhere(
        (entry) => _isSameDate(entry.entryDate, DateTime.now()),
        orElse: () => rows.first,
      ) : null;
      if (!mounted) return;
      setState(() {
        _entries = rows;
        if (today != null) {
          _selectedMood = _moodOptions.firstWhere(
            (m) => m.label == today.moodLabel,
            orElse: () => _moodOptions[2],
          );
          _quickNoteController.text = (today.note ?? '').trim();
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _saveEntry() async {
    final user = SupabaseConfig.client.auth.currentUser;
    final mood = _selectedMood;
    if (user == null || mood == null || _saving) return;

    setState(() => _saving = true);
    try {
      await _moodService.upsertTodayMood(
        userId: user.id,
        moodLabel: mood.label,
        moodScore: mood.score,
        note: _quickNoteController.text.trim(),
        source: 'journal',
      );
      await _loadMoodData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save entry: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int get _checkInsCount => _entries.length;
  int get _sessionsCount =>
      _entries.where((e) => e.source == 'journal').length;
  double get _averageMood {
    if (_entries.isEmpty) return 0;
    final total = _entries.fold<int>(0, (a, b) => a + b.moodScore);
    return total / _entries.length;
  }

  List<double> get _weeklyMoodScores {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final list = <double>[];
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final entry = _entries.where((e) => _isSameDate(e.entryDate, day)).toList();
      list.add(entry.isEmpty ? 3 : entry.first.moodScore.toDouble());
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeklyScores = _weeklyMoodScores;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7FC),
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Journal',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF22243B),
              ),
            ),
            Text(
              'Track your feelings. Understand yourself better.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7D819C),
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadMoodData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewCard(theme),
                      const SizedBox(height: 14),
                      _buildMoodInputCard(theme),
                      const SizedBox(height: 14),
                      _buildInsightsCard(theme, weeklyScores),
                      const SizedBox(height: 14),
                      _buildMotivationalCard(theme),
                      const SizedBox(height: 14),
                      _buildEntriesCard(theme),
                      const SizedBox(height: 14),
                      _buildDetailedJournalButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCard(ThemeData theme) {
    return _softCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Mood Overview',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Text('📖', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryStatCard(
                  color: const Color(0xFFE6F7EE),
                  emoji: '😊',
                  value: _averageMood == 0 ? '-' : _averageMood.toStringAsFixed(1),
                  label: 'Avg Mood',
                  valueColor: const Color(0xFF4AA870),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryStatCard(
                  color: const Color(0xFFEAF0FF),
                  emoji: '🗂️',
                  value: '$_sessionsCount',
                  label: 'Sessions',
                  valueColor: const Color(0xFF4A74D8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryStatCard(
                  color: const Color(0xFFF2ECFF),
                  emoji: '🧠',
                  value: '$_checkInsCount',
                  label: 'Check-ins',
                  valueColor: const Color(0xFF7B4DD3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodInputCard(ThemeData theme) {
    return _softCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling right now?',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: _moodOptions
                .map(
                  (m) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _moodChoice(m),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quickNoteController,
                  decoration: InputDecoration(
                    hintText: 'Add a quick note (optional)...',
                    hintStyle: const TextStyle(fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF2F0FF),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _saving ? null : _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E8DE8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Entry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(ThemeData theme, List<double> weeklyScores) {
    return _softCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Mood Insights',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Your mood trend this week',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7D819C)),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRange,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: const [
                      DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                      DropdownMenuItem(value: 'Last Week', child: Text('Last Week')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedRange = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: const Color(0xFFE6E8F0), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 1,
                maxY: 5.2,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final i = value.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[i],
                            style: const TextStyle(fontSize: 11, color: Color(0xFF7D819C)),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, _) {
                        String? label;
                        if (value == 1) label = 'Stressed';
                        if (value == 2) label = 'Sad';
                        if (value == 3) label = 'Okay';
                        if (value == 4) label = 'Good';
                        if (value == 5) label = 'Amazing';
                        if (label == null) return const SizedBox.shrink();
                        return Text(
                          label,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF8B8FA6)),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < weeklyScores.length; i++)
                        FlSpot(i.toDouble(), weeklyScores[i]),
                    ],
                    isCurved: true,
                    color: const Color(0xFF7A73DE),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 5,
                        color: _dotColor(spot.y),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF7A73DE).withValues(alpha: 0.08),
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

  Color _dotColor(double score) {
    if (score >= 4.5) return const Color(0xFF56C58A);
    if (score >= 3.5) return const Color(0xFF6E8DE8);
    if (score >= 2.5) return const Color(0xFFF2BE4D);
    if (score >= 1.5) return const Color(0xFFF08A6A);
    return const Color(0xFFE86C83);
  }

  Widget _buildMotivationalCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF1EDFF), Color(0xFFE6F1FF)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7A73DE)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "You've had some ups and downs, and that's okay.\nKeep taking small steps for your well-being.",
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.35),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFC3CCFF)),
            child: const Center(child: Text('🫂', style: TextStyle(fontSize: 28))),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesCard(ThemeData theme) {
    return _softCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your Entries',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: const Text('View Calendar'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_entries.isEmpty)
            Text(
              'No mood entry yet. Pick an emotion on Home or save one here.',
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7D819C)),
            )
          else
            for (final entry in _entries.take(10)) _entryTile(entry),
        ],
      ),
    );
  }

  Widget _buildDetailedJournalButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Write a detailed journal'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6E63C7),
          backgroundColor: const Color(0xFFF1EDFF),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _moodChoice(_MoodOption mood) {
    final selected = _selectedMood?.label == mood.label;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = mood),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF0FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF6E8DE8) : const Color(0xFFE6E8F0),
          ),
        ),
        child: Column(
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              mood.displayLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFF3D63CD) : const Color(0xFF3D435C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStatCard({
    required Color color,
    required String emoji,
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: valueColor),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF646C86))),
        ],
      ),
    );
  }

  Widget _entryTile(PatientMoodEntry entry) {
    final dt = entry.updatedAt ?? entry.createdAt ?? DateTime.now();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_monthShort(entry.entryDate.month)} ${entry.entryDate.day}\n${_weekdayShort(entry.entryDate.weekday)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.2),
            ),
          ),
          const SizedBox(width: 10),
          Text(_emojiForLabel(entry.moodLabel), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.moodLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text(_formatTime(dt), style: const TextStyle(fontSize: 11, color: Color(0xFF7D819C))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  (entry.note ?? '').isEmpty ? 'No quick note added.' : entry.note!,
                  style: const TextStyle(fontSize: 12.5, height: 1.3),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF2FB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    entry.source == 'home' ? 'Home check-in' : 'Mood journal saved',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF5F6790),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _emojiForLabel(String label) {
    switch (label) {
      case 'Amazing':
        return '😍';
      case 'Good':
        return '🙂';
      case 'Okay':
        return '😐';
      case 'Sad':
        return '😔';
      default:
        return '😣';
    }
  }

  String _monthShort(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[month - 1];
  }

  String _weekdayShort(int weekday) {
    const d = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return d[weekday - 1];
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Widget _softCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MoodOption {
  final String label;
  final String displayLabel;
  final String emoji;
  final int score;

  const _MoodOption({
    required this.label,
    String? displayLabel,
    required this.emoji,
    required this.score,
  }) : displayLabel = displayLabel ?? label;
}
