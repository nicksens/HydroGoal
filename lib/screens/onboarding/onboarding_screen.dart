import 'package:flutter/material.dart';
import 'package:hydrogoal/screens/auth/signup_screen.dart';
import 'package:hydrogoal/utils/colors.dart';
import 'package:liquid_swipe/liquid_swipe.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  late LiquidController _liquidController;

  @override
  void initState() {
    super.initState();
    _liquidController = LiquidController();
  }

  // Data for our onboarding slides
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'color': AppColors.lightBlue.withOpacity(0.3),
      'icon': Icons.track_changes_outlined,
      'title': 'Track Your Goals',
      'description':
          'Set personalized hydration goals and easily track your daily water intake to stay on top of your health.',
    },
    {
      'color': AppColors.accentAqua.withOpacity(0.4),
      'icon': Icons.camera_alt_outlined,
      'title': 'Stay Accountable',
      'description':
          'Use our unique "Hydration Proof" feature to verify your water consumption with a quick photo.',
    },
    {
      'color': AppColors.primaryBlue.withOpacity(0.5),
      'icon': Icons.calendar_today_outlined,
      'title': 'Build a Lasting Habit',
      'description':
          'View your progress on the calendar, celebrate your streaks, and build a lasting, healthy habit.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // UPDATED: Use List.generate to build pages with animated content
    final pages = List.generate(
      _onboardingData.length,
      (index) => Container(
        color: _onboardingData[index]['color'],
        child: AnimatedOpacity(
          // This is the key: only show content for the current page
          duration: const Duration(milliseconds: 500),
          opacity: _currentPage == index ? 1.0 : 0.0,
          child: _buildPageContent(
            icon: _onboardingData[index]['icon'],
            title: _onboardingData[index]['title'],
            description: _onboardingData[index]['description'],
          ),
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          LiquidSwipe(
            pages: pages,
            liquidController: _liquidController,
            onPageChangeCallback: (page) => setState(() => _currentPage = page),
            slideIconWidget:
                const Icon(Icons.arrow_back_ios, color: AppColors.primaryBlue),
            enableLoop: false,
            waveType: WaveType.liquidReveal,
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Expanded(flex: 5, child: SizedBox()), // Spacer
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (index) => _buildDot(index: index),
                        ),
                      ),
                      const SizedBox(height: 50),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child:
                                ScaleTransition(scale: animation, child: child),
                          );
                        },
                        child: _currentPage == pages.length - 1
                            ? _buildGetStartedButton()
                            : _buildSkipNextButtons(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- Helper Widgets (No changes needed here) ---

  Widget _buildPageContent(
      {required IconData icon,
      required String title,
      required String description}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 100, color: AppColors.primaryBlue),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: AppColors.darkText.withOpacity(0.7)),
          ),
        ),
      ],
    );
  }

  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 10,
      width: _currentPage == index ? 30 : 10,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.primaryBlue, width: 1.5),
      ),
    );
  }

  Widget _buildSkipNextButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            _liquidController.animateToPage(
                page: _onboardingData.length - 1, duration: 700);
          },
          child: const Text('SKIP',
              style: TextStyle(
                  color: AppColors.darkText, fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: () => _liquidController.animateToPage(
              page: _liquidController.currentPage + 1),
          child: const Text('NEXT'),
        ),
      ],
    );
  }

  Widget _buildGetStartedButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SignUpScreen()),
          );
        },
        child: const Text('GET STARTED'),
      ),
    );
  }
}
