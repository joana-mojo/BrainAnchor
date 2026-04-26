import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:brain_anchor/services/auth_service.dart';
import 'package:brain_anchor/services/provider_service.dart';
import 'package:brain_anchor/services/storage_service.dart';
import 'package:brain_anchor/screens/auth/login_screen.dart';
import 'package:brain_anchor/core/constants.dart';
import 'package:brain_anchor/widgets/terms_and_privacy_dialog.dart';

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final List<String> _specializations = [
    'Clinical Psychologist',
    'Psychiatrist',
    'Therapist',
    'Counselor',
    'Mental Health Nurse',
  ];
  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];
  
  String? _selectedSpecialization;
  String? _selectedGender;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToPolicy = false;
  bool _isLoading = false;
  File? _selectedFile;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  final _authService = AuthService();
  final _providerService = ProviderService();
  final _storageService = StorageService();

  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = () {
      TermsAndPrivacyDialogs.showTermsOfUse(context);
    };
    _privacyRecognizer = TapGestureRecognizer()..onTap = () {
      TermsAndPrivacyDialogs.showPrivacyPolicy(context);
    };
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    _birthdayController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _firstNameController.text.isNotEmpty &&
           _lastNameController.text.isNotEmpty &&
           _birthdayController.text.isNotEmpty &&
           _selectedGender != null &&
           _emailController.text.isNotEmpty &&
           _passwordController.text.isNotEmpty &&
           _passwordController.text == _confirmPasswordController.text &&
           _licenseController.text.isNotEmpty &&
           _selectedSpecialization != null &&
           _experienceController.text.isNotEmpty &&
           _selectedFile != null &&
           _agreeToPolicy;
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _register() async {
    if (_isFormValid()) {
      setState(() => _isLoading = true);
      try {
        // 1. Sign up user
        final authResponse = await _authService.signUpProvider(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final userId = authResponse.user?.id;
        if (userId == null) throw Exception('Registration failed.');

        // 2. Upload file
        final fileUrl = await _storageService.uploadProviderDocument(
          providerId: userId,
          file: _selectedFile!,
        );

        // 3. Create profile
        await _providerService.createProviderProfile(
          userId: userId,
          firstName: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          suffix: _suffixController.text.trim().isEmpty ? null : _suffixController.text.trim(),
          birthday: DateFormat('yyyy-MM-dd').parse(_birthdayController.text),
          gender: _selectedGender!,
          email: _emailController.text.trim(),
          licenseNumber: _licenseController.text.trim(),
          specialization: _selectedSpecialization!,
          yearsOfExperience: int.tryParse(_experienceController.text.trim()) ?? 0,
          verificationFileUrl: fileUrl,
        );

        if (!mounted) return;
        
        // Show success and instructions
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Registration Submitted'),
            content: const Text('Verification required before approval. Your account will be reviewed.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(initialRole: AppConstants.roleDoctor),
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Verification required before approval. Your account will be reviewed.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildLabeledField(
              'First Name *',
              TextFormField(
                controller: _firstNameController,
                decoration: _commonInputDecoration('First Name'),
                onChanged: (_) => setState((){}),
              ),
            ),

            _buildLabeledField(
              'Middle Name (Optional)',
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
                onChanged: (_) => setState((){}),
              ),
            ),

            _buildLabeledField(
              'Suffix (Optional)',
              TextFormField(
                controller: _suffixController,
                decoration: _commonInputDecoration('ex. Jr., MD'),
              ),
            ),

            _buildLabeledField(
              'Birthday *',
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1990),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _birthdayController.text = DateFormat('MM/dd/yyyy').format(picked);
                    });
                  }
                },
                child: InputDecorator(
                  decoration: _commonInputDecoration(
                    'MM/DD/YYYY', 
                    suffixIcon: Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary),
                  ),
                  child: Text(
                    _birthdayController.text.isEmpty 
                      ? 'MM/DD/YYYY' 
                      : _birthdayController.text,
                    style: TextStyle(
                      color: _birthdayController.text.isEmpty ? Colors.grey.shade400 : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            _buildLabeledField(
              'Gender *',
              DropdownButtonFormField<String>(
                decoration: _commonInputDecoration('Select from the options'),
                icon: const Icon(Icons.keyboard_arrow_down),
                value: _selectedGender,
                items: _genders.map((g) {
                  return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 14)));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedGender = val;
                  });
                },
              ),
            ),

            _buildLabeledField(
              'Email Address *',
              TextFormField(
                controller: _emailController,
                decoration: _commonInputDecoration('name@email.com'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState((){}),
              ),
            ),

            _buildLabeledField(
              'Password *',
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _commonInputDecoration(
                  'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                onChanged: (_) => setState((){}),
              ),
            ),

            _buildLabeledField(
              'Confirm Password *',
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: _commonInputDecoration(
                  'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                ),
                onChanged: (_) => setState((){}),
              ),
            ),

            _buildLabeledField(
              'License Number *',
              TextFormField(
                controller: _licenseController,
                decoration: _commonInputDecoration('License Number'),
                onChanged: (_) => setState((){}),
              ),
            ),

            _buildLabeledField(
              'Specialization *',
              DropdownButtonFormField<String>(
                decoration: _commonInputDecoration('Select Specialization'),
                icon: const Icon(Icons.keyboard_arrow_down),
                value: _selectedSpecialization,
                items: _specializations.map((spec) {
                  return DropdownMenuItem(value: spec, child: Text(spec, style: const TextStyle(fontSize: 14)));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSpecialization = val;
                  });
                },
              ),
            ),

            _buildLabeledField(
              'Years of Experience *',
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: _commonInputDecoration('e.g. 5'),
                onChanged: (_) => setState((){}),
              ),
            ),

            // File Upload UI
            _buildLabeledField(
              'Upload ID / License Verification *',
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFile != null ? theme.colorScheme.primary : Colors.grey.shade300,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                        size: 40,
                        color: _selectedFile != null ? theme.colorScheme.primary : theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile != null ? _selectedFile!.path.split(Platform.pathSeparator).last : 'Tap to Upload',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedFile == null)
                        Text(
                          'PDF, JPG, PNG (Max 5MB)',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Consent Section
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
                    onChanged: (val) => setState(() => _agreeToPolicy = val ?? false),
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
                onPressed: (_isFormValid() && !_isLoading) ? _register : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: _isFormValid() ? 1.0 : 0.5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const SizedBox(
                      height: 24, 
                      width: 24, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text('Register as Provider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
