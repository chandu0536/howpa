import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:howpa_nurse/core/network/api_exceptions.dart';
import 'package:howpa_nurse/core/network/token_storage.dart';
import 'package:howpa_nurse/core/services/user_profile_manager.dart';
import 'package:howpa_nurse/features/profile/data/repositories/profile_repository.dart';
import 'package:howpa_nurse/features/auth/presentation/screens/registration_step1_screen.dart';
import 'package:howpa_nurse/features/auth/presentation/screens/verification_in_progress_screen.dart';

class RegistrationStep2Screen extends StatefulWidget {
  final String phoneNumber;

  const RegistrationStep2Screen({
    super.key,
    this.phoneNumber = '+91 98765 43210',
  });

  @override
  State<RegistrationStep2Screen> createState() => _RegistrationStep2ScreenState();
}

class DocumentItem {
  final String id;
  final String title;
  final String? subtitleTag;
  final String description;
  final IconData icon;
  String? uploadedFileName;
  String? remoteUrl;
  File? file;
  bool isUploaded;

  DocumentItem({
    required this.id,
    required this.title,
    this.subtitleTag,
    required this.description,
    required this.icon,
    this.uploadedFileName,
    this.remoteUrl,
    this.file,
    this.isUploaded = false,
  });
}

class _RegistrationStep2ScreenState extends State<RegistrationStep2Screen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isFetchingDocs = false;

  final List<DocumentItem> _documents = [
    DocumentItem(
      id: 'nursing_cert',
      title: 'Nursing Certificate',
      description: 'Upload nursing degree or council registration',
      icon: Icons.card_membership_rounded,
    ),
    DocumentItem(
      id: 'aadhaar_front',
      title: 'Aadhaar Card Front',
      description: 'Upload front side of your Aadhaar card',
      icon: Icons.badge_outlined,
    ),
    DocumentItem(
      id: 'aadhaar_back',
      title: 'Aadhaar Card Back',
      description: 'Upload back side of your Aadhaar card with address',
      icon: Icons.flip_to_back_rounded,
    ),
  ];

  int get _uploadedCount => _documents.where((doc) => doc.isUploaded).length;

  @override
  void initState() {
    super.initState();
    _fetchExistingDocuments();
  }

  Future<void> _fetchExistingDocuments() async {
    final incomingDigits = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    final storedPhone = (await TokenStorage.getPhone() ?? '').replaceAll(RegExp(r'\D'), '');
    if (incomingDigits.isNotEmpty &&
        storedPhone.isNotEmpty &&
        !storedPhone.endsWith(incomingDigits) &&
        !incomingDigits.endsWith(storedPhone)) {
      // Different phone number! Do not fetch previous documents and reset cards
      setState(() {
        for (final doc in _documents) {
          doc.isUploaded = false;
          doc.remoteUrl = null;
          doc.uploadedFileName = null;
          doc.file = null;
        }
      });
      return;
    }

    setState(() => _isFetchingDocs = true);
    try {
      final docStatus = await ProfileRepositoryImpl().getDocumentsStatus();
      if (!mounted) return;

      final bool hasBothMandatory = docStatus.isNursingCertUploaded && docStatus.isAadhaarFrontUploaded;
      if (docStatus.isUnderReview || hasBothMandatory) {
        final phoneKey = incomingDigits.isNotEmpty ? incomingDigits : storedPhone;
        if (phoneKey.isNotEmpty) {
          await TokenStorage.setKycSubmitted(phoneKey, true);
        }
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => VerificationInProgressScreen(registeredPhone: widget.phoneNumber),
            ),
            (route) => false,
          );
          return;
        }
      }

      setState(() {
        for (final doc in _documents) {
          if (doc.id == 'nursing_cert' && docStatus.isNursingCertUploaded) {
            doc.isUploaded = true;
            doc.remoteUrl = docStatus.nursingCertUrl;
            doc.uploadedFileName = _getCleanFileName(docStatus.nursingCertUrl, 'Nursing Certificate (Uploaded)');
          } else if (doc.id == 'aadhaar_front' && docStatus.isAadhaarFrontUploaded) {
            doc.isUploaded = true;
            doc.remoteUrl = docStatus.aadhaarFrontUrl;
            doc.uploadedFileName = _getCleanFileName(docStatus.aadhaarFrontUrl, 'Aadhaar Front (Uploaded)');
          } else if (doc.id == 'aadhaar_back' && docStatus.isAadhaarBackUploaded) {
            doc.isUploaded = true;
            doc.remoteUrl = docStatus.aadhaarBackUrl;
            doc.uploadedFileName = _getCleanFileName(docStatus.aadhaarBackUrl, 'Aadhaar Back (Uploaded)');
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching documents in Step 2: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingDocs = false);
      }
    }
  }

  String _getCleanFileName(String? urlOrKey, String fallback) {
    if (urlOrKey == null || urlOrKey.trim().isEmpty || urlOrKey == 'null') return fallback;
    try {
      final uri = Uri.tryParse(urlOrKey);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        if (last.isNotEmpty && !last.contains('?')) return last;
        if (last.contains('?')) return last.split('?').first;
      }
    } catch (_) {}
    if (urlOrKey.contains('/')) {
      final lastPart = urlOrKey.split('/').last;
      if (lastPart.isNotEmpty) {
        return lastPart.contains('?') ? lastPart.split('?').first : lastPart;
      }
    }
    return fallback;
  }

  void _handleUpload(DocumentItem doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                doc.isUploaded ? 'Manage ${doc.title}' : 'Upload ${doc.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose file source from your phone camera or gallery',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: const Color(0xFFFF5C00),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final XFile? photo = await _picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 70,
                        );
                        if (photo != null && mounted) {
                          final file = File(photo.path);
                          if (file.existsSync()) {
                            _completeUpload(doc, photo.name, file);
                          }
                        }
                      } catch (e) {
                        debugPrint('Registration Step 2 camera error: $e');
                      }
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF0052FF),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 70,
                        );
                        if (image != null && mounted) {
                          final file = File(image.path);
                          if (file.existsSync()) {
                            _completeUpload(doc, image.name, file);
                          }
                        }
                      } catch (e) {
                        debugPrint('Registration Step 2 gallery error: $e');
                      }
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Files / PDF',
                    color: const Color(0xFF8B5CF6),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
                        );
                        if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
                          final file = File(result.files.first.path!);
                          _completeUpload(doc, result.files.first.name, file);
                        }
                      } catch (e) {
                        // ignore error
                      }
                    },
                  ),
                  if (doc.isUploaded)
                    _buildSourceOption(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove',
                      color: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(context);
                        _removeUpload(doc);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  void _completeUpload(DocumentItem doc, String fileName, [File? file]) {
    setState(() {
      doc.isUploaded = true;
      doc.uploadedFileName = fileName;
      doc.file = file;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${doc.title} selected: $fileName'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _removeUpload(DocumentItem doc) {
    setState(() {
      doc.isUploaded = false;
      doc.uploadedFileName = null;
      doc.file = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${doc.title} removed'),
        backgroundColor: const Color(0xFF64748B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _onSubmitPressed() async {
    if (_isLoading) return;

    if (_uploadedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload at least your required documents'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final nursingCertDoc = _documents.where((d) => d.id == 'nursing_cert').firstOrNull;
      final aadhaarFrontDoc = _documents.where((d) => d.id == 'aadhaar_front').firstOrNull;
      final aadhaarBackDoc = _documents.where((d) => d.id == 'aadhaar_back').firstOrNull;

      final success = await ProfileRepositoryImpl().uploadKycDocuments(
        nursingCertificate: nursingCertDoc?.file,
        aadhaarFront: aadhaarFrontDoc?.file,
        aadhaarBack: aadhaarBackDoc?.file,
        recentPhoto: UserProfileManager.instance.profileImageFile,
      );

      if (!mounted) return;

      if (success) {
        final cleanDigits = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
        if (cleanDigits.isNotEmpty) {
          await TokenStorage.setKycSubmitted(cleanDigits, true);
        }

        final uploadedDocPreviews = <String, String>{};
        for (final doc in _documents) {
          if (doc.file != null && doc.file!.existsSync()) {
            uploadedDocPreviews[doc.id] = doc.file!.path;
          } else if (doc.remoteUrl != null && doc.remoteUrl!.isNotEmpty) {
            uploadedDocPreviews[doc.id] = doc.remoteUrl!;
          }
        }

        if (!mounted) return;

        // Navigate to Verification In Progress screen ONLY on backend confirmation
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                VerificationInProgressScreen(
                  registeredPhone: widget.phoneNumber,
                  uploadedFilePaths: uploadedDocPreviews,
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to upload KYC documents. Please try again.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading documents: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationStep1Screen(phoneNumber: widget.phoneNumber),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final step2Progress = _uploadedCount / _documents.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFD),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFCFCFD),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF0F172A),
              size: 20,
            ),
            onPressed: _handleBack,
          ),
        ),
      body: SafeArea(
        child: Column(
          children: [
            // STICKY / FIXED TOP HEADER (Progress bar with Orange Line stays visible even when scrolling)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              color: const Color(0xFFFCFCFD),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Step 2 of 2',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${((0.5 + (step2Progress * 0.5)) * 100).toInt()}% Done',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5C00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 2-Step Progress Bars with Orange Fill
                  Row(
                    children: [
                      // Step 1: Fully completed orange line
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5C00),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Step 2: Dynamic smooth orange line moving as documents are uploaded!
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                    width: constraints.maxWidth * step2Progress,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5C00),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            if (_isFetchingDocs)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFFFF5C00),
                backgroundColor: Colors.transparent,
              ),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // Title and Subtitle
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Upload Your Documents',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B1938),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Required for verification by our team',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Document Cards List
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _documents.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        return _buildDocumentCard(doc);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Secure & Private Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFDBEAFE),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF334155),
                                  height: 1.3,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Secure & Private  ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Your documents are encrypted and used only for verification purposes.',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit for Verification Button
                    Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
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
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onSubmitPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text(
                                'Submit for Verification',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDocumentCard(DocumentItem doc) {
    return GestureDetector(
      onTap: () => _handleUpload(doc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: doc.isUploaded ? const Color(0xFFF0F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: doc.isUploaded ? const Color(0xFF0052FF) : const Color(0xFFE2E8F0),
            width: doc.isUploaded ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: doc.isUploaded ? const Color(0x1A0052FF) : const Color(0x06000000),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Icon Container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: doc.isUploaded ? const Color(0x1A0052FF) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                doc.isUploaded ? Icons.check_circle_rounded : doc.icon,
                color: const Color(0xFF0052FF),
                size: 18,
              ),
            ),

            const SizedBox(width: 10),

            // Middle Document Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          doc.title,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    doc.isUploaded ? (doc.uploadedFileName ?? 'Uploaded') : doc.description,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: doc.isUploaded ? const Color(0xFF0052FF) : const Color(0xFF64748B),
                      fontWeight: doc.isUploaded ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right Upload Button (Dashed box style)
            CustomPaint(
              painter: DashedRectPainter(
                color: doc.isUploaded ? const Color(0xFF0052FF) : const Color(0xFF3B82F6),
                strokeWidth: 1.2,
                gap: 3.0,
              ),
              child: Container(
                width: 76,
                height: 36,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: doc.isUploaded ? Colors.white : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: doc.isUploaded
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF0052FF),
                              size: 15,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Uploaded',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0052FF),
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.file_upload_outlined,
                              color: Color(0xFF0052FF),
                              size: 15,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Upload',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0052FF),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for dashed rectangle upload button border
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double length = draw ? 5.0 : gap;
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
