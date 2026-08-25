import 'dart:io';
import 'package:flutter/material.dart';

class UserProfileManager extends ChangeNotifier {
  static final UserProfileManager instance = UserProfileManager._internal();

  UserProfileManager._internal();

  File? _profileImageFile;
  String _fullName = 'Priya Sharma';
  String _phoneNumber = '+91 98765 43210';
  String _email = 'priya.sharma@example.com';
  String _dob = '15/08/1995';
  String _gender = 'Female';
  String _experience = '5';
  String _specialization = 'Elder Care';
  String _country = 'India';
  String _state = 'Telangana';
  String _district = 'Hyderabad';
  String _area = 'Yousufguda';
  String _location = 'D No. 12-25, Srinivasa Nagar, Hyderabad';

  // Getters
  File? get profileImageFile => _profileImageFile;
  bool get hasProfileImage => _profileImageFile != null && _profileImageFile!.existsSync();
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

  // Setters with notifyListeners()
  void setProfileImage(File? file) {
    _profileImageFile = file;
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
    notifyListeners();
  }
}
