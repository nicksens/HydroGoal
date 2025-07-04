import 'package:flutter/material.dart';
import 'package:hydrogoal/screens/auth/auth_wrapper.dart';
import 'package:hydrogoal/screens/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DecisionScreen extends StatefulWidget {
  const DecisionScreen({super.key});

  @override
  State<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends State<DecisionScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Check for the flag. If it's null (or false), default to false.
    final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    // Use `mounted` to ensure the widget is still in the tree before navigating.
    if (!mounted) return;

    if (hasSeenOnboarding) {
      // User has seen onboarding, so go to the AuthWrapper.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    } else {
      // User has NOT seen onboarding, so show it.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while we check the device storage.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
