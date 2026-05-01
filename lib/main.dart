import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brain_anchor/theme/app_theme.dart';
import 'package:brain_anchor/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ??
      dotenv.env['SUPABASE_URL'] ??
      '';
  final supabaseAnonKey = dotenv.env['NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY'] ??
      dotenv.env['SUPABASE_ANON_KEY'] ??
      '';

  assert(
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
    'Missing Supabase credentials. Add NEXT_PUBLIC_SUPABASE_URL and '
    'NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY to your .env file.',
  );

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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
