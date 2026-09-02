import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'phone_number_screen.dart';
import 'registration_step1_screen.dart';

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
  late final TextEditingController _otpController;
  late final FocusNode _otpFocusNode;

  Timer? _timer;
  int _secondsRemaining = 30;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _otpFocusNode = FocusNode();

    _startTimer();

    // Auto-focus OTP input when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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

  void _onVerifyPressed() {
    // Clear any previous keyboard dismiss or focus anomalies
    final otpCode = _otpController.text.trim();
    if (otpCode.length < 4) {
      setState(() {
        _errorMessage = 'Please enter complete 4-digit OTP';
      });
      return;
    }

    context.read<AuthCubit>().verifyOtp(widget.phoneNumber, otpCode);
  }

  void _onResendOtp() {
    // 1. Reset OTP input field and error message
    _otpController.clear();
    setState(() {
      _errorMessage = null;
    });

    // 2. Restart countdown timer & restore focus
    _startTimer();
    _otpFocusNode.requestFocus();

    // 3. Trigger backend API
    context.read<AuthCubit>().sendOtp(widget.phoneNumber);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('A new OTP code has been sent to ${_getMaskedPhoneNumber()}'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PhoneNumberScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pin themes matching exact UI design
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 54,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0052FF),
          width: 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140052FF),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0052FF),
          width: 1.1,
        ),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444),
          width: 1.6,
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
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
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('OTP Verified Successfully!'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );

              final user = state.user;
              if (user != null && user.isProfileCompleted) {
                if (user.approvalStatus == 'APPROVED') {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.dashboard,
                    (route) => false,
                  );
                } else {
                  // Approval is PENDING / UNDER_REVIEW
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.verificationInProgress,
                    (route) => false,
                  );
                }
              } else {
                // New user or profile not completed yet
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationStep1Screen(
                      phoneNumber: '${widget.countryCode} ${widget.phoneNumber}',
                    ),
                  ),
                );
              }
            } else if (state is AuthError) {
              setState(() {
                _errorMessage = state.message;
              });
              // Ensure user can immediately re-type or clear
              _otpFocusNode.requestFocus();
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // Top Logo
                    Image.asset(
                      'assets/images/howpa_logo.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Verify OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Subtitle with masked phone number
                    Text(
                      'Code sent to ${_getMaskedPhoneNumber()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 4-Digit OTP Box Inputs (Pinput)
                    Pinput(
                      length: 4,
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      errorPinTheme: errorPinTheme,
                      forceErrorState: _errorMessage != null,
                      showCursor: true,
                      cursor: Center(
                        child: Container(
                          width: 2,
                          height: 22,
                          color: const Color(0xFF0052FF),
                        ),
                      ),
                      onChanged: (value) {
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                      onCompleted: (pin) {
                        _onVerifyPressed();
                      },
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Resend OTP Countdown Timer / Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Resend OTP ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (_secondsRemaining > 0)
                          Text(
                            'in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0052FF),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: isLoading ? null : _onResendOtp,
                            child: const Text(
                              'Resend',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF5C00),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Verify Gradient Button
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
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
                        onPressed: isLoading ? null : _onVerifyPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Verify',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
