import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:brain_anchor/screens/auth/role_redirect_screen.dart';
import 'package:brain_anchor/screens/auth/welcome_screen.dart';
import 'package:brain_anchor/screens/auth/login_mpin_screen.dart';
import 'package:brain_anchor/core/constants.dart';
import 'package:brain_anchor/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String? initialRole;
  const LoginScreen({super.key, this.initialRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  late String _selectedRole;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _emailWarning;
  String? _passwordWarning;
  final _authService = AuthService();

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? AppConstants.rolePatient;
    _emailController.addListener(_clearEmailWarningOnEdit);
    _passwordController.addListener(_clearPasswordWarningOnEdit);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearEmailWarningOnEdit);
    _passwordController.removeListener(_clearPasswordWarningOnEdit);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Clears the "email not registered" warning as soon as the user edits
  /// the email so a stale message doesn't sit on the form.
  void _clearEmailWarningOnEdit() {
    if (_emailWarning != null) {
      setState(() => _emailWarning = null);
    }
  }

  /// Clears the password warning as soon as the user edits the password.
  void _clearPasswordWarningOnEdit() {
    if (_passwordWarning != null) {
      setState(() => _passwordWarning = null);
    }
  }

  Future<void> _login() async {
    final isPatient = _selectedRole == AppConstants.rolePatient;
    final email = _emailController.text.trim();

    setState(() {
      _emailWarning = null;
      _passwordWarning = null;
    });

    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _emailWarning = 'Please enter a valid email address.');
      return;
    }

    if (isPatient) {
      setState(() => _isLoading = true);
      try {
        final exists = await _authService.isPatientEmailRegistered(email);
        if (!mounted) return;
        if (!exists) {
          setState(() {
            _emailWarning =
                'No patient account found with this email. '
                'Please sign up first.';
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        // Surface the real error in debug builds so misconfigured RPCs
        // (e.g. the function not yet deployed to Supabase) are obvious.
        debugPrint('isPatientEmailRegistered failed: $e');
        if (!mounted) return;
        setState(() {
          _emailWarning =
              'Could not verify email: ${_shortError(e)}';
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatientLoginMpinScreen(email: email),
        ),
      );
      return;
    }

    // ---- Provider (doctor) login: email + password ----
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordWarning = 'Please enter your password.');
      return;
    }

    setState(() => _isLoading = true);
    bool emailVerified = false;
    try {
      final exists = await _authService.isProviderEmailRegistered(email);
      if (!mounted) return;
      if (!exists) {
        setState(() {
          _emailWarning =
              'No provider account found with this email. '
              'Please sign up first.';
          _isLoading = false;
        });
        return;
      }
      emailVerified = true;

      final response = await _authService.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) throw Exception('Login failed.');

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleRedirectScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Provider login failed: $e');
      if (!mounted) return;
      if (!emailVerified) {
        // The RPC itself failed (e.g. function missing in Supabase).
        setState(() {
          _emailWarning =
              'Could not verify email: ${_shortError(e)}';
          _isLoading = false;
        });
      } else {
        // Email is real, so the failure is almost certainly the password.
        setState(() {
          _passwordWarning = 'Incorrect password. Please try again.';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  /// Returns a short, user-readable summary of a thrown exception.
  /// Falls back to the type name if we can't pull a `message` field.
  String _shortError(Object e) {
    final s = e.toString();
    if (s.length > 120) return '${s.substring(0, 117)}...';
    return s;
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleRedirectScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPatient = _selectedRole == AppConstants.rolePatient;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPatient
                    ? 'Login with your email and 4-digit MPIN.'
                    : 'Login with your email and password.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),

              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                          () => _selectedRole = AppConstants.rolePatient,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isPatient
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Patient',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPatient
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                          () => _selectedRole = AppConstants.roleDoctor,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isPatient
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Doctor',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: !isPatient
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: _emailWarning,
                ),
              ),
              const SizedBox(height: 16),

              if (!isPatient) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _passwordWarning,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isPatient ? 'Next' : 'Login'),
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Or continue with',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isGoogleLoading ? null : _continueWithGoogle,
                  icon: _isGoogleLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.g_mobiledata, size: 32),
                  label: const Text('Google'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
