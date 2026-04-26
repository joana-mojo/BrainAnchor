import 'package:flutter/material.dart';
import 'package:brain_anchor/widgets/step_indicator.dart';
import 'package:brain_anchor/services/auth_service.dart';
import 'package:brain_anchor/services/patient_service.dart';
import 'package:brain_anchor/screens/patient/patient_main_screen.dart';

class Step5ConfirmMpinScreen extends StatefulWidget {
  final String originalMpin;
  final Map<String, dynamic> patientData;

  const Step5ConfirmMpinScreen({
    super.key,
    required this.originalMpin,
    required this.patientData,
  });

  @override
  State<Step5ConfirmMpinScreen> createState() => _Step5ConfirmMpinScreenState();
}

class _Step5ConfirmMpinScreenState extends State<Step5ConfirmMpinScreen> {
  String _mpin = '';
  String? _errorMsg;
  bool _isLoading = false;

  final _authService = AuthService();
  final _patientService = PatientService();

  void _onKeypadTap(String value) {
    if (_mpin.length < 4) {
      setState(() {
        _mpin += value;
        _errorMsg = null;
      });
    }
  }

  void _onDeleteTap() {
    if (_mpin.isNotEmpty) {
      setState(() {
        _mpin = _mpin.substring(0, _mpin.length - 1);
        _errorMsg = null;
      });
    }
  }

  Future<void> _finishSetup() async {
    if (_mpin == widget.originalMpin) {
      setState(() => _isLoading = true);
      
      try {
        final user = _authService.currentUser;
        if (user == null) throw Exception('No authenticated user found.');

        // 1. Create Patient Profile
        await _patientService.createPatientProfile(
          userId: user.id,
          phoneNumber: user.phone ?? '',
          firstName: widget.patientData['firstName'],
          middleName: widget.patientData['middleName'],
          lastName: widget.patientData['lastName'],
          nickname: widget.patientData['nickname'],
          suffix: widget.patientData['suffix'],
          birthday: widget.patientData['birthday'],
          sexAssignedAtBirth: widget.patientData['sexAssignedAtBirth'],
          genderIdentity: widget.patientData['genderIdentity'],
          email: widget.patientData['email'],
        );

        // 2. Hash and Save MPIN
        await _patientService.saveMpin(
          userId: user.id,
          mpin: _mpin,
        );

        if (!mounted) return;
        // 3. Redirect to Patient Dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PatientMainScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating account: $e')),
        );
        setState(() => _isLoading = false);
      }
    } else {
      setState(() {
        _errorMsg = 'MPIN does not match. Try again.';
        _mpin = ''; // Clear to retry
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepIndicator(currentStep: 5, totalSteps: 5),
              const SizedBox(height: 24),
              Text(
                'Confirm your MPIN',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Re-enter your MPIN to confirm.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              
              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _mpin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _errorMsg != null
                          ? theme.colorScheme.error
                          : isFilled ? theme.colorScheme.primary : theme.colorScheme.surface,
                      border: Border.all(
                        color: _errorMsg != null
                            ? theme.colorScheme.error
                            : isFilled ? theme.colorScheme.primary : theme.colorScheme.onBackground.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              
              if (_errorMsg != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _errorMsg!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Numeric Keypad
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) return const SizedBox.shrink(); // Empty slot
                  if (index == 11) {
                    return InkWell(
                      onTap: _onDeleteTap,
                      customBorder: const CircleBorder(),
                      child: Icon(Icons.backspace_outlined, color: theme.colorScheme.onBackground),
                    );
                  }
                  
                  final number = index == 10 ? '0' : '${index + 1}';
                  return InkWell(
                    onTap: () => _onKeypadTap(number),
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: Text(
                        number,
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_mpin.length == 4 && !_isLoading) ? _finishSetup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text('Finish / Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
