import 'package:flutter/material.dart';
import 'package:brain_anchor/screens/patient/patient_home_screen.dart';
import 'package:brain_anchor/screens/patient/patient_ai_checker_screen.dart';
import 'package:brain_anchor/screens/patient/patient_booking_screen.dart';
import 'package:brain_anchor/screens/patient/patient_messages_screen.dart';
import 'package:brain_anchor/screens/patient/patient_profile_screen.dart';
import 'package:brain_anchor/screens/patient/progress_tracking_screen.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PatientHomeScreen(
        onOpenWellnessCheck: () => setState(() => _currentIndex = 2),
        onOpenConsults: () => setState(() => _currentIndex = 1),
        onOpenMoodJournal: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProgressTrackingScreen(),
            ),
          );
        },
      ),
      const PatientBookingScreen(),
      PatientAiCheckerScreen(
        onBackToHome: () => setState(() => _currentIndex = 0),
        onOpenConsults: () => setState(() => _currentIndex = 1),
      ),
      const PatientMessagesScreen(),
      const PatientProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.home, color: Color(0xFF5C88DA)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.calendar_month, color: Color(0xFF5C88DA)),
            label: 'Consults',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.psychology, color: Color(0xFF5C88DA)),
            label: 'Wellness',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.message, color: Color(0xFF5C88DA)),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.grey),
            selectedIcon: Icon(Icons.person, color: Color(0xFF5C88DA)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
