import 'dart:io';
import 'package:flutter/material.dart';
import 'package:howpa_nurse/core/network/api_endpoints.dart';

class UserProfileManager extends ChangeNotifier {
  static final UserProfileManager instance = UserProfileManager._internal();

  UserProfileManager._internal();

  String _nurseId = '';
  File? _profileImageFile;
  String? _profilePhotoUrl;
  String _fullName = 'Nurse';
  String _phoneNumber = '';
  String _email = '';
  String _dob = '';
  String _gender = '';
  String _experience = '0';
  String _specialization = 'Nurse Care';
  String _country = 'India';
  String _state = 'Telangana';
  String _district = 'Hyderabad';
  String _area = '';
  String _location = '';
  double? _latitude;
  double? _longitude;

  // Getters
  String get nurseId => _nurseId;
  File? get profileImageFile => _profileImageFile;
  String? get profilePhotoUrl => _profilePhotoUrl;

  String? get fullProfilePhotoUrl {
    if (_profilePhotoUrl == null || _profilePhotoUrl!.trim().isEmpty) return null;
    final url = _profilePhotoUrl!.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final baseUrl = ApiEndpoints.baseUrl.endsWith('/')
        ? ApiEndpoints.baseUrl.substring(0, ApiEndpoints.baseUrl.length - 1)
        : ApiEndpoints.baseUrl;
    final path = url.startsWith('/') ? url : '/$url';
    return '$baseUrl$path';
  }

  bool get hasProfileImage =>
      (_profileImageFile != null && _profileImageFile!.existsSync()) ||
      (fullProfilePhotoUrl != null && fullProfilePhotoUrl!.isNotEmpty);

  String get fullName => _fullName;
  String get phoneNumber => _phoneNumber;
  String get email => _email;
  String get dob => _dob;
  String get gender => _gender;
  String get experience => _experience;
  String get specialization => _specialization;
  String get country => _country;
  String get state => _state;
  String get district => _district;
  String get area => _area;
  String get location => _location;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  // Setters with notifyListeners()
  void setProfileImage(File? file) {
    _profileImageFile = file;
    notifyListeners();
  }

  void setProfilePhotoUrl(String? url) {
    if (url != null && url.isNotEmpty) {
      _profilePhotoUrl = url;
      notifyListeners();
    }
  }

  static String formatCleanDob(String? rawDob) {
    if (rawDob == null || rawDob.trim().isEmpty) return '';
    final trimmed = rawDob.trim();
    if (trimmed == 'null') return '';

    // Check if it matches DD/MM/YYYY or DD-MM-YYYY
    final ddmmyyyyRegex = RegExp(r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})');
    final matchDmy = ddmmyyyyRegex.firstMatch(trimmed);
    if (matchDmy != null) {
      final day = matchDmy.group(1)!.padLeft(2, '0');
      final month = matchDmy.group(2)!.padLeft(2, '0');
      final year = matchDmy.group(3)!;
      return '$day/$month/$year';
    }

    // Try parsing as ISO or standard DateTime
    try {
      final dt = DateTime.tryParse(trimmed);
      if (dt != null) {
        final day = dt.day.toString().padLeft(2, '0');
        final month = dt.month.toString().padLeft(2, '0');
        final year = dt.year.toString();
        return '$day/$month/$year';
      }
    } catch (_) {}

    // Check if it starts with YYYY-MM-DD or YYYY/MM/DD
    final yyyymmddRegex = RegExp(r'^(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})');
    final matchYmd = yyyymmddRegex.firstMatch(trimmed);
    if (matchYmd != null) {
      final year = matchYmd.group(1)!;
      final month = matchYmd.group(2)!.padLeft(2, '0');
      final day = matchYmd.group(3)!.padLeft(2, '0');
      return '$day/$month/$year';
    }

    // If string has space or T, take just the first part
    if (trimmed.contains('T')) {
      return formatCleanDob(trimmed.split('T')[0]);
    }
    if (trimmed.contains(' ')) {
      return formatCleanDob(trimmed.split(' ')[0]);
    }

    return trimmed;
  }

  static String? normalizeGender(String? g) {
    if (g == null || g.trim().isEmpty || g.trim() == 'null') return null;
    final lower = g.trim().toLowerCase();
    if (lower == 'female' || lower == 'f') return 'Female';
    if (lower == 'male' || lower == 'm') return 'Male';
    if (lower == 'others' || lower == 'other' || lower == 'o') return 'Others';
    return lower[0].toUpperCase() + lower.substring(1);
  }

  void updateProfileDetails({
    String? nurseId,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? dob,
    String? gender,
    String? experience,
    String? specialization,
    String? country,
    String? state,
    String? district,
    String? area,
    String? location,
    double? latitude,
    double? longitude,
    String? profilePhotoUrl,
  }) {
    if (nurseId != null && nurseId.trim().isNotEmpty && nurseId.trim() != 'null') _nurseId = nurseId.trim();
    if (fullName != null && fullName.trim().isNotEmpty && fullName.trim() != 'null') _fullName = fullName.trim();
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty && phoneNumber.trim() != 'null') _phoneNumber = phoneNumber.trim();
    if (email != null && email.trim().isNotEmpty && email.trim() != 'null') _email = email.trim();
    if (dob != null && dob.trim().isNotEmpty && dob.trim() != 'null') {
      final cleaned = formatCleanDob(dob);
      if (cleaned.isNotEmpty) _dob = cleaned;
    }
    if (gender != null && gender.trim().isNotEmpty && gender.trim() != 'null') {
      _gender = normalizeGender(gender) ?? gender.trim();
    }
    if (experience != null && experience.trim().isNotEmpty && experience.trim() != 'null') _experience = experience.trim();
    if (specialization != null && specialization.trim().isNotEmpty && specialization.trim() != 'null') _specialization = specialization.trim();
    if (country != null && country.trim().isNotEmpty && country.trim() != 'null') _country = country.trim();
    if (state != null && state.trim().isNotEmpty && state.trim() != 'null') _state = state.trim();
    if (district != null && district.trim().isNotEmpty && district.trim() != 'null') _district = district.trim();
    if (area != null && area.trim().isNotEmpty && area.trim() != 'null') _area = area.trim();
    if (location != null && location.trim().isNotEmpty && location.trim() != 'null') _location = location.trim();
    if (latitude != null) _latitude = latitude;
    if (longitude != null) _longitude = longitude;
    if (profilePhotoUrl != null && profilePhotoUrl.trim().isNotEmpty && profilePhotoUrl.trim() != 'null') _profilePhotoUrl = profilePhotoUrl.trim();
    notifyListeners();
  }

  Widget buildAvatarWidget({
    double size = 40,
    Color fallbackBgColor = const Color(0xFF0052FF),
    Color fallbackIconColor = Colors.white,
    double iconSize = 24,
  }) {
    if (_profileImageFile != null && _profileImageFile!.existsSync()) {
      return ClipOval(
        child: Image.file(
          _profileImageFile!,
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
      );
    }

    final networkUrl = fullProfilePhotoUrl;
    if (networkUrl != null && networkUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          networkUrl,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon(size, fallbackBgColor, fallbackIconColor, iconSize);
          },
        ),
      );
    }

    return _buildFallbackIcon(size, fallbackBgColor, fallbackIconColor, iconSize);
  }

  Widget _buildFallbackIcon(double size, Color bgColor, Color iconColor, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }
}
