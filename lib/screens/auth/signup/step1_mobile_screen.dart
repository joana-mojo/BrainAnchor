import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brain_anchor/widgets/step_indicator.dart';
import 'package:brain_anchor/screens/auth/signup/step2_otp_screen.dart';
import 'package:brain_anchor/services/auth_service.dart';

class Step1MobileScreen extends StatefulWidget {
  const Step1MobileScreen({super.key});

  @override
  State<Step1MobileScreen> createState() => _Step1MobileScreenState();
}

class _Step1MobileScreenState extends State<Step1MobileScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isValid = false;
  bool _isLoading = false;

  void _validateInput(String value) {
    setState(() {
      // Very basic validation: only numbers, exactly 10 digits
      final numberOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
      _isValid = numberOnly.length == 10;
    });
  }

  Future<void> _nextStep() async {
    if (_isValid) {
      setState(() => _isLoading = true);
      final rawNumber = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final fullPhoneNumber = '+63$rawNumber';
      
      try {
        await _authService.signInWithOtp(fullPhoneNumber);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Step2OtpScreen(phoneNumber: fullPhoneNumber),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
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
              const StepIndicator(currentStep: 1, totalSteps: 5),
              const SizedBox(height: 24),
              Text(
                'Enter your 10-digit mobile number',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 32),
              
              // Phone Input Field
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '+63',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: _validateInput,
                      style: theme.textTheme.titleMedium,
                      decoration: InputDecoration(
                        hintText: '999 123 4567',
                        hintStyle: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your mobile number in this format.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isValid && !_isLoading) ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary, // Blue CTA
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
