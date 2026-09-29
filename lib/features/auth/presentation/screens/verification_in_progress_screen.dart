import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:howpa_nurse/core/network/token_storage.dart';
import 'package:howpa_nurse/core/services/user_profile_manager.dart';
import 'package:howpa_nurse/features/profile/data/models/profile_models.dart';
import 'package:howpa_nurse/features/profile/data/repositories/profile_repository.dart';
import 'package:howpa_nurse/features/home/presentation/screens/nurse_dashboard_screen.dart';
import 'package:howpa_nurse/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:howpa_nurse/core/network/api_exceptions.dart';
import 'package:howpa_nurse/core/widgets/no_internet_widget.dart';
import 'package:howpa_nurse/features/visits/data/models/visit_models.dart';

class VerificationInProgressScreen extends StatefulWidget {
  final String? registeredPhone;
  final Map<String, String>? uploadedFilePaths;

  const VerificationInProgressScreen({
    super.key,
    this.registeredPhone,
    this.uploadedFilePaths,
  });

  @override
  State<VerificationInProgressScreen> createState() =>
      _VerificationInProgressScreenState();
}

class _VerificationInProgressScreenState
    extends State<VerificationInProgressScreen>
    with SingleTickerProviderStateMixin {
  final ProfileRepository _profileRepo = ProfileRepositoryImpl();
  bool _isChecking = false;
  bool _isApproved = false;
  bool _isRejected = false;
  bool _isOffline = false;
  String _statusText = 'Under Review';
  String _registeredPhone = '';
  String _nurseName = '';
  String? _profilePhotoUrl;
  Timer? _pollingTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadInitialUserData();
    _checkApprovalStatus(silent: true);

    // Auto-poll approval status every 10 seconds in background
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !_isApproved) {
        _checkApprovalStatus(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUserData() async {
    final phone =
        widget.registeredPhone ?? UserProfileManager.instance.phoneNumber;
    final storedPhone = await TokenStorage.getPhone();
    final mgrPhoto =
        UserProfileManager.instance.fullProfilePhotoUrl ??
        UserProfileManager.instance.profilePhotoUrl;

    if (mounted) {
      setState(() {
        _registeredPhone = phone.isNotEmpty
            ? phone
            : (storedPhone?.isNotEmpty == true
                  ? storedPhone!
                  : 'Registered Mobile');
        _nurseName = UserProfileManager.instance.fullName;
        if (mgrPhoto != null && mgrPhoto.trim().isNotEmpty) {
          _profilePhotoUrl = mgrPhoto.trim();
        }
      });
    }
  }

  Future<void> _checkApprovalStatus({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isChecking = true;
      });
    }

    try {
      final profileFuture = _profileRepo.getProfile();
      final docsFuture = _profileRepo.getDocumentsStatus();

      final results = await Future.wait([profileFuture, docsFuture]);
      final profile = results[0] as dynamic;
      final docs = results[1] as KycDocumentsStatus?;

      if (!mounted) return;

      setState(() {
        _isOffline = false;
      });

      if (profile != null) {
        if (profile.fullName != null && profile.fullName.isNotEmpty) {
          setState(() {
            _nurseName = profile.fullName;
          });
        }
        if (profile.phone != null && profile.phone.isNotEmpty) {
          setState(() {
            _registeredPhone = profile.phone;
          });
        }
      }

      final candidatePhoto =
          (profile?.profilePhotoUrl != null &&
              profile!.profilePhotoUrl!.isNotEmpty)
          ? profile.profilePhotoUrl
          : (docs?.photoUrl != null && docs!.photoUrl!.isNotEmpty
                ? docs.photoUrl
                : (UserProfileManager.instance.profilePhotoUrl?.isNotEmpty ==
                          true
                      ? UserProfileManager.instance.profilePhotoUrl
                      : null));

      if (candidatePhoto != null && candidatePhoto.isNotEmpty) {
        setState(() {
          _profilePhotoUrl = candidatePhoto;
        });
        UserProfileManager.instance.setProfilePhotoUrl(candidatePhoto);
      }

      if (profile != null) {
        if (profile.isApproved) {
          setState(() {
            _isApproved = true;
            _isRejected = false;
            _statusText = 'Approved';
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Account Approved for $_registeredPhone! Redirecting...',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
          }

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              _navigateToDashboard();
            }
          });
          return;
        } else if (profile.isRejected) {
          setState(() {
            _isApproved = false;
            _isRejected = true;
            _statusText = 'Rejected';
          });
          if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Your documents require resubmission. Please contact support.',
                ),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } else {
          setState(() {
            _isApproved = false;
            _isRejected = false;
            _statusText = 'Under Review';
          });
          if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verification pending. Review usually takes 24-48 hours.',
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF0F172A),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      }

      if (docs != null && docs.photoUrl != null && docs.photoUrl!.isNotEmpty) {
        setState(() {
          _profilePhotoUrl = docs.photoUrl;
        });
      }
    } on NetworkException catch (_) {
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isChecking = false;
        });
      }
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error checking status. Please try again.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NurseDashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?'),
        content: const Text(
          'Are you sure you want to sign out and log in with another number?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await TokenStorage.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return NoInternetWidget(
        onRetry: () {
          setState(() {
            _isOffline = false;
          });
          _checkApprovalStatus(silent: false);
        },
      );
    }

    final imageAsset = _isRejected
        ? 'assets/images/Verification in progress cancled .png'
        : 'assets/images/Verification in progress.png';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Verification Status',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _checkApprovalStatus(silent: false),
            color: const Color(0xFF0052FF),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── 1. Top Image (Verification in Progress) ──
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 240),
                    alignment: Alignment.center,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.fact_check_outlined,
                            size: 80,
                            color: Color(0xFF0052FF),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Title & Status Tagline ──
                  Text(
                    _isApproved
                        ? 'Verification Approved! 🎉'
                        : _isRejected
                        ? 'Verification Action Required'
                        : 'Verification Under Review',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _isApproved
                          ? const Color(0xFF16A34A)
                          : _isRejected
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _isApproved
                        ? 'Your credentials have been verified by HOWPA Medical Board. You are now authorized to accept patient home visits.'
                        : _isRejected
                        ? 'Some uploaded documents could not be verified. Please review feedback and resubmit your certificates.'
                        : 'Our medical compliance team is reviewing your nursing credentials, degree certificate, and identity proof. This usually takes 24 to 48 hours.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ── 2. Process Line / Stepper Indicator ──
                  _buildProcessLine(),

                  const SizedBox(height: 24),

                  // ── 3. Registered Nurse Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        _buildNurseAvatar(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nurseName.isNotEmpty && _nurseName != 'Nurse'
                                    ? _nurseName
                                    : 'Registered Nurse',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _registeredPhone,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _isApproved
                                ? const Color(0xFFDCFCE7)
                                : _isRejected
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isApproved
                                  ? const Color(0xFF86EFAC)
                                  : _isRejected
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFFCD34D),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isApproved
                                      ? const Color(0xFF16A34A)
                                      : _isRejected
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _statusText,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: _isApproved
                                      ? const Color(0xFF15803D)
                                      : _isRejected
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 4. Primary Action Button ──
                  if (_isApproved)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToDashboard,
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Proceed to Home Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isChecking
                            ? null
                            : () => _checkApprovalStatus(silent: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052FF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF94A3B8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isChecking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Check Approval Status',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Sign out button
                  TextButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    label: const Text(
                      'Sign Out / Login with Another Number',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Process Line Widget (Step 1 -> Step 2 -> Step 3) ──
  Widget _buildProcessLine() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Step 1: Registered
              _buildStepIcon(
                stepNumber: '1',
                icon: Icons.check_rounded,
                isCompleted: true,
                isActive: false,
                color: const Color(0xFF16A34A),
              ),

              // Connector Line 1
              Expanded(
                child: Container(height: 3, color: const Color(0xFF16A34A)),
              ),

              // Step 2: Under Review
              _isApproved
                  ? _buildStepIcon(
                      stepNumber: '2',
                      icon: Icons.check_rounded,
                      isCompleted: true,
                      isActive: false,
                      color: const Color(0xFF16A34A),
                    )
                  : _isRejected
                  ? _buildStepIcon(
                      stepNumber: '2',
                      icon: Icons.close_rounded,
                      isCompleted: false,
                      isActive: true,
                      color: const Color(0xFFDC2626),
                    )
                  : ScaleTransition(
                      scale: _pulseAnimation,
                      child: _buildStepIcon(
                        stepNumber: '2',
                        icon: Icons.hourglass_top_rounded,
                        isCompleted: false,
                        isActive: true,
                        color: const Color(0xFF0052FF),
                      ),
                    ),

              // Connector Line 2
              Expanded(
                child: Container(
                  height: 3,
                  color: _isApproved
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFCBD5E1),
                ),
              ),

              // Step 3: Approved & Ready
              _buildStepIcon(
                stepNumber: '3',
                icon: _isApproved
                    ? Icons.verified_rounded
                    : Icons.lock_outline_rounded,
                isCompleted: _isApproved,
                isActive: false,
                color: _isApproved
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Step Labels Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                width: 80,
                child: Text(
                  'Submitted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  _isApproved
                      ? 'Verified'
                      : _isRejected
                      ? 'Action Req.'
                      : 'In Review',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _isApproved
                        ? const Color(0xFF16A34A)
                        : _isRejected
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF0052FF),
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'Approved',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _isApproved
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon({
    required String stepNumber,
    required IconData icon,
    required bool isCompleted,
    required bool isActive,
    required Color color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isCompleted
            ? color
            : isActive
            ? color.withValues(alpha: 0.15)
            : const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted || isActive ? color : const Color(0xFFCBD5E1),
          width: isActive ? 2.5 : 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          icon,
          size: 18,
          color: isCompleted
              ? Colors.white
              : isActive
              ? color
              : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildNurseAvatar() {
    final localPath =
        widget.uploadedFilePaths?['recent_photo'] ??
        widget.uploadedFilePaths?['photo'] ??
        widget.uploadedFilePaths?['avatar'];

    if (localPath != null && File(localPath).existsSync()) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        ),
        child: ClipOval(
          child: Image.file(
            File(localPath),
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (UserProfileManager.instance.profileImageFile != null &&
        UserProfileManager.instance.profileImageFile!.existsSync()) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        ),
        child: ClipOval(
          child: Image.file(
            UserProfileManager.instance.profileImageFile!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final photoUrl =
        _profilePhotoUrl ??
        UserProfileManager.instance.fullProfilePhotoUrl ??
        UserProfileManager.instance.profilePhotoUrl;

    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      final formattedUrl = formatImageUrl(photoUrl);
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        ),
        child: ClipOval(
          child: Image.network(
            formattedUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 48,
              height: 48,
              color: const Color(0xFFEFF6FF),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF0052FF),
                size: 26,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF0052FF),
        size: 26,
      ),
    );
  }
}
