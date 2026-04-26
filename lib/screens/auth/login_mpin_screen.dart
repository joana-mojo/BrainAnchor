import 'package:flutter/material.dart';
import 'package:brain_anchor/screens/patient/patient_main_screen.dart';
import 'package:brain_anchor/theme/app_theme.dart';
import 'package:brain_anchor/services/auth_service.dart';
import 'package:brain_anchor/services/patient_service.dart';

class PatientLoginMpinScreen extends StatefulWidget {
  final String phoneNumber;

  const PatientLoginMpinScreen({super.key, required this.phoneNumber});

  @override
  State<PatientLoginMpinScreen> createState() => _PatientLoginMpinScreenState();
}

class _PatientLoginMpinScreenState extends State<PatientLoginMpinScreen> {
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

  Future<void> _login() async {
    if (_mpin.length == 4) {
      setState(() => _isLoading = true);

      try {
        final user = _authService.currentUser;
        if (user == null) throw Exception('No authenticated user found.');

        final isValid = await _patientService.verifyMpin(
          userId: user.id,
          mpin: _mpin,
        );

        if (!mounted) return;

        if (isValid) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const PatientMainScreen()),
            (route) => false,
          );
        } else {
          setState(() {
            _errorMsg = 'Incorrect MPIN. Please try again.';
            _mpin = '';
          });
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String maskedPhone = widget.phoneNumber.length >= 4 
        ? widget.phoneNumber.substring(widget.phoneNumber.length - 4) 
        : 'XXXX';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome Back',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your 4-digit MPIN to access your wellness account ending in $maskedPhone.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // PIN Dots Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _mpin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? AppTheme.primaryColor : Colors.white,
                        border: Border.all(
                          color: isFilled ? AppTheme.primaryColor : AppTheme.primaryColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: isFilled ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ] : null,
                      ),
                    );
                  }),
                ),
              ),
              
              if (_errorMsg != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMsg!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: AppTheme.primaryColor),
              ],
              
              const SizedBox(height: 24),
              
              // Numeric Keypad
              Expanded(
                child: GridView.builder(
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
                      return Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          onTap: _onDeleteTap,
                          splashColor: AppTheme.errorColor.withValues(alpha: 0.1),
                          highlightColor: AppTheme.errorColor.withValues(alpha: 0.05),
                          child: const Icon(
                            Icons.backspace_rounded, 
                            color: AppTheme.textSecondary,
                            size: 28,
                          ),
                        ),
                      );
                    }
                    
                    final number = index == 10 ? '0' : '${index + 1}';
                    return Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: () => _onKeypadTap(number),
                        highlightColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        splashColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        child: Center(
                          child: Text(
                            number,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _mpin.length == 4 ? _login : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: _mpin.length == 4 ? 8 : 0,
                    shadowColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _mpin.length == 4 ? Colors.white : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
