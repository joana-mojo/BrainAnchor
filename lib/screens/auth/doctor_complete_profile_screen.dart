import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:brain_anchor/services/provider_service.dart';
import 'package:brain_anchor/services/storage_service.dart';
import 'package:brain_anchor/screens/auth/role_redirect_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorCompleteProfileScreen extends StatefulWidget {
  const DoctorCompleteProfileScreen({super.key});

  @override
  State<DoctorCompleteProfileScreen> createState() => _DoctorCompleteProfileScreenState();
}

class _DoctorCompleteProfileScreenState extends State<DoctorCompleteProfileScreen> {
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
  bool _isLoading = false;
  File? _selectedFile;
  DateTime? _selectedBirthday;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  final _providerService = ProviderService();
  final _storageService = StorageService();

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    _birthdayController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _firstNameController.text.isNotEmpty &&
           _lastNameController.text.isNotEmpty &&
           _selectedBirthday != null &&
           _selectedGender != null &&
           _licenseController.text.isNotEmpty &&
           _selectedSpecialization != null &&
           _experienceController.text.isNotEmpty &&
           _selectedFile != null;
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

  Future<void> _submitProfile() async {
    if (_isFormValid()) {
      setState(() => _isLoading = true);
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null) throw Exception('No authenticated user found.');

        final userId = currentUser.id;
        final email = currentUser.email;
        if (email == null) throw Exception('No email associated with user.');

        // 1. Upload file
        final fileUrl = await _storageService.uploadProviderDocument(
          providerId: userId,
          file: _selectedFile!,
        );

        // 2. Create profile
        await _providerService.createProviderProfile(
          userId: userId,
          firstName: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          suffix: _suffixController.text.trim().isEmpty ? null : _suffixController.text.trim(),
          birthday: _selectedBirthday!,
          gender: _selectedGender!,
          email: email,
          licenseNumber: _licenseController.text.trim(),
          specialization: _selectedSpecialization!,
          yearsOfExperience: int.tryParse(_experienceController.text.trim()) ?? 0,
          verificationFileUrl: fileUrl,
        );

        if (!mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Profile Submitted'),
            content: const Text(
              'Your profile has been submitted for review. You will be able to '
              'access the dashboard once approved.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoleRedirectScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Continue'),
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
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Force them to complete profile
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
                      'Please complete your professional profile. Verification is required before approval.',
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
                    initialDate: _selectedBirthday ?? DateTime(1990),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedBirthday = picked;
                      _birthdayController.text =
                          DateFormat('MM/dd/yyyy').format(picked);
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
            const SizedBox(height: 32),

            SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: (_isFormValid() && !_isLoading) ? _submitProfile : null,
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
                   : const Text('Submit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
               ),
             ),
             const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
