import 'package:flutter/material.dart';
import 'package:brain_anchor/screens/auth/welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Toggle states
  bool _anonymousMode = false;
  bool _hideActivity = true;
  bool _notifAppointments = true;
  bool _notifMessages = true;
  bool _notifReminders = true;
  bool _notifTips = false;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage your preferences and privacy',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Account Settings
            _buildSectionHeader(context, 'Account Settings', Icons.person_outline),
            _buildCard(
              theme,
              Column(
                children: [
                  ListTile(
                    title: const Text('Profile Info'),
                    subtitle: const Text('User (Anonymous)'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Linked Accounts'),
                    subtitle: const Text('Google Connected'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Privacy & Security
            _buildSectionHeader(context, 'Privacy & Security', Icons.security_outlined),
            _buildCard(
              theme,
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'End-to-End Encrypted',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Anonymous Mode'),
                    value: _anonymousMode,
                    activeColor: theme.colorScheme.secondary,
                    onChanged: (val) => setState(() => _anonymousMode = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Hide Activity from Doctors'),
                    value: _hideActivity,
                    activeColor: theme.colorScheme.secondary,
                    onChanged: (val) => setState(() => _hideActivity = val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Manage Data Permissions'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notifications
            _buildSectionHeader(context, 'Notifications', Icons.notifications_none_outlined),
            _buildCard(
              theme,
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Appointments'),
                    value: _notifAppointments,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _notifAppointments = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Messages'),
                    value: _notifMessages,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _notifMessages = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Reminders'),
                    value: _notifReminders,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _notifReminders = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Mental Health Tips'),
                    value: _notifTips,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _notifTips = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Preferences
            _buildSectionHeader(context, 'App Preferences', Icons.tune_outlined),
            _buildCard(
              theme,
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: _darkMode,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _darkMode = val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Language'),
                    trailing: DropdownButton<String>(
                      value: 'English',
                      underline: const SizedBox(),
                      items: ['English', 'Spanish', 'French'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support
            _buildSectionHeader(context, 'Support', Icons.help_outline),
            _buildCard(
              theme,
              Column(
                children: [
                  ListTile(
                    title: const Text('Help Center'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Contact Support'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Report a Problem'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                  foregroundColor: theme.colorScheme.error,
                  elevation: 0,
                  side: BorderSide(color: theme.colorScheme.error, width: 2),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ThemeData theme, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
