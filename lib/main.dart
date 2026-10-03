import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timecade_mobile/screens/splash_screen.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/teacher/teacher_home_shell.dart';
import 'screens/student/student_home_shell.dart';

void main() {
  runApp(const TimeCadeApp());
}

class TimeCadeApp extends StatelessWidget {
  const TimeCadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..restoreSession(),
      child: MaterialApp(
        title: 'Academic Scheduler Agent',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _RootRouter(),
      ),
    );
  }
}

/// Shows the splash while the session restores (and for a minimum time),
/// then routes to Login, TeacherHomeShell, or StudentHomeShell.
class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  bool _minSplashDone = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _minSplashDone = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading || !_minSplashDone) {
      return const SplashScreen();
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    switch (auth.user!.role) {
      case 'teacher':
        return const TeacherHomeShell();
      case 'student':
        return const StudentHomeShell();
      default:
      // office_assistant or any other role isn't supported in this app.
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('This account role is not supported in the mobile app.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<AuthProvider>().logout(),
                    child: const Text('Log out'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}