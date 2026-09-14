class Validators {
  static String? requiredField(String? value, [String message = 'This field is required']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter phone number';
    }
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length < 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter email address';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validateOtp(String? value, [int length = 4]) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter OTP';
    }
    if (value.trim().length != length) {
      return 'Enter valid $length digit OTP';
    }
    return null;
  }
}
