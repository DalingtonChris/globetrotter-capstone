import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/splash_screen.dart';
import 'state/auth_controller.dart';

class FindYourWayApp extends StatelessWidget {
  const FindYourWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find Your Way',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    context.read<AuthController>().bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthController>().status;

    switch (status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.unauthenticated:
        return const AuthScreen();
      case AuthStatus.authenticated:
        return const HomeShell();
    }
  }
}
