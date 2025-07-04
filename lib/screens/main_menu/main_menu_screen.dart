import 'package:flutter/material.dart';
import 'package:hydrogoal/services/firebase_auth_service.dart';
import 'package:hydrogoal/screens/auth/auth_wrapper.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('HydroGoal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              // After signing out, go back to the AuthWrapper
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to your Main Menu!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
