import 'package:flutter/material.dart';

class DoctorEditProfileScreen extends StatefulWidget {
  const DoctorEditProfileScreen({super.key});

  @override
  State<DoctorEditProfileScreen> createState() => _DoctorEditProfileScreenState();
}

class _DoctorEditProfileScreenState extends State<DoctorEditProfileScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Dr. Patient Healer");
  final TextEditingController _emailController = TextEditingController(text: "dr.healer@brainanchor.com");
  final TextEditingController _phoneController = TextEditingController(text: "+63 917 123 4567");
  final TextEditingController _licenseController = TextEditingController(text: "PRC-1234567");
  final TextEditingController _yearsController = TextEditingController(text: "10");
  final TextEditingController _bioController = TextEditingController(
      text: "Dedicated psychiatrist specializing in mood disorders and trauma. I provide a safe, judgment-free space to help you anchor your mental wellbeing.");

  final List<String> _availableSpecialties = [
    'Anxiety', 'Depression', 'Substance Abuse', 'Trauma', 'Family Therapy', 'Bipolar Disorder', 'PTSD'
  ];
  final List<String> _selectedSpecialties = ['Anxiety', 'Depression', 'Trauma'];
  bool _availableToday = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _yearsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleSpecialty(String spec) {
    setState(() {
      if (_selectedSpecialties.contains(spec)) {
        _selectedSpecialties.remove(spec);
      } else {
        _selectedSpecialties.add(spec);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes Saved Successfully')));
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.person, size: 50, color: theme.colorScheme.primary),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.surface, width: 3),
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Basic Info
            _buildSectionTitle(theme, 'Basic Information'),
            _buildTextField(theme, 'Full Name', _nameController),
            const SizedBox(height: 16),
            _buildTextField(theme, 'Email Address', _emailController, enabled: false),
            const SizedBox(height: 16),
            _buildTextField(theme, 'Phone Number', _phoneController, keyboardType: TextInputType.phone),
            const SizedBox(height: 32),

            // Professional Info
            _buildSectionTitle(theme, 'License & Credentials'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Your medical license is currently verified by BrainAnchor administrators.',
                      style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(theme, 'License Number', _licenseController),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_file),
              label: const Text('Update License Document (PDF/JPG)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Specializations
            _buildSectionTitle(theme, 'Specializations'),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _availableSpecialties.map((spec) {
                final isSelected = _selectedSpecialties.contains(spec);
                return FilterChip(
                  label: Text(spec),
                  selected: isSelected,
                  onSelected: (bool selected) => _toggleSpecialty(spec),
                  selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onBackground.withOpacity(0.7),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Experience
            _buildSectionTitle(theme, 'Experience'),
            _buildTextField(theme, 'Years of Experience', _yearsController, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(theme, 'Short Bio', _bioController, maxLines: 4),
            const SizedBox(height: 32),

            // Availability
            _buildSectionTitle(theme, 'Availability'),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.onBackground.withOpacity(0.1)),
              ),
              child: SwitchListTile(
                title: const Text('Available Today', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Toggle to immediately appear available to patients.'),
                value: _availableToday,
                activeColor: theme.colorScheme.primary,
                onChanged: (val) => setState(() => _availableToday = val),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set Working Days & Time Slots'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const SizedBox(height: 48),

            // Main CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated Successfully')));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextField(ThemeData theme, String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType, bool enabled = true}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: enabled ? theme.colorScheme.surface : theme.colorScheme.onBackground.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.onBackground.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.onBackground.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
