import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:brain_anchor/screens/auth/login_screen.dart';
import 'package:brain_anchor/core/constants.dart';
import 'package:brain_anchor/screens/patient/settings_screen.dart';
import 'package:brain_anchor/screens/patient/health_vault_screen.dart';
import 'package:brain_anchor/screens/patient/progress_tracking_screen.dart';
import 'package:brain_anchor/services/patient_service.dart';
import 'package:brain_anchor/services/supabase_config.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _patientService = PatientService();

  bool _loadingProfile = true;
  bool _uploadingAvatar = false;
  PatientProfileData? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    final profile = await _patientService.getPatientProfileData(user.id);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loadingProfile = false;
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null || _uploadingAvatar) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _uploadingAvatar = true);

      await _patientService.uploadPatientAvatar(
        userId: user.id,
        bytes: bytes,
        fileExtension: file.extension ?? 'jpg',
      );

      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $message')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null || _uploadingAvatar) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text(
          'Your profile photo will be removed and your initial will be shown instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _uploadingAvatar = true);
      await _patientService.clearPatientAvatar(user.id);
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo removed.')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove photo: $message')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = (_profile?.fullName ?? '').trim();
    final email = (_profile?.email ?? '').trim();
    final avatarUrl = (_profile?.avatarUrl ?? '').trim();
    final displayName = (_profile?.displayName ?? '').trim();
    final fallbackInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                fallbackInitial,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAndUploadAvatar,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _uploadingAvatar
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                      if (avatarUrl.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: InkWell(
                            onTap: _removeAvatar,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _loadingProfile ? 'Loading...' : (fullName.isNotEmpty ? fullName : 'No name on file'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loadingProfile ? 'Loading email...' : (email.isNotEmpty ? email : 'No email on file'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _ProfileListTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Anonymous Mode',
              trailing: Switch(
                value: true,
                onChanged: (val) {},
                activeThumbColor: theme.colorScheme.secondary,
              ),
              onTap: () {},
            ),
            _ProfileListTile(
              icon: Icons.health_and_safety_outlined,
              title: 'Health Vault (Secure info)',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HealthVaultScreen()),
                );
              },
            ),
            _ProfileListTile(
              icon: Icons.bar_chart_rounded,
              title: 'Mood Journal',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProgressTrackingScreen()),
                );
              },
            ),
            _ProfileListTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(
                        initialRole: AppConstants.rolePatient,
                      ),
                    ),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error, width: 2),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ProfileListTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      onTap: onTap,
    );
  }
}
