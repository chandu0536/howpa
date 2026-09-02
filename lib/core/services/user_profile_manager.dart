import 'dart:io';
import 'package:flutter/material.dart';

class UserProfileManager extends ChangeNotifier {
  static final UserProfileManager instance = UserProfileManager._internal();

  UserProfileManager._internal();

  File? _profileImageFile;
  String? _profileImageUrl;
  String _fullName = 'Priya Sharma';
  String _phoneNumber = '+91 98765 43210';
  String _email = 'priya.sharma@example.com';
  String _dob = '15/08/1995';
  String _gender = 'Female';
  String _experience = '5';
  String _specialization = 'Elder Care Specialist';
  String _country = 'India';
  String _state = 'Telangana';
  String _district = 'Hyderabad';
  String _area = 'Yousufguda';
  String _location = '12-3-456, Green Avenue, Near Park';
  String _approvalStatus = 'UNDER_REVIEW';
  bool _isVerified = false;
  String _nurseCode = 'NUR-0002';
  String _profileStatus = 'COMPLETED';

  // Getters
  File? get profileImageFile => _profileImageFile;
  bool get hasProfileImage => _profileImageFile != null && _profileImageFile!.existsSync();
  String? get profileImageUrl => _profileImageUrl;
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
  String get approvalStatus => _approvalStatus;
  bool get isVerified => _isVerified;
  String get nurseCode => _nurseCode;
  String get profileStatus => _profileStatus;

  bool get isApproved =>
      _approvalStatus.toUpperCase() == 'APPROVED' || _isVerified;

  // Setters with notifyListeners()
  void setProfileImage(File? file) {
    _profileImageFile = file;
    notifyListeners();
  }

  void setApprovalStatus(String status, {bool? verified}) {
    _approvalStatus = status;
    if (verified != null) _isVerified = verified;
    notifyListeners();
  }

  void updateProfileDetails({
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
    String? profileImageUrl,
    String? approvalStatus,
    bool? isVerified,
    String? nurseCode,
    String? profileStatus,
  }) {
    if (fullName != null && fullName.isNotEmpty) _fullName = fullName;
    if (phoneNumber != null && phoneNumber.isNotEmpty) _phoneNumber = phoneNumber;
    if (email != null && email.isNotEmpty) _email = email;
    if (dob != null && dob.isNotEmpty) _dob = dob;
    if (gender != null && gender.isNotEmpty) _gender = gender;
    if (experience != null && experience.isNotEmpty) _experience = experience;
    if (specialization != null && specialization.isNotEmpty) _specialization = specialization;
    if (country != null && country.isNotEmpty) _country = country;
    if (state != null && state.isNotEmpty) _state = state;
    if (district != null && district.isNotEmpty) _district = district;
    if (area != null && area.isNotEmpty) _area = area;
    if (location != null && location.isNotEmpty) _location = location;
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) _profileImageUrl = profileImageUrl;
    if (approvalStatus != null && approvalStatus.isNotEmpty) _approvalStatus = approvalStatus;
    if (isVerified != null) _isVerified = isVerified;
    if (nurseCode != null && nurseCode.isNotEmpty) _nurseCode = nurseCode;
    if (profileStatus != null && profileStatus.isNotEmpty) _profileStatus = profileStatus;
    notifyListeners();
  }

  void clear() {
    _profileImageFile = null;
    _profileImageUrl = null;
    _fullName = '';
    _phoneNumber = '';
    _email = '';
    _dob = '';
    _gender = '';
    _experience = '';
    _specialization = '';
    _country = 'India';
    _state = '';
    _district = '';
    _area = '';
    _location = '';
    _approvalStatus = 'UNDER_REVIEW';
    _isVerified = false;
    _nurseCode = '';
    _profileStatus = 'PENDING';
    notifyListeners();
  }
}
