import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:howpa_nurse/core/network/token_storage.dart';
import 'package:howpa_nurse/core/services/user_profile_manager.dart';
import 'package:howpa_nurse/features/profile/data/models/profile_models.dart';
import 'package:howpa_nurse/features/profile/data/repositories/profile_repository.dart';
import 'package:howpa_nurse/features/home/presentation/screens/nurse_dashboard_screen.dart';
import 'package:howpa_nurse/features/auth/presentation/screens/onboarding_screen.dart';

class VerificationInProgressScreen extends StatefulWidget {
  final String? registeredPhone;
  final Map<String, String>? uploadedFilePaths; // Local file paths of uploaded docs

  const VerificationInProgressScreen({
    super.key,
    this.registeredPhone,
    this.uploadedFilePaths,
  });

  @override
  State<VerificationInProgressScreen> createState() => _VerificationInProgressScreenState();
}

class _VerificationInProgressScreenState extends State<VerificationInProgressScreen> {
  final ProfileRepository _profileRepo = ProfileRepositoryImpl();
  bool _isChecking = false;
  bool _isApproved = false;
  bool _isRejected = false;
  String _statusText = 'Under Review';
  String _registeredPhone = '';
  String _nurseName = '';
  String? _profilePhotoUrl;
  KycDocumentsStatus? _docsStatus;
  DateTime? _lastCheckedTime;
  Timer? _pollingTimer;

  Map<String, String> _localUploadedPaths = {};

  @override
  void initState() {
    super.initState();
    if (widget.uploadedFilePaths != null) {
      _localUploadedPaths = Map.from(widget.uploadedFilePaths!);
    }
    _loadInitialUserData();

    // 1. Initial check against backend API
    _checkApprovalStatus(silent: true);

    // 2. Poll every 10 seconds to detect backend approval automatically
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !_isApproved) {
        _checkApprovalStatus(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialUserData() async {
    final phone = widget.registeredPhone ??
        UserProfileManager.instance.phoneNumber;
    final storedPhone = await TokenStorage.getPhone();
    
    if (mounted) {
      setState(() {
        _registeredPhone = phone.isNotEmpty
            ? phone
            : (storedPhone?.isNotEmpty == true ? storedPhone! : 'Registered Number');
        _nurseName = UserProfileManager.instance.fullName;
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
        _lastCheckedTime = DateTime.now();
        if (docs != null) _docsStatus = docs;
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
        if (profile.profilePhotoUrl != null && profile.profilePhotoUrl.isNotEmpty) {
          setState(() {
            _profilePhotoUrl = profile.profilePhotoUrl;
          });
        }

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
                    const Icon(Icons.verified_user_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Account Approved for $_registeredPhone! Redirecting to Home...',
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
                content: const Text('Your documents require resubmission. Please contact HOWPA support.'),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } else {
          // Still pending
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
                      child: Text('Verification pending for $_registeredPhone. Review usually takes 24-48 hours.'),
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
      } else {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Server unreachable. Please check your internet connection.'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error checking approval status. Please try again.'),
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

  void _showImagePreviewDialog({
    required String title,
    String? localPath,
    String? networkUrl,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 380),
                      width: double.infinity,
                      color: const Color(0xFFF1F5F9),
                      child: localPath != null && File(localPath).existsSync()
                          ? Image.file(
                              File(localPath),
                              fit: BoxFit.contain,
                            )
                          : (networkUrl != null && networkUrl.isNotEmpty
                              ? Image.network(
                                  networkUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Text('Document preview unavailable'),
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Icon(Icons.description_outlined, size: 64, color: Color(0xFF94A3B8)),
                                  ),
                                )),
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

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out and register/log in with another number?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  @override
  Widget build(BuildContext context) {
    // Collect document items to display
    final nursingPath = _localUploadedPaths['nursing_cert'];
    final aadhaarPath = _localUploadedPaths['aadhaar_card'];
    final govtIdPath = _localUploadedPaths['govt_id'];
    final recentPhotoPath = _localUploadedPaths['recent_photo'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _checkApprovalStatus(silent: false),
          color: const Color(0xFF0052FF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Top Real-Time Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isApproved
                        ? const Color(0xFFDCFCE7)
                        : _isRejected
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(24),
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
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isApproved
                              ? const Color(0xFF16A34A)
                              : _isRejected
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Approval Status: $_statusText',
                        style: TextStyle(
                          fontSize: 13,
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

                const SizedBox(height: 16),

                // Header Profile & ID Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Nurse Profile Avatar
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEFF6FF),
                              border: Border.all(color: const Color(0xFF0052FF), width: 1.5),
                            ),
                            child: ClipOval(
                              child: recentPhotoPath != null && File(recentPhotoPath).existsSync()
                                  ? Image.file(File(recentPhotoPath), fit: BoxFit.cover)
                                  : (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                                      ? Image.network(_profilePhotoUrl!, fit: BoxFit.cover)
                                      : const Icon(Icons.person_rounded, color: Color(0xFF0052FF), size: 28)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nurseName.isNotEmpty && _nurseName != 'Nurse' ? _nurseName : 'Registered Nurse',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _registeredPhone.isNotEmpty ? _registeredPhone : 'Mobile Number',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'In Review',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Uploaded Documents Gallery Section
                Row(
                  children: const [
                    Icon(Icons.file_copy_outlined, size: 18, color: Color(0xFF0052FF)),
                    SizedBox(width: 8),
                    Text(
                      'Uploaded Documents & Credentials',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Document Preview Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    _buildDocumentPreviewCard(
                      title: 'Nursing License',
                      localPath: nursingPath,
                      networkUrl: _docsStatus?.nursingCertUrl,
                      isUploaded: nursingPath != null || (_docsStatus?.isNursingCertUploaded ?? true),
                      icon: Icons.card_membership_rounded,
                    ),
                    _buildDocumentPreviewCard(
                      title: 'Aadhaar / ID',
                      localPath: aadhaarPath,
                      networkUrl: _docsStatus?.aadhaarFrontUrl,
                      isUploaded: aadhaarPath != null || (_docsStatus?.isAadhaarFrontUploaded ?? true),
                      icon: Icons.badge_outlined,
                    ),
                    if (govtIdPath != null || (_docsStatus?.isGovtIdUploaded ?? false))
                      _buildDocumentPreviewCard(
                        title: 'Govt ID Proof',
                        localPath: govtIdPath,
                        networkUrl: _docsStatus?.govtIdUrl,
                        isUploaded: true,
                        icon: Icons.shield_outlined,
                      ),
                    if (recentPhotoPath != null || (_docsStatus?.isPhotoUploaded ?? false) || (_profilePhotoUrl != null))
                      _buildDocumentPreviewCard(
                        title: 'Passport Photo',
                        localPath: recentPhotoPath,
                        networkUrl: _docsStatus?.photoUrl ?? _profilePhotoUrl,
                        isUploaded: true,
                        icon: Icons.portrait_rounded,
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Live Sync Notice Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_rounded, color: Color(0xFF0052FF), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _lastCheckedTime != null
                              ? 'Live sync active (Checked ${_lastCheckedTime!.hour.toString().padLeft(2, '0')}:${_lastCheckedTime!.minute.toString().padLeft(2, '0')}:${_lastCheckedTime!.second.toString().padLeft(2, '0')})'
                              : 'Live sync active. Auto-refreshes every 10 seconds.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Primary Action: Real-Time Check Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : () => _checkApprovalStatus(silent: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052FF),
                      foregroundColor: Colors.white,
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

                const SizedBox(height: 12),

                // Sign Out / Switch Account
                TextButton(
                  onPressed: _handleLogout,
                  child: const Text(
                    'Sign Out / Register Different Number',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPreviewCard({
    required String title,
    String? localPath,
    String? networkUrl,
    required bool isUploaded,
    required IconData icon,
  }) {
    final bool hasFile = (localPath != null && File(localPath).existsSync()) ||
        (networkUrl != null && networkUrl.isNotEmpty);

    return InkWell(
      onTap: () {
        _showImagePreviewDialog(
          title: title,
          localPath: localPath,
          networkUrl: networkUrl,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? const Color(0xFF0052FF).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              if (localPath != null && File(localPath).existsSync())
                Positioned.fill(
                  child: Image.file(
                    File(localPath),
                    fit: BoxFit.cover,
                  ),
                )
              else if (networkUrl != null && networkUrl.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    networkUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFEFF6FF),
                      child: Center(
                        child: Icon(icon, color: const Color(0xFF0052FF), size: 32),
                      ),
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: Center(
                      child: Icon(icon, color: const Color(0xFF94A3B8), size: 32),
                    ),
                  ),
                ),

              // Gradient Overlay for Legibility
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Top Status Badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isUploaded ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUploaded ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isUploaded ? 'Uploaded' : 'Pending',
                        style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Title and Tap to Preview Hint
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 10, color: Colors.white70),
                        SizedBox(width: 3),
                        Text(
                          'Tap to view',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
