import 'package:flutter/material.dart';
import 'package:hydrogoal/screens/auth/auth_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // This function runs when the user finishes onboarding
  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: const [
                  OnboardingPage(
                    title: "Personalized Hydration Goals",
                    description:
                        "Set and track your daily water intake targets effortlessly.",
                    icon: Icons.track_changes,
                  ),
                  OnboardingPage(
                    title: "Stay Accountable",
                    description:
                        "Use our unique 'Hydration Proof' to verify you're drinking water.",
                    icon: Icons.camera_alt,
                  ),
                  OnboardingPage(
                    title: "Build a Lasting Habit",
                    description:
                        "View your progress on the calendar and build a healthy habit.",
                    icon: Icons.calendar_today,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text("SKIP"),
                  ),

                  // Next button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    child: Text(_currentPage < 2 ? "NEXT" : "GET STARTED"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A reusable widget for each onboarding page's content
class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: Colors.blueAccent),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
