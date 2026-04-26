import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brain_anchor/theme/app_theme.dart';
import 'package:brain_anchor/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: 'https://thuntsxzzfhbsliwlqte.supabase.co',
    anonKey: 'sb_publishable_6lFOmQnnvVix_EhchjAMTQ_CEKrM6Dp',
  );

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
