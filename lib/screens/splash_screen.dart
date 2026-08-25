import 'dart:async';
import 'package:flutter/material.dart';
import 'package:howpa_nurse/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set up intro animations for a premium feel
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // Start timer to navigate to OnboardingScreen after 3 seconds
    Timer(const Duration(seconds: 3), _navigateToOnboarding);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToOnboarding() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top-left faint ring decoration
          Positioned(
            top: -70,
            left: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x0A0052FF),
                  width: 24,
                ),
              ),
            ),
          ),
          
          // Additional offset top-left faint ring for visual depth
          Positioned(
            top: -110,
            left: -110,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x080052FF),
                  width: 16,
                ),
              ),
            ),
          ),

          // Bottom-right faint ring decoration
          Positioned(
            bottom: -70,
            right: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x0A0052FF),
                  width: 24,
                ),
              ),
            ),
          ),

          // Additional offset bottom-right faint ring
          Positioned(
            bottom: -110,
            right: -110,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x080052FF),
                  width: 16,
                ),
              ),
            ),
          ),

          // Central Logo and loaders
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: screenWidth * 0.72,
                      child: Image.asset(
                        'assets/images/splish screen log.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const ThreeDotLoader(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ThreeDotLoader extends StatefulWidget {
  const ThreeDotLoader({super.key});

  @override
  State<ThreeDotLoader> createState() => _ThreeDotLoaderState();
}

class _ThreeDotLoaderState extends State<ThreeDotLoader> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: -10.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF0052FF), // Blue
      const Color(0xFF8C3CFF), // Purple/Violet
      const Color(0xFFFF5C00), // Orange
    ];

    final shadowColors = [
      const Color(0x400052FF), // Blue shadow
      const Color(0x408C3CFF), // Purple shadow
      const Color(0x40FF5C00), // Orange shadow
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6.0),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[index],
                  boxShadow: [
                    BoxShadow(
                      color: shadowColors[index],
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
