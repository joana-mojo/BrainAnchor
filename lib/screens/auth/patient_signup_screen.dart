import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:brain_anchor/screens/auth/login_screen.dart';
import 'package:brain_anchor/core/constants.dart';

class PatientSignupScreen extends StatefulWidget {
  const PatientSignupScreen({super.key});

  @override
  State<PatientSignupScreen> createState() => _PatientSignupScreenState();
}

class _PatientSignupScreenState extends State<PatientSignupScreen> {
  bool _isAnonymous = false;
  bool _agreeToPolicy = false;
  bool _isPasswordVisible = false;

  DateTime? _selectedBirthdate;
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;

  @override
  void dispose() {
    _birthdateController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthdate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
        _birthdateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _calculateAge(picked);
      });
    }
  }

  void _calculateAge(DateTime birthdate) {
    final today = DateTime.now();
    int age = today.year - birthdate.year;
    if (today.month < birthdate.month ||
        (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    _ageController.text = age.toString();
  }

  void _showPolicyModal(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text('This is the full content for $title.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _signup() {
    // Navigate to Login after signup or directly to dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(initialRole: AppConstants.rolePatient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sign up anonymously toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.privacy_tip_outlined,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stay anonymous to doctors',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Your real name will be hidden during consultations.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnonymous,
                    onChanged: (val) => setState(() => _isAnonymous = val),
                    activeColor: theme.colorScheme.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
                decoration: const InputDecoration(
                  hintText: 'First Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Middle Name (Optional)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthdateController,
                readOnly: true,
                onTap: () => _selectBirthdate(context),
                decoration: const InputDecoration(
                  hintText: 'Birthdate',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: 'Age',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  hintText: 'Gender',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                items: ['Male', 'Female', 'Prefer not to say', 'Other']
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 16),

            TextFormField(
              decoration: const InputDecoration(
                hintText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              obscureText: !_isPasswordVisible,
              decoration: const InputDecoration(
                hintText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 24),

            // Policy Checkbox
            Row(
              children: [
                Checkbox(
                  value: _agreeToPolicy,
                  onChanged: (val) =>
                      setState(() => _agreeToPolicy = val ?? false),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _showPolicyModal(context, 'Privacy Policy'),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _showPolicyModal(context, 'Terms of Service'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Signup Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _agreeToPolicy ? _signup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      theme.colorScheme.secondary, // Teal for patient
                ),
                child: const Text('Create Account'),
              ),
            ),
            const SizedBox(height: 24),

            // Login link
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(
                        initialRole: AppConstants.rolePatient,
                      ),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
