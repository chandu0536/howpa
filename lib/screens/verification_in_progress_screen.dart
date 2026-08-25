import 'package:flutter/material.dart';
import 'package:howpa_nurse/screens/nurse_dashboard_screen.dart';

class VerificationInProgressScreen extends StatefulWidget {
  const VerificationInProgressScreen({super.key});

  @override
  State<VerificationInProgressScreen> createState() => _VerificationInProgressScreenState();
}

class _VerificationInProgressScreenState extends State<VerificationInProgressScreen> {
  bool _isApproved = false;

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const NurseDashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
      (route) => false,
    );
  }

  void _simulateAdminApproval() {
    setState(() {
      _isApproved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Admin Approved your account! Redirecting to Home Dashboard...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateToDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Top Admin Approval Simulation Banner (For testing & demonstration)
              GestureDetector(
                onTap: _simulateAdminApproval,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isApproved ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isApproved ? Icons.verified_user_rounded : Icons.admin_panel_settings_rounded,
                        size: 16,
                        color: _isApproved ? const Color(0xFF16A34A) : const Color(0xFF0052FF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isApproved
                            ? 'Approved by Admin'
                            : 'Simulate Admin Approval',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isApproved ? const Color(0xFF15803D) : const Color(0xFF0052FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Top Illustration (Verification in progress.png)
              Center(
                child: Image.asset(
                  'assets/images/Verification in progress.png',
                  height: 230,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 28),

              // Green Check Circle Badge Icon
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3316A34A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(height: 16),

              // Main Title
              const Text(
                'Verification in Progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Our team is reviewing your documents.\nThis usually takes 24–48 hours.\nYou’ll be notified once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 28),

              // Notification Card Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE0EDFF),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0EDFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF0052FF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'We’ll notify you!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You will receive a notification once your account is approved.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 3 Feature Columns Row (Secure | Verified by Experts | Timely Updates)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFeatureItem(
                      icon: Icons.shield_outlined,
                      title: 'Secure',
                      description: 'Your documents are safe with us.',
                    ),
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  Expanded(
                    child: _buildFeatureItem(
                      icon: Icons.people_outline_rounded,
                      title: 'Verified by Experts',
                      description: 'Our team carefully reviews each document.',
                    ),
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  Expanded(
                    child: _buildFeatureItem(
                      icon: Icons.mail_outline_rounded,
                      title: 'Timely Updates',
                      description: 'You’ll be notified at every step.',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Bottom Action Button: Go to Dashboard
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0052FF), // Vibrant Blue
                      Color(0xFFFF5C00), // Vibrant Orange
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x260052FF),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _navigateToDashboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Go to Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0052FF),
            size: 22,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
