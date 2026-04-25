import 'package:flutter/material.dart';
import 'package:brain_anchor/widgets/step_indicator.dart';
import 'package:brain_anchor/screens/auth/login_screen.dart';

class Step5ConfirmMpinScreen extends StatefulWidget {
  final String originalMpin;

  const Step5ConfirmMpinScreen({super.key, required this.originalMpin});

  @override
  State<Step5ConfirmMpinScreen> createState() => _Step5ConfirmMpinScreenState();
}

class _Step5ConfirmMpinScreenState extends State<Step5ConfirmMpinScreen> {
  String _mpin = '';
  String? _errorMsg;

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

  void _finishSetup() {
    if (_mpin == widget.originalMpin) {
      // Setup successful, redirect to Login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
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
                  onPressed: _mpin.length == 4 ? _finishSetup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: const Text('Finish / Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
