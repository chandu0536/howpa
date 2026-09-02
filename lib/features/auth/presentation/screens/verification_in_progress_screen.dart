import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/user_profile_manager.dart';
import '../../../profile/data/models/nurse_profile_model.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../dashboard/presentation/screens/nurse_dashboard_screen.dart';

class VerificationInProgressScreen extends StatefulWidget {
  const VerificationInProgressScreen({super.key});

  @override
  State<VerificationInProgressScreen> createState() => _VerificationInProgressScreenState();
}

class _VerificationInProgressScreenState extends State<VerificationInProgressScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isChecking = false;
  NurseProfileModel? _profile;
  String _approvalStatus = 'UNDER_REVIEW';
  bool _isVerified = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  bool get _isApproved =>
      _approvalStatus.toUpperCase() == 'APPROVED' || _isVerified;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    // Check status from backend immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerificationStatus(isInitial: true);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Query the backend API: GET /api/nurse/profile
  Future<void> _checkVerificationStatus({bool isInitial = false}) async {
    if (_isChecking) return;

    setState(() {
      if (isInitial) {
        _isLoading = true;
      } else {
        _isChecking = true;
      }
      _errorMessage = null;
    });

    try {
      NurseProfileModel? profile;
      if (mounted) {
        final authRepo = context.read<AuthRepository>();
        profile = await authRepo.getVerificationProfile();
      }

      if (profile == null && mounted) {
        final profileRepo = context.read<ProfileRepository>();
        profile = await profileRepo.getProfile();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isChecking = false;
          if (profile != null) {
            _profile = profile;
            _approvalStatus = profile.approvalStatus;
            _isVerified = profile.isVerified;
          }
        });

        if (!isInitial) {
          if (_isApproved) {
            _showSuccessSnackBar('Your account is approved! Dashboard is now unlocked.');
          } else {
            _showInfoSnackBar('Status: Under Review. Our team is still reviewing your documents.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isChecking = false;
          _errorMessage = e.toString();
        });
        if (!isInitial) {
          _showInfoSnackBar('Could not refresh status. Please check your internet.');
        }
      }
    }
  }

  void _navigateToDashboard() {
    if (!_isApproved) {
      _showPendingApprovalNotice();
      return;
    }

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

  void _showPendingApprovalNotice() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_clock_rounded,
                color: Color(0xFFD97706),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Account Verification Pending',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your profile is currently UNDER_REVIEW by our administrative team. Once your credentials are verified, the dashboard will be automatically unlocked.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _checkVerificationStatus();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Check Approval Status Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _simulateAdminApproval() {
    final newStatus = _isApproved ? 'UNDER_REVIEW' : 'APPROVED';
    final newVerified = !_isApproved;

    setState(() {
      _approvalStatus = newStatus;
      _isVerified = newVerified;
    });

    UserProfileManager.instance.setApprovalStatus(newStatus, verified: newVerified);

    if (_isApproved) {
      _showSuccessSnackBar('Simulated Admin Approval! Dashboard is now unlocked.');
    } else {
      _showInfoSnackBar('Reset to Under Review state.');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userManager = UserProfileManager.instance;
    final nurseName = _profile?.fullName.isNotEmpty == true
        ? _profile!.fullName
        : userManager.fullName;
    final nurseCode = _profile?.nurseCode.isNotEmpty == true
        ? _profile!.nurseCode
        : userManager.nurseCode;
    final specialization = _profile?.specialization.isNotEmpty == true
        ? _profile!.specialization
        : userManager.specialization;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _checkVerificationStatus(),
          color: const Color(0xFF0052FF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Top Admin Approval Simulation & Status Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Badge
                      _buildStatusBadge(),

                      // Test Mode / Simulation Toggle
                      GestureDetector(
                        onTap: _simulateAdminApproval,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isApproved
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isApproved
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isApproved
                                    ? Icons.verified_rounded
                                    : Icons.tune_rounded,
                                size: 14,
                                color: _isApproved
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isApproved ? 'Demo: Approved' : 'Test Toggle',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _isApproved
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Top Illustration (Verification in progress.png)
                  Center(
                    child: Image.asset(
                      'assets/images/Verification in progress.png',
                      height: 210,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status Icon Badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isApproved ? const Color(0xFF16A34A) : const Color(0xFF0052FF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _isApproved
                              ? const Color(0x3316A34A)
                              : const Color(0x330052FF),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isApproved ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Main Title
                  Text(
                    _isApproved
                        ? 'Verification Approved!'
                        : 'Verification in Progress',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle description
                  Text(
                    _isApproved
                        ? 'Congratulations! Your profile documents have been verified and approved by the HOWPA medical board. You can now start receiving visit requests.'
                        : 'Our team is reviewing your documents.\nThis usually takes 24–48 hours.\nYou’ll be notified once approved.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF0052FF),
                        ),
                      ),
                    )
                  else ...[
                    // Nurse Application Card (Synced from API)
                    _buildNurseInfoCard(nurseName, nurseCode, specialization),

                    const SizedBox(height: 20),

                    // Status Timeline Steps
                    _buildStatusTimeline(),

                    const SizedBox(height: 24),

                    // Notification Banner Card
                    _buildNotificationBanner(),

                    const SizedBox(height: 24),

                    // 3 Feature Highlights (Secure | Verified by Experts | Timely Updates)
                    _buildFeaturesRow(),

                    const SizedBox(height: 28),

                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Refresh / Check Status Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isChecking ? null : () => _checkVerificationStatus(),
                        icon: _isChecking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0052FF),
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                size: 20,
                                color: Color(0xFF0052FF),
                              ),
                        label: Text(
                          _isChecking ? 'Checking API Status...' : 'Check Approval Status',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0052FF),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Main Action Button: Go to Dashboard (Disabled if not approved)
                    _buildDashboardButton(),
                  ],

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Status badge at top of the screen
  Widget _buildStatusBadge() {
    if (_isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
            SizedBox(width: 6),
            Text(
              'Status: Approved',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF0052FF)),
          SizedBox(width: 6),
          Text(
            'Status: Under Review',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0052FF),
            ),
          ),
        ],
      ),
    );
  }

  /// Nurse details summary card (from API response)
  Widget _buildNurseInfoCard(String name, String code, String spec) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isApproved
                    ? [const Color(0xFF16A34A), const Color(0xFF22C55E)]
                    : [const Color(0xFF0052FF), const Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'N',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (code.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  spec.isNotEmpty ? spec : 'Home Care Specialist',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _isApproved ? 'VERIFIED' : 'PENDING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _isApproved ? const Color(0xFF15803D) : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4-step status timeline
  Widget _buildStatusTimeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Progress',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 14),
          _buildTimelineStep(
            title: '1. Registration & Profile Setup',
            subtitle: 'Completed successfully',
            isCompleted: true,
            isActive: false,
          ),
          _buildTimelineStep(
            title: '2. Professional Documents Uploaded',
            subtitle: 'Certificates & Aadhaar submitted',
            isCompleted: true,
            isActive: false,
          ),
          _buildTimelineStep(
            title: '3. Admin Review & Verification',
            subtitle: _isApproved
                ? 'Approved by HOWPA Medical Board'
                : 'Under active review (24-48 hrs)',
            isCompleted: _isApproved,
            isActive: !_isApproved,
          ),
          _buildTimelineStep(
            title: '4. Dashboard Access & Patient Visits',
            subtitle: _isApproved
                ? 'Unlocked & ready to accept requests'
                : 'Locked until verification completes',
            isCompleted: _isApproved,
            isActive: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF16A34A)
                    : (isActive ? const Color(0xFF0052FF) : const Color(0xFFCBD5E1)),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : (isActive
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock, size: 11, color: Colors.white)),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isCompleted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isCompleted || isActive
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive
                        ? const Color(0xFF0052FF)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Notification banner
  Widget _buildNotificationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFE0EDFF),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFE0EDFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isApproved ? Icons.verified_user_rounded : Icons.notifications_none_rounded,
              color: _isApproved ? const Color(0xFF16A34A) : const Color(0xFF0052FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isApproved ? 'Account Activated!' : 'We’ll notify you!',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isApproved
                      ? 'Your account is ready. Tap Go to Dashboard below to begin.'
                      : 'You will receive an instant notification once your account is approved.',
                  style: const TextStyle(
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
    );
  }

  /// 3 feature cards
  Widget _buildFeaturesRow() {
    return Row(
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
            description: 'Medical team reviews each document.',
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
    );
  }

  /// Go to Dashboard Action Button
  /// Conditionally ENABLED when _isApproved is true, and DISABLED when under review.
  Widget _buildDashboardButton() {
    if (_isApproved) {
      // Enabled button with Vibrant Gradient
      return Container(
        width: double.infinity,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              color: Color(0x330052FF),
              blurRadius: 14,
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
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Go to Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      );
    }

    // Disabled / Locked button state
    return GestureDetector(
      onTap: _showPendingApprovalNotice,
      child: Container(
        width: double.infinity,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Go to Dashboard (Pending Approval)',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF64748B),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
