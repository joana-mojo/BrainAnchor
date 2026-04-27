import 'package:flutter/material.dart';
import 'package:brain_anchor/widgets/step_indicator.dart';
import 'package:brain_anchor/services/auth_service.dart';
import 'package:brain_anchor/services/patient_service.dart';
import 'package:brain_anchor/screens/patient/patient_main_screen.dart';

/// Visible signup step 4 of 4: confirm the MPIN, then create the Supabase
/// auth user and write the patient profile + recovery password hash.
///
/// At this point [patientData] should contain everything we collected in
/// the earlier steps:
///   - email, recoveryPassword
///   - firstName, middleName, lastName, nickname, suffix
///   - birthday (DateTime), sexAssignedAtBirth, genderIdentity
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

  Future<void> _confirmAndFinish() async {
    if (_mpin != widget.originalMpin) {
      setState(() {
        _errorMsg = 'MPIN does not match. Try again.';
        _mpin = '';
      });
      return;
    }

    setState(() => _isLoading = true);

    final email = widget.patientData['email'] as String?;
    final recoveryPassword =
        widget.patientData['recoveryPassword'] as String?;
    final firstName = widget.patientData['firstName'] as String?;
    final lastName = widget.patientData['lastName'] as String?;
    final nickname = widget.patientData['nickname'] as String?;
    final birthday = widget.patientData['birthday'] as DateTime?;
    final sex = widget.patientData['sexAssignedAtBirth'] as String?;

    if (email == null ||
        email.isEmpty ||
        recoveryPassword == null ||
        recoveryPassword.isEmpty ||
        firstName == null ||
        lastName == null ||
        nickname == null ||
        birthday == null ||
        sex == null) {
      setState(() {
        _isLoading = false;
        _errorMsg =
            'Some sign-up data is missing. Please go back and try again.';
      });
      return;
    }

    try {
      final signUp = await _authService.signUpPatientWithMpin(
        email: email,
        mpin: _mpin,
      );
      if (signUp.user == null) {
        throw Exception('Sign-up failed. Please try again.');
      }

      // If "Confirm email" is on in the Supabase project, [signUp] won't
      // return a session. Try signing in once as a fallback.
      if (signUp.session == null) {
        try {
          await _authService.signInPatientWithMpin(
            email: email,
            mpin: _mpin,
          );
        } catch (_) {
          // Sign-in failed too -> almost certainly email-confirmation gate.
        }
      }

      final user = _authService.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 6),
            content: Text(
              'Account created, but Supabase requires email confirmation. '
              'Disable "Confirm email" in your Supabase project '
              '(Authentication → Providers → Email) and try again.',
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      await _patientService.createPatientProfile(
        userId: user.id,
        firstName: firstName,
        middleName: widget.patientData['middleName'] as String?,
        lastName: lastName,
        nickname: nickname,
        suffix: widget.patientData['suffix'] as String?,
        birthday: birthday,
        sexAssignedAtBirth: sex,
        genderIdentity: widget.patientData['genderIdentity'] as String?,
        email: email,
      );

      await _patientService.saveMpinAndRecovery(
        userId: user.id,
        mpin: _mpin,
        recoveryPassword: recoveryPassword,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PatientMainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      String friendly = 'Error creating account: $e';
      if (msg.contains('already') || msg.contains('registered')) {
        friendly =
            'An account already exists with this email. Try logging in instead.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendly)),
      );
      setState(() => _isLoading = false);
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
              const StepIndicator(currentStep: 4, totalSteps: 4),
              const SizedBox(height: 24),
              Text(
                'Confirm your MPIN',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Re-enter your MPIN to confirm.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),

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
                          : isFilled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surface,
                      border: Border.all(
                        color: _errorMsg != null
                            ? theme.colorScheme.error
                            : isFilled
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
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
                  if (index == 9) return const SizedBox.shrink();
                  if (index == 11) {
                    return InkWell(
                      onTap: _onDeleteTap,
                      customBorder: const CircleBorder(),
                      child: Icon(
                        Icons.backspace_outlined,
                        color: theme.colorScheme.onSurface,
                      ),
                    );
                  }

                  final number = index == 10 ? '0' : '${index + 1}';
                  return InkWell(
                    onTap: () => _onKeypadTap(number),
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: Text(
                        number,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_mpin.length == 4 && !_isLoading)
                      ? _confirmAndFinish
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Finish Sign-up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
