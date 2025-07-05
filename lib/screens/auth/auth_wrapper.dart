import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hydrogoal/screens/home_screen.dart';
import 'package:hydrogoal/screens/main_menu/today_screen.dart';
import 'package:hydrogoal/screens/onboarding/onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading circle while checking for a user
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If snapshot has data, it means the user is logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // If no data, the user is logged out, so show the onboarding screen
        return const OnboardingScreen();
      },
    );
  }
}
