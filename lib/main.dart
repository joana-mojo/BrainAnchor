import 'package:flutter/material.dart';
import 'package:brain_anchor/theme/app_theme.dart';
import 'package:brain_anchor/screens/splash_screen.dart';
// other imports will be added later

void main() {
  runApp(const BrainAnchorApp());
}

class BrainAnchorApp extends StatelessWidget {
  const BrainAnchorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrainAnchor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
