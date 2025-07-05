import 'package:flutter/material.dart';
import 'package:hydrogoal/screens/auth/signup_screen.dart';
import 'package:hydrogoal/utils/colors.dart';

// Reusing the WaveClipper from the login screen for consistency
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 50);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 100);
    var secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // This function sets a flag and navigates to the main app
  void _completeOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) =>
              const SignUpScreen()), // Or LoginScreen if you prefer
    );
  }

  // Data for our onboarding slides
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'icon': Icons.track_changes,
      'title': 'Track Your Goals',
      'description':
          'Set personalized hydration goals and easily track your daily water intake to stay on top of your health.',
    },
    {
      'icon': Icons.camera_alt_outlined,
      'title': 'Stay Accountable',
      'description':
          'Use our unique "Hydration Proof" feature to verify your water consumption with a quick photo.',
    },
    {
      'icon': Icons.calendar_today_outlined,
      'title': 'Build a Habit',
      'description':
          'View your progress on the calendar, celebrate your streaks, and build a lasting, healthy habit.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Wave
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 200,
                color: AppColors.primaryBlue.withOpacity(0.2),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _onboardingData.length,
                    onPageChanged: (int page) =>
                        setState(() => _currentPage = page),
                    itemBuilder: (_, index) {
                      return OnboardingPage(
                        icon: _onboardingData[index]['icon'],
                        title: _onboardingData[index]['title'],
                        description: _onboardingData[index]['description'],
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Page Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _onboardingData.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 10,
                              width: _currentPage == index ? 30 : 10,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: _currentPage == index
                                    ? AppColors.primaryBlue
                                    : AppColors.lightBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Next/Get Started Button
                        ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _onboardingData.length - 1) {
                              _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut);
                            } else {
                              _completeOnboarding();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: AppColors.primaryBlue,
                            elevation: 5,
                          ),
                          child: Text(
                            _currentPage < _onboardingData.length - 1
                                ? 'NEXT'
                                : 'GET STARTED',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Skip Button
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: const Text('SKIP',
                              style: TextStyle(
                                  color: AppColors.lightText,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// A reusable widget for each onboarding page's content
class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: AppColors.primaryBlue),
          const SizedBox(height: 40),
          Text(title,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(description,
              style: const TextStyle(fontSize: 16, color: AppColors.lightText),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
