import 'package:flutter/material.dart';
import 'package:brain_anchor/screens/auth/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Welcome to BrainAnchor',
      'description':
          'Your personal and secure digital mental health safespace. We are here to support your mental wellbeing journey.',
      'image': 'assets/images/logo.png',
    },
    {
      'title': 'For Patients',
      'description':
          'Track your mood daily, perform AI-assisted symptom checks, and securely consult with verified mental health professionals.',
      'icon': Icons.health_and_safety_outlined,
    },
    {
      'title': 'For Doctors',
      'description':
          'Manage your patients efficiently, view real-time health data, and provide telemedicine securely in one centralized app.',
      'icon': Icons.medical_services_outlined,
    },
  ];

  void _onNext() {
    if (_currentPage == _onboardingData.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _onSkip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _onSkip,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _onboardingData[index].containsKey('image')
                                ? Image.asset(
                                    _onboardingData[index]['image'] as String,
                                    width: 140,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      // Fallback to the original BrainAnchor icon
                                      Icons.psychology_alt_outlined, 
                                      size: 100,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : Icon(
                                    _onboardingData[index]['icon'] as IconData,
                                    size: 100,
                                    color: theme.colorScheme.primary,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        Text(
                          _onboardingData[index]['title'] as String,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onBackground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _onboardingData[index]['description'] as String,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(
                              0.7,
                            ),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Pagination and Actions
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Get Started button
                  FloatingActionButton(
                    onPressed: _onNext,
                    backgroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    child: Icon(
                      _currentPage == _onboardingData.length - 1
                          ? Icons.check
                          : Icons.arrow_forward_ios,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
