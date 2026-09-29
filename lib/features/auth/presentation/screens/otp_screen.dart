import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:howpa_nurse/core/network/api_exceptions.dart';
import 'package:howpa_nurse/features/auth/data/models/auth_models.dart';
import 'package:howpa_nurse/features/auth/data/repositories/auth_repository.dart';
import 'package:howpa_nurse/features/home/presentation/screens/nurse_dashboard_screen.dart';
import 'phone_number_screen.dart';
import 'registration_step1_screen.dart';
import 'registration_step2_screen.dart';
import 'verification_in_progress_screen.dart';

class OtpScreen extends StatefulWidget {
  final String countryCode;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    this.countryCode = '+91',
    this.phoneNumber = '9876543210',
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 4;

  // Single unified controller and focus node for robust input handling
  late final TextEditingController _otpController;
  late final FocusNode _otpFocusNode;

  String _otpText = '';
  Timer? _timer;
  int _secondsRemaining = 30;
  String? _errorMessage;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _otpFocusNode = FocusNode();

    // Rebuild visual boxes when focus changes so the active border highlights correctly
    _otpFocusNode.addListener(_handleFocusChange);

    _startTimer();

    // Automatically focus the OTP input after transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpFocusNode.removeListener(_handleFocusChange);
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  String _getMaskedPhoneNumber() {
    final rawNumber = widget.phoneNumber.trim();
    if (rawNumber.length == 10) {
      return '${widget.countryCode} ${rawNumber[0]}XXXXX${rawNumber.substring(7)}';
    }
    return '${widget.countryCode} $rawNumber';
  }

  void _onOtpChanged(String value) {
    setState(() {
      _otpText = value;
      if (_errorMessage != null) {
        _errorMessage = null;
      }
    });

    // Optional auto-submit when 4 digits are completed
    if (value.length == _otpLength && !_isVerifying) {
      _onVerifyPressed();
    }
  }

  Future<void> _onVerifyPressed() async {
    // Prevent duplicate triggers
    if (_isVerifying) return;

    final otpCode = _otpController.text.trim();
    if (otpCode.length < _otpLength) {
      setState(() {
        _errorMessage = 'Please enter complete 4-digit OTP';
      });
      _otpFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final fullPhone = '${widget.countryCode}${widget.phoneNumber}';
      final response = await AuthRepositoryImpl().verifyOtp(
        VerifyOtpRequest(
          phone: fullPhone,
          otp: otpCode,
          deviceType: 'android',
        ),
      );

      if (!mounted) return;

      if (response.success) {
        // Success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('OTP Verified Successfully!'),
            backgroundColor: const Color(0xFF0052FF),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        final user = response.nurse;
        final isApproved = user?.isApproved ?? false;
        final hasFullName = user?.fullName != null && user!.fullName!.trim().isNotEmpty;
        final isProfileCompleted = (user?.isProfileCompleted ?? false) && hasFullName;
        final isKycSubmitted = user?.isKycSubmitted ?? false;

        Widget targetScreen;
        if (isApproved) {
          // Existing Approved Nurse -> Go directly to Home Dashboard
          targetScreen = const NurseDashboardScreen();
        } else if (!isProfileCompleted) {
          // Step 1: Personal Details & Specialization
          targetScreen = RegistrationStep1Screen(
            phoneNumber: '${widget.countryCode} ${widget.phoneNumber}',
          );
        } else if (!isKycSubmitted) {
          // Step 2: Upload Documents & KYC
          targetScreen = RegistrationStep2Screen(
            phoneNumber: '${widget.countryCode} ${widget.phoneNumber}',
          );
        } else {
          // Both Step 1 & Step 2 completed -> Under Review Screen
          targetScreen = VerificationInProgressScreen(registeredPhone: fullPhone);
        }

        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
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
        setState(() {
          _errorMessage = response.message ?? 'Invalid OTP entered. Please try again.';
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Invalid OTP entered. Please check and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _onResendOtp() {
    if (_secondsRemaining > 0) return;

    final fullPhone = '${widget.countryCode}${widget.phoneNumber}';
    AuthRepositoryImpl().sendOtp(fullPhone);

    // Reset OTP field, error message and restart timer
    _otpController.clear();
    setState(() {
      _otpText = '';
      _errorMessage = null;
    });
    _otpFocusNode.requestFocus();
    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('A new OTP code has been sent to ${_getMaskedPhoneNumber()}'),
        backgroundColor: const Color(0xFFFF5C00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PhoneNumberScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          backgroundColor: Colors.transparent,
          elevation: 0,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Top Logo
              Image.asset(
                'assets/images/howpa_logo.png',
                height: 95,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 48),

              // Title
              const Text(
                'Verify OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle with masked phone number
              Text(
                'Code sent to ${_getMaskedPhoneNumber()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 36),

              // 4-Digit Unified OTP Box Widget
              GestureDetector(
                onTap: () {
                  _otpFocusNode.requestFocus();
                },
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Visual pin cells
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_otpLength, (index) {
                        return _buildPinCell(index);
                      }),
                    ),

                    // Completely transparent, fully-functional native TextField overlay
                    Opacity(
                      opacity: 0.0,
                      child: TextField(
                        controller: _otpController,
                        focusNode: _otpFocusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_otpLength),
                        ],
                        onChanged: _onOtpChanged,
                        onSubmitted: (_) => _onVerifyPressed(),
                        showCursor: false,
                        enableInteractiveSelection: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // Resend OTP Countdown Timer / Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Resend OTP ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (_secondsRemaining > 0)
                    Text(
                      'in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0052FF),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _onResendOtp,
                      child: const Text(
                        'Resend',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5C00),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 36),

              // Verify Gradient Button
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
                  onPressed: _isVerifying ? null : _onVerifyPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildPinCell(int index) {
    final hasFocus = _otpFocusNode.hasFocus;
    final isCurrentFocused = hasFocus &&
        ((_otpText.length == index) || (_otpText.length == _otpLength && index == _otpLength - 1));
    final hasValue = _otpText.length > index;
    final digit = hasValue ? _otpText[index] : '';

    Color borderColor = const Color(0xFFE2E8F0);
    double borderWidth = 1.2;
    List<BoxShadow> boxShadow = [];

    if (_errorMessage != null) {
      borderColor = const Color(0xFFEF4444);
      borderWidth = 1.8;
    } else if (isCurrentFocused) {
      borderColor = const Color(0xFF0052FF);
      borderWidth = 1.8;
      boxShadow = const [
        BoxShadow(
          color: Color(0x1A0052FF),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];
    } else if (hasValue) {
      borderColor = const Color(0xFF0052FF);
      borderWidth = 1.2;
    }

    return SizedBox(
      width: 62,
      height: 64,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: boxShadow,
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
