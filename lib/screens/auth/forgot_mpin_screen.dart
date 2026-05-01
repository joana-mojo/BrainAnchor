import 'package:flutter/material.dart';
import 'package:brain_anchor/services/auth_service.dart';
import 'package:brain_anchor/theme/app_theme.dart';

/// Forgot-MPIN flow.
///
/// User enters their email + recovery password (the one they chose during
/// sign-up) and a new MPIN. The [AuthService.resetMpinWithRecoveryPassword]
/// call invokes the `reset_patient_mpin` Postgres RPC, which verifies the
/// recovery password and updates both the Supabase auth password (derived
/// from the new MPIN) and the stored MPIN hash.
class ForgotMpinScreen extends StatefulWidget {
  /// Email pre-filled from the previous screen.
  final String email;

  const ForgotMpinScreen({super.key, required this.email});

  @override
  State<ForgotMpinScreen> createState() => _ForgotMpinScreenState();
}

class _ForgotMpinScreenState extends State<ForgotMpinScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController =
      TextEditingController(text: widget.email);
  final _passwordController = TextEditingController();
  final _newMpinController = TextEditingController();
  final _confirmMpinController = TextEditingController();

  bool _passwordVisible = false;
  bool _isLoading = false;
  String? _errorMsg;

  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _newMpinController.dispose();
    _confirmMpinController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Recovery password is required.';
    if (v.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  String? _validateMpin(String? v) {
    if (v == null || v.length != 4) return 'MPIN must be 4 digits.';
    if (!RegExp(r'^\d{4}$').hasMatch(v)) return 'Digits only.';
    return null;
  }

  String? _validateConfirmMpin(String? v) {
    if (v != _newMpinController.text) return 'MPINs don\'t match.';
    return null;
  }

  Future<void> _resetMpin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final ok = await _authService.resetMpinWithRecoveryPassword(
        email: _emailController.text.trim(),
        recoveryPassword: _passwordController.text,
        newMpin: _newMpinController.text,
      );

      if (!ok) {
        setState(() {
          _errorMsg =
              'We couldn\'t verify that email and recovery password. '
              'Please double-check and try again.';
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'MPIN reset. Log in with your email and the new MPIN.',
          ),
        ),
      );
      // Pop back to the MPIN login screen so the user can enter the new
      // MPIN against the same email.
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMsg = 'Something went wrong: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
        title: const Text(
          'Forgot MPIN',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enter the recovery password you chose during '
                          'sign-up, then pick a new 4-digit MPIN.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: _validateEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  autofillHints: const [AutofillHints.password],
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    labelText: 'Recovery password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _passwordVisible = !_passwordVisible,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newMpinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  validator: _validateMpin,
                  decoration: const InputDecoration(
                    labelText: 'New 4-digit MPIN',
                    prefixIcon: Icon(Icons.dialpad_rounded),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmMpinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  validator: _validateConfirmMpin,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new MPIN',
                    prefixIcon: Icon(Icons.dialpad_rounded),
                    counterText: '',
                  ),
                ),

                if (_errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMsg!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetMpin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Reset MPIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
