import 'package:flutter/material.dart';
import 'package:brain_anchor/screens/patient/patient_ai_checker_screen.dart';
import 'package:brain_anchor/services/patient_mood_service.dart';
import '../../services/patient_service.dart';
import '../../services/provider_directory_service.dart';
import '../../services/supabase_config.dart';
import '../../theme/app_theme.dart';

class PatientHomeScreen extends StatefulWidget {
  final VoidCallback? onOpenWellnessCheck;
  final VoidCallback? onOpenMoodJournal;
  final VoidCallback? onOpenConsults;
  const PatientHomeScreen({
    super.key,
    this.onOpenWellnessCheck,
    this.onOpenMoodJournal,
    this.onOpenConsults,
  });

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final _patientService = PatientService();
  final _providerDirectoryService = ProviderDirectoryService();
  final _patientMoodService = PatientMoodService();
  String? _displayName;
  String? _profileAvatarUrl;
  String? _todayMoodLabel;
  bool _savingMood = false;
  bool _careTeamLoading = false;
  String? _careTeamError;
  List<ApprovedProvider> _careTeam = const [];

  @override
  void initState() {
    super.initState();
    _loadHeaderProfile();
    _loadCareTeam();
    _loadTodayMood();
    PatientMoodService.todayMoodNotifier.addListener(_onMoodSyncUpdated);
  }

  @override
  void dispose() {
    PatientMoodService.todayMoodNotifier.removeListener(_onMoodSyncUpdated);
    super.dispose();
  }

  void _onMoodSyncUpdated() {
    final user = SupabaseConfig.client.auth.currentUser;
    final event = PatientMoodService.todayMoodNotifier.value;
    if (user == null || event == null || event.userId != user.id) return;
    if (!mounted) return;
    setState(() => _todayMoodLabel = event.moodLabel);
  }

  Future<void> _loadHeaderProfile() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    final profile = await _patientService.getPatientProfileData(user.id);
    if (!mounted) return;
    setState(() {
      _displayName = profile?.displayName;
      _profileAvatarUrl = profile?.avatarUrl;
    });
  }

  Future<void> _loadCareTeam() async {
    setState(() {
      _careTeamLoading = true;
      _careTeamError = null;
    });

    try {
      final providers = await _providerDirectoryService.fetchApprovedProviders();
      if (!mounted) return;
      setState(() {
        _careTeam = providers;
        _careTeamLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _careTeamError = 'Couldn\'t load your care team right now.';
        _careTeamLoading = false;
      });
    }
  }

  Future<void> _loadTodayMood() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    try {
      final today = await _patientMoodService.getTodayMood(user.id);
      if (!mounted) return;
      setState(() => _todayMoodLabel = today?.moodLabel);
    } catch (_) {
      // Keep silent to avoid interrupting home screen UX.
    }
  }

  Future<void> _saveTodayMood({
    required String moodLabel,
    required int moodScore,
  }) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null || _savingMood) return;

    setState(() {
      _savingMood = true;
      _todayMoodLabel = moodLabel;
    });

    try {
      await _patientMoodService.upsertTodayMood(
        userId: user.id,
        moodLabel: moodLabel,
        moodScore: moodScore,
        source: 'home',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save mood: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingMood = false);
    }
  }

  /// Returns "Good Morning" / "Good Noon" / "Good Afternoon" / "Good Evening"
  /// based on the local time, plus a matching emoji.
  ///   Morning   : 5:00 \u2013 11:59
  ///   Noon      : 12:00 \u2013 12:59
  ///   Afternoon : 13:00 \u2013 17:59
  ///   Evening   : 18:00 \u2013 4:59 (next day)
  ({String greeting, String emoji}) _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return (greeting: 'Good Morning,', emoji: '\u2600\uFE0F'); // \u2600\uFE0F sun
    }
    if (hour == 12) {
      return (greeting: 'Good Noon,', emoji: '\u{1F31E}'); // \u{1F31E} sun with face
    }
    if (hour >= 13 && hour < 18) {
      return (greeting: 'Good Afternoon,', emoji: '\u{1F324}\uFE0F'); // \u{1F324} sun behind small cloud
    }
    return (greeting: 'Good Evening,', emoji: '\u{1F319}'); // \u{1F319} crescent moon
  }

  /// Capitalizes only the first character so a stored "ron" displays as
  /// "Ron" in the greeting, while preserving the rest of the user's typing
  /// (e.g. "McDonald" stays "McDonald", not "Mcdonald").
  String _capitalizeFirst(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white, // Overall background is white to match the mockup
      body: Stack(
        children: [
          // Background soft gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF4F0FF), // Soft pastel purple
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Greeting Section
                  _buildTopBar(theme),
                  const SizedBox(height: 32),

                  // 2. Mood Check-in
                  Row(
                    children: [
                      Text(
                        'How are you feeling today?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('✨', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your feelings matter. Take a moment for you.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMoodCheckIn(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🤍', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        "It's okay to feel what you feel.",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('🌿', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 3. Care Team
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Your Care Team',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('🤍', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          if (widget.onOpenConsults != null) {
                            widget.onOpenConsults!.call();
                          }
                        },
                        child: Text(
                          'See All >',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCareTeam(theme),
                  const SizedBox(height: 32),

                  // 4. Quick Actions
                  Row(
                    children: [
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('⚡', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(theme),
                  const SizedBox(height: 32),

                  // 5. Motivational Banner
                  _buildMotivationalBanner(theme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    final timeOfDay = _greetingForNow();
    // Show the user's nickname (or first name) if loaded; otherwise leave it
    // blank so we never flash a hard-coded "Joana" before the fetch returns.
    final rawName = _displayName ?? '';
    final name = _capitalizeFirst(rawName);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting line: muted, lighter weight to let the name take focus.
              Row(
                children: [
                  Text(
                    timeOfDay.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeOfDay.greeting,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Name with a soft brand-color gradient. ShaderMask requires
              // the underlying text to be white so the gradient shows through.
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  name,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tagline with a soft pill background for a calmer, more
              // grounded feel than plain text.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "You're not alone, we're with you.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: (_profileAvatarUrl != null &&
                        _profileAvatarUrl!.isNotEmpty)
                    ? NetworkImage(_profileAvatarUrl!)
                    : null,
                child: (_profileAvatarUrl == null || _profileAvatarUrl!.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80), // Green online status
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoodCheckIn() {
    final moods = [
      {
        'emoji': '🤩',
        'title': 'Great',
        'dbLabel': 'Amazing',
        'score': 5,
        'subtitle': 'Feeling amazing!',
        'color': const Color(0xFFE8F8F5), // Soft Mint
        'textColor': const Color(0xFF1ABC9C)
      },
      {
        'emoji': '🙂',
        'title': 'Good',
        'score': 4,
        'subtitle': 'Feeling good',
        'color': const Color(0xFFEBF5FB), // Soft Blue
        'textColor': const Color(0xFF3498DB)
      },
      {
        'emoji': '😐',
        'title': 'Okay',
        'score': 3,
        'subtitle': 'Just okay',
        'color': const Color(0xFFFEF9E7), // Soft Yellow
        'textColor': const Color(0xFFF1C40F)
      },
      {
        'emoji': '😢',
        'title': 'Sad',
        'score': 2,
        'subtitle': 'Feeling low',
        'color': const Color(0xFFFDEDEC), // Soft Peach
        'textColor': const Color(0xFFE74C3C)
      },
      {
        'emoji': '😖',
        'title': 'Stressed',
        'score': 1,
        'subtitle': 'Very overwhelmed',
        'color': const Color(0xFFFADBD8), // Soft Red/Pink
        'textColor': const Color(0xFFC0392B)
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: moods.map((mood) {
        final title = mood['title'] as String;
        final dbLabel = (mood['dbLabel'] as String?) ?? title;
        final isSelected = _todayMoodLabel == dbLabel;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () => _saveTodayMood(
                moodLabel: dbLabel,
                moodScore: mood['score'] as int,
              ),
              child: Container(
                height: 135,
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: BoxDecoration(
                  color: mood['color'] as Color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (mood['color'] as Color).withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mood['emoji'] as String,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isSelected
                            ? (_savingMood ? 'Saving...' : 'Saved for today')
                            : mood['subtitle'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: mood['textColor'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCareTeam(ThemeData theme) {
    if (_careTeamLoading) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_careTeamError != null) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _careTeamError!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadCareTeam,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_careTeam.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'No approved providers yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    final cardColors = const [
      Color(0xFFEDE8FF),
      Color(0xFFE5F7F3),
      Color(0xFFFFEEE7),
    ];

    return Column(
      children: [
        for (int index = 0; index < _careTeam.length && index < 3; index++) ...[
          _careTeamProviderCard(
            theme: theme,
            provider: _careTeam[index],
            cardColor: cardColors[index % cardColors.length],
          ),
          if (index < _careTeam.length - 1 && index < 2)
            const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _careTeamProviderCard({
    required ThemeData theme,
    required ApprovedProvider provider,
    required Color cardColor,
  }) {
    final displayName = _providerNameForCard(provider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.specialization,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${provider.yearsOfExperience} years exp',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F73E0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF2F73E0),
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Approved',
                            style: TextStyle(
                              color: Color(0xFF2F73E0),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Align(
            alignment: Alignment.bottomCenter,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D8FE5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Connect'),
            ),
          ),
        ],
      ),
    );
  }

  String _providerNameForCard(ApprovedProvider provider) {
    final specialization = provider.specialization.toLowerCase();
    final isPsychiatry = specialization.contains('psychiatrist') ||
        specialization.contains('psychiatry');
    if (isPsychiatry) return provider.displayName;
    return provider.displayName.replaceFirst(RegExp(r'^Dr\.\s*'), '');
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: '🧠',
                title: 'Wellness\nCheck',
                subtitle: 'Reflect and check in gently',
                color: const Color(0xFFF3E5F5), // Light purple
                onTap: () {
                  if (widget.onOpenWellnessCheck != null) {
                    widget.onOpenWellnessCheck!.call();
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PatientAiCheckerScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: '🧘‍♀️',
                title: 'Guided\nRelaxation',
                subtitle: 'Calm your mind',
                color: const Color(0xFFE0F2F1), // Light teal
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: '📖',
                title: 'Mood\nJournal',
                subtitle: 'Write your feelings',
                color: const Color(0xFFFBE9E7), // Light coral
                onTap: () {
                  if (widget.onOpenMoodJournal != null) {
                    widget.onOpenMoodJournal!.call();
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: '🌱',
                title: 'Wellness\nTools',
                subtitle: 'Helpful resources',
                color: const Color(0xFFFFF8E1), // Light yellow
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8EAF6), // Very light indigo
            Color(0xFFF3E5F5), // Very light purple
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD1C4E9).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🤍', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Small steps every day lead to big changes.',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "You're doing better than you think. 🌞☁️",
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
