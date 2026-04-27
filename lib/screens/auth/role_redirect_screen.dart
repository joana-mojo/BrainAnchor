import 'package:flutter/material.dart';
import 'package:brain_anchor/services/auth_service.dart';
import 'package:brain_anchor/services/provider_service.dart';
import 'package:brain_anchor/screens/auth/welcome_screen.dart';
import 'package:brain_anchor/screens/auth/doctor_complete_profile_screen.dart';
import 'package:brain_anchor/screens/auth/signup/step3_personal_info_screen.dart';
import 'package:brain_anchor/screens/patient/patient_main_screen.dart';
import 'package:brain_anchor/screens/doctor/doctor_main_screen.dart';
import 'package:brain_anchor/theme/app_theme.dart';

/// Decides where to send an authenticated user.
///
/// Decision tree:
/// - No `profiles` row -> if metadata says provider, send to complete profile;
///   otherwise back to welcome (treat as orphaned auth user).
/// - role == 'patient'  -> [PatientMainScreen]
/// - role == 'provider' && approval_status == 'approved' -> [DoctorMainScreen]
/// - role == 'provider' && approval_status == 'pending'  -> pending screen
/// - role == 'provider' && approval_status == 'rejected' -> rejected screen
class RoleRedirectScreen extends StatefulWidget {
  const RoleRedirectScreen({super.key});

  @override
  State<RoleRedirectScreen> createState() => _RoleRedirectScreenState();
}

class _RoleRedirectScreenState extends State<RoleRedirectScreen> {
  final _authService = AuthService();
  final _providerService = ProviderService();

  bool _isLoading = true;
  _RedirectState? _state;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveAndRedirect());
  }

  Future<void> _resolveAndRedirect() async {
    final user = _authService.currentUser;
    if (user == null) {
      _replaceWith(const WelcomeScreen());
      return;
    }

    try {
      final role = await _authService.getCurrentUserRole();

      if (role == null) {
        final metaRole = user.userMetadata?['role'];
        if (metaRole == 'provider') {
          _replaceWith(const DoctorCompleteProfileScreen());
          return;
        }
        if (metaRole == 'patient') {
          // Auth user exists but profile was never completed -> resume signup.
          _replaceWith(Step3PersonalInfoScreen(prefillEmail: user.email));
          return;
        }
        setState(() {
          _isLoading = false;
          _state = _RedirectState.unknownRole;
        });
        return;
      }

      if (role == 'patient') {
        _replaceWith(const PatientMainScreen());
        return;
      }

      if (role == 'provider') {
        final status = await _providerService.getProviderStatus(user.id);
        switch (status) {
          case 'approved':
            _replaceWith(const DoctorMainScreen());
            return;
          case 'rejected':
            setState(() {
              _isLoading = false;
              _state = _RedirectState.rejected;
            });
            return;
          case 'pending':
          default:
            setState(() {
              _isLoading = false;
              _state = _RedirectState.pending;
            });
            return;
        }
      }

      setState(() {
        _isLoading = false;
        _state = _RedirectState.unknownRole;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _state = _RedirectState.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _replaceWith(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  Future<void> _signOutAndRestart() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text(
                'Preparing your account...',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    switch (_state) {
      case _RedirectState.pending:
        return _StatusScaffold(
          icon: Icons.hourglass_top_rounded,
          iconColor: AppTheme.moodStressed,
          title: 'Awaiting approval',
          message:
              'Your provider profile is under review by the Brain Anchor admin '
              'team. You will be able to access the dashboard as soon as your '
              'license has been verified.',
          primaryLabel: 'Sign out',
          onPrimary: _signOutAndRestart,
        );
      case _RedirectState.rejected:
        return _StatusScaffold(
          icon: Icons.cancel_rounded,
          iconColor: AppTheme.errorColor,
          title: 'Account rejected',
          message:
              'Unfortunately, your provider registration was rejected. Please '
              'contact support@brainanchor.app if you believe this is a '
              'mistake.',
          primaryLabel: 'Sign out',
          onPrimary: _signOutAndRestart,
        );
      case _RedirectState.unknownRole:
        return _StatusScaffold(
          icon: Icons.help_outline_rounded,
          iconColor: AppTheme.textSecondary,
          title: 'Account incomplete',
          message:
              'We could not determine your role. Please sign in again or '
              'finish creating your account.',
          primaryLabel: 'Back to login',
          onPrimary: _signOutAndRestart,
        );
      case _RedirectState.error:
      case null:
        return _StatusScaffold(
          icon: Icons.error_outline_rounded,
          iconColor: AppTheme.errorColor,
          title: 'Something went wrong',
          message: _errorMessage ?? 'Please try again in a moment.',
          primaryLabel: 'Retry',
          onPrimary: () {
            setState(() {
              _isLoading = true;
              _state = null;
              _errorMessage = null;
            });
            _resolveAndRedirect();
          },
          secondaryLabel: 'Sign out',
          onSecondary: _signOutAndRestart,
        );
    }
  }
}

enum _RedirectState { pending, rejected, unknownRole, error }

class _StatusScaffold extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _StatusScaffold({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 56, color: iconColor),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPrimary,
                    child: Text(primaryLabel),
                  ),
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
