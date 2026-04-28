import 'package:flutter/material.dart';
import 'package:brain_anchor/screens/auth/role_redirect_screen.dart';
import 'package:brain_anchor/screens/auth/forgot_mpin_screen.dart';
import 'package:brain_anchor/theme/app_theme.dart';
import 'package:brain_anchor/services/auth_service.dart';

/// Patient login: confirm email + 4-digit MPIN.
///
/// The Supabase password is derived from the MPIN, so this single screen
/// completes the login (no separate password screen).
class PatientLoginMpinScreen extends StatefulWidget {
  /// Email entered on the previous screen.
  final String email;

  const PatientLoginMpinScreen({super.key, required this.email});

  @override
  State<PatientLoginMpinScreen> createState() => _PatientLoginMpinScreenState();
}

class _PatientLoginMpinScreenState extends State<PatientLoginMpinScreen> {
  String _mpin = '';
  String? _errorMsg;
  bool _isLoading = false;

  final _authService = AuthService();

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
    if (_mpin.length != 4) return;
    setState(() => _isLoading = true);

    try {
      final response = await _authService.signInPatientWithMpin(
        email: widget.email,
        mpin: _mpin,
      );
      if (response.user == null) {
        throw Exception('Invalid email or MPIN.');
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleRedirectScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Incorrect email or MPIN. Please try again.';
        _mpin = '';
        _isLoading = false;
      });
    }
  }

  String _maskEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 1) return email;
    final first = email.substring(0, 1);
    final domain = email.substring(atIndex);
    return '$first***$domain';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maskedEmail = _maskEmail(widget.email);

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
          child: Stack(
            children: [
              Column(
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
                    'Enter your 4-digit MPIN for $maskedEmail.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
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
                            color: isFilled
                                ? AppTheme.primaryColor
                                : Colors.white,
                            border: Border.all(
                              color: isFilled
                                  ? AppTheme.primaryColor
                                  : AppTheme.primaryColor.withValues(alpha: 0.2),
                              width: 2,
                            ),
                            boxShadow: isFilled
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
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

                  const SizedBox(height: 24),

                  Expanded(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        if (index == 9) return const SizedBox.shrink();
                        if (index == 11) {
                          return Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              onTap: _onDeleteTap,
                              splashColor:
                                  AppTheme.errorColor.withValues(alpha: 0.1),
                              highlightColor:
                                  AppTheme.errorColor.withValues(alpha: 0.05),
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
                          shadowColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () => _onKeypadTap(number),
                            highlightColor:
                                AppTheme.primaryColor.withValues(alpha: 0.1),
                            splashColor:
                                AppTheme.primaryColor.withValues(alpha: 0.2),
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
                      onPressed:
                          (_mpin.length == 4 && !_isLoading) ? _login : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.3),
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
                          color: _mpin.length == 4
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ForgotMpinScreen(email: widget.email),
                              ),
                            );
                          },
                    child: const Text(
                      'Forgot MPIN?',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                const Positioned(
                  top: 245,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xCCFFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
