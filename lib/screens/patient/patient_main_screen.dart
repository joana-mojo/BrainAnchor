import 'package:flutter/material.dart';
import 'package:brain_anchor/screens/patient/patient_home_screen.dart';
import 'package:brain_anchor/screens/patient/patient_ai_checker_screen.dart';
import 'package:brain_anchor/screens/patient/patient_booking_screen.dart';
import 'package:brain_anchor/screens/patient/patient_messages_screen.dart';
import 'package:brain_anchor/screens/patient/patient_profile_screen.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PatientHomeScreen(),
    PatientBookingScreen(),
    PatientAiCheckerScreen(),
    PatientMessagesScreen(),
    PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.secondary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Consults',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'AI Check',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
