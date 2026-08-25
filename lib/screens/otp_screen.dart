import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:howpa_nurse/screens/registration_step1_screen.dart';

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
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  int _focusedIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 30;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();

    for (int i = 0; i < 4; i++) {
      final index = i;
      _focusNodes[index].addListener(() {
        if (_focusNodes[index].hasFocus) {
          setState(() {
            _focusedIndex = index;
          });
        }
      });
    }
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getMaskedPhoneNumber() {
    final rawNumber = widget.phoneNumber.trim();
    if (rawNumber.length == 10) {
      // e.g. 9XXXXX210 matching the design screenshot
      return '${widget.countryCode} ${rawNumber[0]}XXXXX${rawNumber.substring(7)}';
    }
    return '${widget.countryCode} $rawNumber';
  }

  void _onOtpDigitChanged(int index, String value) {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    if (value.isNotEmpty) {
      if (value.length > 1) {
        // Handle paste or multi-character input
        _controllers[index].text = value.substring(value.length - 1);
        _controllers[index].selection = TextSelection.fromPosition(
          TextPosition(offset: _controllers[index].text.length),
        );
      }
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
  }

  void _onVerifyPressed() {
    final otpCode = _controllers.map((c) => c.text).join();
    if (otpCode.length < 4) {
      setState(() {
        _errorMessage = 'Please enter complete 4-digit OTP';
      });
      return;
    }

    // Success feedback and navigate to Step 1 Registration Screen
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

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RegistrationStep1Screen(
          phoneNumber: '${widget.countryCode} ${widget.phoneNumber}',
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
    );
  }

  void _onResendOtp() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          onPressed: () => Navigator.pop(context),
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

              // 4-Digit OTP Box Inputs Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  final isFocused = _focusedIndex == index && _focusNodes[index].hasFocus;
                  final hasValue = _controllers[index].text.isNotEmpty;

                  return SizedBox(
                    width: 62,
                    height: 64,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _errorMessage != null
                              ? const Color(0xFFEF4444)
                              : (isFocused
                                  ? const Color(0xFF0052FF)
                                  : (hasValue
                                      ? const Color(0xFF0052FF)
                                      : const Color(0xFFE2E8F0))),
                          width: isFocused || _errorMessage != null ? 1.8 : 1.2,
                        ),
                        boxShadow: isFocused
                            ? [
                                const BoxShadow(
                                  color: Color(0x1A0052FF),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.backspace) {
                            if (_controllers[index].text.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                              _controllers[index - 1].clear();
                            }
                          }
                        },
                        child: Center(
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.0,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                            ],
                            onChanged: (value) => _onOtpDigitChanged(index, value),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
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
                  onPressed: _onVerifyPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
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
    );
  }
}
