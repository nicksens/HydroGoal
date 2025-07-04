import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hydrogoal/screens/auth/login_screen.dart';
import 'package:hydrogoal/screens/main_menu/main_menu_screen.dart';
import 'package:hydrogoal/services/firebase_auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show a loading circle while checking the user's status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If the user has data (is logged in), show the Main Menu
        if (snapshot.hasData) {
          return const MainMenuScreen();
        }

        // If the user is not logged in, show the Login Screen
        return const LoginScreen();
      },
    );
  }
}
