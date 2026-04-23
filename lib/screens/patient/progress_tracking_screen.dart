import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  // Chart Data (Dummy)
  final List<FlSpot> _moodData = const [
    FlSpot(0, 3), // Mon: Neutral
    FlSpot(1, 4), // Tue: Good
    FlSpot(2, 2), // Wed: Sad
    FlSpot(3, 3), // Thu: Neutral
    FlSpot(4, 5), // Fri: Great
    FlSpot(5, 4), // Sat: Good
    FlSpot(6, 4.5), // Sun: Very Good
  ];

  // Dummy Timeline Data
  final List<Map<String, dynamic>> _activities = [
    {
      'title': 'Completed consultation',
      'subtitle': 'Dr. Sarah Smith',
      'time': 'Today, 10:00 AM',
      'icon': Icons.video_camera_front_outlined,
      'color': Colors.blue,
    },
    {
      'title': 'AI check-in done',
      'subtitle': 'Mood scored: 4.5/5',
      'time': 'Yesterday, 8:00 PM',
      'icon': Icons.psychology_outlined,
      'color': Colors.purple,
    },
    {
      'title': 'New record added',
      'subtitle': 'Therapy_Notes.pdf',
      'time': 'Oct 12, 2026',
      'icon': Icons.folder_shared_outlined,
      'color': Colors.green,
    },
  ];

  void _showAddMoodBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LogMoodBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Using layout from theme
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Progress Tracker'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your mental wellness journey',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),

            // Mood Tracking Chart Section
            Text(
              'Mood Overview (This Week)',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.only(right: 16, left: 0, top: 24, bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.colorScheme.onBackground.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value.toInt() >= 0 && value.toInt() < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                days[value.toInt()],
                                style: TextStyle(
                                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          IconData? iconData;
                          Color iconColor = theme.colorScheme.primary;
                          if (value == 1) { iconData = Icons.sentiment_very_dissatisfied; iconColor = Colors.red; }
                          else if (value == 3) { iconData = Icons.sentiment_neutral; iconColor = Colors.amber; }
                          else if (value == 5) { iconData = Icons.sentiment_very_satisfied; iconColor = Colors.green; }
                          
                          if (iconData == null) return const SizedBox();

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(iconData, size: 20, color: iconColor),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 1,
                  maxY: 5.5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _moodData,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 5,
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Statistics Cards
            Row(
              children: [
                _buildStatCard(theme, 'Avg Mood', '4.2', Icons.mood, theme.colorScheme.secondary),
                const SizedBox(width: 16),
                _buildStatCard(theme, 'Sessions', '12', Icons.video_chat, theme.colorScheme.primary),
                const SizedBox(width: 16),
                _buildStatCard(theme, 'AI Checks', '28', Icons.psychology_alt, Colors.purple),
              ],
            ),
            const SizedBox(height: 32),

            // AI Insights
            Text(
              'AI Insights',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.secondary.withOpacity(0.1), theme.colorScheme.primary.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.secondary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You\'ve been improving this week!', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Your mood score is up 15%. Consider scheduling a follow-up session to maintain this momentum.', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Activity Timeline
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._activities.map((activity) => _buildTimelineItem(theme, activity)).toList(),
            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMoodBottomSheet,
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log Mood', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.6)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(ThemeData theme, Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(activity['icon'] as IconData, size: 20, color: activity['color'] as Color),
              ),
              // Optional: drawing a line here for continuous timeline
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.onBackground.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activity['title'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        activity['time'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['subtitle'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom Sheet for Logging Mood
class _LogMoodBottomSheet extends StatefulWidget {
  const _LogMoodBottomSheet();

  @override
  State<_LogMoodBottomSheet> createState() => _LogMoodBottomSheetState();
}

class _LogMoodBottomSheetState extends State<_LogMoodBottomSheet> {
  double _moodValue = 3; // default neutral
  
  IconData _getMoodIcon() {
    if (_moodValue < 2) return Icons.sentiment_very_dissatisfied;
    if (_moodValue < 3) return Icons.sentiment_dissatisfied;
    if (_moodValue < 4) return Icons.sentiment_neutral;
    if (_moodValue < 5) return Icons.sentiment_satisfied;
    return Icons.sentiment_very_satisfied;
  }

  Color _getMoodColor() {
    if (_moodValue < 2) return Colors.red;
    if (_moodValue < 3) return Colors.orange;
    if (_moodValue < 4) return Colors.amber;
    if (_moodValue < 5) return Colors.lightGreen;
    return Colors.green;
  }

  String _getMoodLabel() {
    if (_moodValue < 2) return 'Very Sad';
    if (_moodValue < 3) return 'Sad';
    if (_moodValue < 4) return 'Neutral';
    if (_moodValue < 5) return 'Good';
    return 'Excellent';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onBackground.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text('Log Your Mood', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('How are you feeling right now?', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 32),
          
          Icon(
            _getMoodIcon(), 
            size: 80, 
            color: _getMoodColor(),
          ),
          const SizedBox(height: 8),
          Text(
            _getMoodLabel(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          Slider(
            value: _moodValue,
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.colorScheme.primary.withOpacity(0.2),
            onChanged: (val) => setState(() => _moodValue = val),
          ),
          const SizedBox(height: 24),
          
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a note about your mood... (Optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: theme.colorScheme.onBackground.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mood logged successfully!')));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Entry'),
            ),
          ),
        ],
      ),
    );
  }
}
