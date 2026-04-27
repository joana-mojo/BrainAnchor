import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:brain_anchor/screens/auth/signup/step4_create_mpin_screen.dart';
import 'package:brain_anchor/widgets/terms_and_privacy_dialog.dart';

/// Visible signup step 2 of 4: personal information + recovery password.
///
/// This screen only collects data — nothing is written to Supabase here.
/// The actual sign-up happens after the MPIN is confirmed (step 4).
class Step3PersonalInfoScreen extends StatefulWidget {
  /// Email collected in step 1. When set, the email field is hidden.
  final String? prefillEmail;

  const Step3PersonalInfoScreen({super.key, this.prefillEmail});

  @override
  State<Step3PersonalInfoScreen> createState() =>
      _Step3PersonalInfoScreenState();
}

class _Step3PersonalInfoScreenState extends State<Step3PersonalInfoScreen> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _suffixController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedSex;
  String? _selectedGenderId;

  bool _agreeToPolicy = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  static const int _minPasswordLen = 8;

  @override
  void initState() {
    super.initState();
    if (widget.prefillEmail != null) {
      _emailController.text = widget.prefillEmail!;
    }
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => TermsAndPrivacyDialogs.showTermsOfUse(context);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => TermsAndPrivacyDialogs.showPrivacyPolicy(context);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _suffixController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _isFormValid() {
    final passwordOk =
        _passwordController.text.length >= _minPasswordLen &&
            _confirmPasswordController.text == _passwordController.text;

    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _nicknameController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        _selectedSex != null &&
        passwordOk &&
        _agreeToPolicy;
  }

  String? _passwordError() {
    final p = _passwordController.text;
    final c = _confirmPasswordController.text;
    if (p.isEmpty) return null;
    if (p.length < _minPasswordLen) {
      return 'Password must be at least $_minPasswordLen characters.';
    }
    if (c.isNotEmpty && c != p) return 'Passwords don\'t match.';
    return null;
  }

  void _next() {
    if (!_isFormValid()) return;

    final email = widget.prefillEmail ??
        (_emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim());

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address.')),
      );
      return;
    }

    final patientData = <String, dynamic>{
      'email': email,
      'recoveryPassword': _passwordController.text,
      'firstName': _firstNameController.text.trim(),
      'middleName': _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'nickname': _nicknameController.text.trim(),
      'suffix': _suffixController.text.trim().isEmpty
          ? null
          : _suffixController.text.trim(),
      'birthday': _selectedDate,
      'sexAssignedAtBirth': _selectedSex,
      'genderIdentity': _selectedGenderId,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Step4CreateMpinScreen(patientData: patientData),
      ),
    );
  }

  Widget _buildLabeledField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  InputDecoration _commonInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passwordError = _passwordError();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.5, // 2 of 4
            backgroundColor: Colors.grey.shade200,
            valueColor:
                AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Provide information that is true and correct for medical purposes.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              _buildLabeledField(
                'First Name *',
                TextFormField(
                  controller: _firstNameController,
                  decoration: _commonInputDecoration('First Name'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              _buildLabeledField(
                'Middle name (optional)',
                TextFormField(
                  controller: _middleNameController,
                  decoration: _commonInputDecoration('Middle Name'),
                ),
              ),
              _buildLabeledField(
                'Last Name *',
                TextFormField(
                  controller: _lastNameController,
                  decoration: _commonInputDecoration('Last Name'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildLabeledField(
                      'Nickname *',
                      TextFormField(
                        controller: _nicknameController,
                        decoration: _commonInputDecoration('Nickname'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLabeledField(
                      'Suffix (optional)',
                      TextFormField(
                        controller: _suffixController,
                        decoration: _commonInputDecoration(
                          'ex. Jr., I, II, III, Sr.',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _buildLabeledField(
                'Birthday *',
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: _commonInputDecoration(
                      'MM/DD/YYYY',
                      suffixIcon: Icon(
                        Icons.calendar_today_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'MM/DD/YYYY'
                          : DateFormat('MM/dd/yyyy').format(_selectedDate!),
                      style: TextStyle(
                        color: _selectedDate == null
                            ? Colors.grey.shade400
                            : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              _buildLabeledField(
                'Sex assigned at birth *',
                DropdownButtonFormField<String>(
                  decoration: _commonInputDecoration('Select from the options'),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: ['Male', 'Female']
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g, style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedSex = val),
                ),
              ),
              _buildLabeledField(
                'Gender identity (optional)',
                DropdownButtonFormField<String>(
                  decoration: _commonInputDecoration('Select from the options'),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: [
                    'Male',
                    'Female',
                    'Non-binary',
                    'Transgender',
                    'Other',
                    'Prefer not to say',
                  ]
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g, style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedGenderId = val),
                ),
              ),
              if (widget.prefillEmail == null)
                _buildLabeledField(
                  'Email address *',
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        _commonInputDecoration('ex. name@email.com'),
                  ),
                ),

              const SizedBox(height: 8),
              Text(
                'Recovery password',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You\'ll log in with your MPIN, but if you ever forget it '
                'we\'ll use this password to let you set a new one.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              _buildLabeledField(
                'Password *',
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  onChanged: (_) => setState(() {}),
                  decoration: _commonInputDecoration(
                    'At least $_minPasswordLen characters',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () => setState(
                        () => _passwordVisible = !_passwordVisible,
                      ),
                    ),
                  ),
                ),
              ),
              _buildLabeledField(
                'Confirm password *',
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_confirmVisible,
                  onChanged: (_) => setState(() {}),
                  decoration: _commonInputDecoration(
                    'Re-enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () =>
                          setState(() => _confirmVisible = !_confirmVisible),
                    ),
                  ),
                ),
              ),
              if (passwordError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    passwordError,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 8),
              Text(
                'Consent',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreeToPolicy,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) =>
                          setState(() => _agreeToPolicy = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Use',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _termsRecognizer,
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _privacyRecognizer,
                          ),
                          const TextSpan(text: ' *'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFormValid() ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: _isFormValid() ? 1.0 : 0.5,
                    ),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
