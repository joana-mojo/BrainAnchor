import 'package:flutter/material.dart';
import 'package:brain_anchor/screens/auth/welcome_screen.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  bool _videoConsultation = true;
  bool _chatConsultation = true;
  bool _twoFactorAuth = false;
  bool _notifAppointments = true;
  bool _notifMessages = true;
  bool _notifSystem = true;
  
  final TextEditingController _feeController = TextEditingController(text: "1500");

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Settings'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage your account and preferences',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            // A. Account
            _buildSectionHeader(context, 'Account', Icons.person_outline),
            _buildCard(
              theme,
              Column(
                children: [
                   Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.person, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dr. Patient Healer', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('dr.healer@brainanchor.com', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.verified, color: Colors.green),
                    title: const Text('Verification Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    subtitle: const Text('Your credentials are verified and active.'),
                    trailing: const Icon(Icons.info_outline, size: 16),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // B. Professional Settings
            _buildSectionHeader(context, 'Professional Settings', Icons.work_outline),
            _buildCard(
              theme,
              Column(
                children: [
                  ListTile(
                    title: const Text('Availability Schedule'),
                    subtitle: const Text('Mon-Fri, 9:00 AM - 5:00 PM'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        const Text('Consultation Fee (PHP)', style: TextStyle(fontSize: 16)),
                        const Spacer(),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _feeController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Video Consultations'),
                    value: _videoConsultation,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _videoConsultation = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Chat Consultations'),
                    value: _chatConsultation,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _chatConsultation = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // C. Privacy & Security
            _buildSectionHeader(context, 'Privacy & Security', Icons.lock_outline),
            _buildCard(
              theme,
              Column(
                children: [
                  ListTile(
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Two-Factor Authentication'),
                    subtitle: const Text('Highly Recommended'),
                    value: _twoFactorAuth,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _twoFactorAuth = val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: Colors.blueGrey),
                    title: const Text('Data Privacy Information'),
                    subtitle: const Text('All active telemedicine sessions are encrypted.'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // D. Notifications
            _buildSectionHeader(context, 'Notifications', Icons.notifications_none),
            _buildCard(
              theme,
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Appointment Alerts'),
                    value: _notifAppointments,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _notifAppointments = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Patient Messages'),
                    value: _notifMessages,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _notifMessages = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('System Updates'),
                    value: _notifSystem,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _notifSystem = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // E. Support
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
                    title: const Text('Contact Admin Support'),
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
                label: const Text('Secure Logout', style: TextStyle(fontWeight: FontWeight.bold)),
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
        borderRadius: BorderRadius.circular(16),
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
