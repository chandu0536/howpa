import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:howpa_nurse/screens/otp_screen.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final String _selectedCountryCode = '+91';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onSendOtpPressed() {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your mobile number';
      });
      return;
    }

    if (phoneNumber.length != 10) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    // Navigate to OTP Screen
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => OtpScreen(
          countryCode: _selectedCountryCode,
          phoneNumber: phoneNumber,
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

  @override
  Widget build(BuildContext context) {
    final isFocused = _phoneFocusNode.hasFocus;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Top Logo
              Image.asset(
                'assets/images/howpa_logo.png',
                height: 95,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 48),

              // Title
              const Text(
                'Enter Your Mobile Number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'We’ll send you a One-Time Password to verify',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 36),

              // Mobile Number Input Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country Code Selector Container
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCountryCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Phone Number Input Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _errorMessage != null
                                  ? const Color(0xFFEF4444)
                                  : (isFocused
                                      ? const Color(0xFF0052FF)
                                      : const Color(0xFFE2E8F0)),
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
                          child: TextField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            onChanged: (val) {
                              if (_errorMessage != null) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            },
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter mobile number',
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.normal,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Send OTP Gradient Button
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
                  onPressed: _onSendOtpPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Send OTP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 120),

              // Footer Terms & Privacy Notice
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: 'By continuing, you agree to our ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms & Privacy Policy.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
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
}
