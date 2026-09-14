class LoginRequest {
  final String phoneNumber;
  final String? otp;

  const LoginRequest({
    required this.phoneNumber,
    this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      if (otp != null) 'otp': otp,
    };
  }

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      phoneNumber: json['phone_number'] as String? ?? '',
      otp: json['otp'] as String?,
    );
  }
}
