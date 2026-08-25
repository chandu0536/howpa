import 'package:flutter/material.dart';
import 'package:howpa_nurse/screens/phone_number_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/images/onbording screen 1.png',
      title: 'Get Assigned\nVisits Instantly',
      subtitle:
          'Receive home-visit requests from doctors\nand manage your schedule with ease.',
    ),
    OnboardingData(
      image: 'assets/images/onbording screen 2.png',
      title: 'Provide Expert Care\nat Home',
      subtitle:
          'Deliver professional nursing services in the comfort of patients\' homes.',
    ),
    OnboardingData(
      image: 'assets/images/onbording screen 3.png',
      title: 'Track Your Earnings\nand Growth',
      subtitle:
          'Monitor your weekly payout, check service history, and grow your career.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _navigateToPhoneNumberScreen() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PhoneNumberScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToPhoneNumberScreen();
    }
  }

  void _onSkipPressed() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD), // Elegant off-white background
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, right: 24.0),
                child: AnimatedOpacity(
                  opacity: isLastPage ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: isLastPage,
                    child: TextButton(
                      onPressed: _onSkipPressed,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFFFF5C00), // Vibrant Orange
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Page contents
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Illustration Image Container
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            page.image,
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A), // Premium Dark Navy
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B), // Soft slate grey
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),

            // Bottom section containing Page Indicators and Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? const Color(0xFFFF5C00) // Active dot color
                              : const Color(0xFFE2E8F0), // Inactive dot color
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0052FF), // Vibrant Blue
                          Color(0xFFFF5C00), // Vibrant Orange
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x260052FF),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isLastPage) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
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

class OnboardingData {
  final String image;
  final String title;
  final String subtitle;

  OnboardingData({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
