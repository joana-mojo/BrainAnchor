import 'package:flutter/material.dart';
import 'package:brain_anchor/screens/auth/login_screen.dart';
import 'package:brain_anchor/core/constants.dart';
import 'package:brain_anchor/screens/patient/settings_screen.dart';
import 'package:brain_anchor/screens/patient/health_vault_screen.dart';
import 'package:brain_anchor/screens/patient/progress_tracking_screen.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.secondary.withOpacity(
                      0.1,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'User (Anonymous)',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'user@example.com',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Profile Options
            _ProfileListTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Anonymous Mode',
              trailing: Switch(
                value: true,
                onChanged: (val) {},
                activeColor: theme.colorScheme.secondary,
              ),
              onTap: () {},
            ),
            _ProfileListTile(
              icon: Icons.health_and_safety_outlined,
              title: 'Health Vault (Secure info)',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthVaultScreen()));
              },
            ),
            _ProfileListTile(
              icon: Icons.bar_chart_rounded,
              title: 'Progress Tracking',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgressTrackingScreen()));
              },
            ),
            _ProfileListTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              },
            ),
            const SizedBox(height: 32),

            // Logout Button
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
          color: theme.colorScheme.primary.withOpacity(0.1),
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
      trailing:
          trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      onTap: onTap,
    );
  }
}
