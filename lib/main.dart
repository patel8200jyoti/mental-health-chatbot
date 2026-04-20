import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:mindease/screens/user/splash_screen.dart';

import 'screens/user/chat_screen.dart';
import 'screens/user/login_screen.dart';
import 'screens/user/signup_screen.dart';
import 'screens/user/mood_screen.dart';
import 'screens/user/journal_screen.dart';
import 'screens/user/toolkit_screen.dart';
import 'screens/user/findDoctor_screen.dart';
import 'screens/user/profile_screen.dart';

import 'screens/admin/shell_admin.dart';
import 'screens/admin/admin_login.dart';

import 'screens/professional/login_proff.dart';
import 'screens/professional/signup_proff.dart';
import 'screens/professional/pending_proff.dart';
import 'screens/professional/shell_proff.dart';



void main() {
  usePathUrlStrategy();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MindEase",
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        // ── User ────────────────────────────────
        '/':               (context)=> const SplashScreen(),
        '/login':          (context) => const LoginScreen(),
        '/signup':         (context) => SignupScreen(),
        '/chat':           (context) => const ChatScreen(),
        '/mood':           (context) => const MoodScreen(),
        '/journal':        (context) => const JournalScreen(),
        '/toolkit':        (context) => const ToolkitScreen(),
        '/doctor':         (context) => const FindProfessionalScreen(),
        '/profile':        (context) => const PersonalInformationScreen(),

        // ── Admin ────────────────────────────────
        '/admin_dashboard': (context) => const AdminShell(), 
        '/admin_login':     (context) => const AdminLogin(),

        // ── Professional ─────────────────────────
        '/proff_login':    (context) => const ProffLogin(),
        '/proff_signup':   (context) => const ProffSignupScreen(),
        '/proff_pending':  (context) => const ProffPendingScreen(),
        '/proff':          (context) => const ProfessionalShell(),
      },
    );
  }
}