import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:howpa_nurse/features/auth/presentation/screens/phone_number_screen.dart';
import 'package:howpa_nurse/features/auth/presentation/screens/registration_step2_screen.dart';
import 'package:howpa_nurse/features/auth/presentation/screens/map_picker_screen.dart';
import 'package:howpa_nurse/features/profile/data/models/profile_models.dart';
import 'package:howpa_nurse/features/profile/data/repositories/profile_repository.dart';
import 'package:howpa_nurse/core/services/user_profile_manager.dart';
import 'package:howpa_nurse/core/services/location_service.dart';
import 'package:howpa_nurse/core/network/api_exceptions.dart';

class RegistrationStep1Screen extends StatefulWidget {
  final String phoneNumber;

  const RegistrationStep1Screen({
    super.key,
    this.phoneNumber = '+91 98765 43210',
  });

  @override
  State<RegistrationStep1Screen> createState() => _RegistrationStep1ScreenState();
}

class _RegistrationStep1ScreenState extends State<RegistrationStep1Screen> {
  final _formKey = GlobalKey<FormState>();

  // Profile Picture state
  bool _hasProfilePhoto = false;
  File? _profileImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isFetchingLocation = false;
  bool _isLoading = false;

  // Personal & Professional details controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String? _selectedGender;
  double? _latitude;
  double? _longitude;

  // Location controllers (Positioned AT THE VERY END)
  final TextEditingController _countryController = TextEditingController(text: 'India');
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedSpecialization;
  final List<String> _specializations = [
    'General Care',
    'Elder Care',
    'Post-Surgery Care',
    'Critical Care',
    'Pediatric Care',
    'Palliative Care',
    'Maternal & Newborn Care',
    'Physiotherapy & Rehab',
  ];

  final Map<String, FocusNode> _focusNodes = {
    'fullName': FocusNode(),
    'dob': FocusNode(),
    'email': FocusNode(),
    'experience': FocusNode(),
    'country': FocusNode(),
    'state': FocusNode(),
    'district': FocusNode(),
    'area': FocusNode(),
    'location': FocusNode(),
  };

  FocusNode _getFocusNode(String key) {
    return _focusNodes.putIfAbsent(key, () {
      final node = FocusNode();
      node.addListener(() {
        if (mounted) setState(() {});
      });
      return node;
    });
  }

  @override
  void initState() {
    super.initState();

    // Listen to focus nodes
    _focusNodes.forEach((key, node) {
      node.addListener(() {
        setState(() {});
      });
    });

    // Listen to text changes to smoothly animate sticky orange progress bar
    _fullNameController.addListener(_onFieldChanged);
    _dobController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _experienceController.addListener(_onFieldChanged);
    _countryController.addListener(_onFieldChanged);
    _stateController.addListener(_onFieldChanged);
    _districtController.addListener(_onFieldChanged);
    _areaController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);

    // Auto-prefill data previously entered by the user or stored in backend
    _loadExistingData();
  }

  void _loadExistingData() {
    final manager = UserProfileManager.instance;

    if (manager.fullName.isNotEmpty && manager.fullName != 'Nurse') {
      _fullNameController.text = manager.fullName;
    }
    if (manager.dob.isNotEmpty) {
      _dobController.text = UserProfileManager.formatCleanDob(manager.dob);
    }
    if (manager.email.isNotEmpty) {
      _emailController.text = manager.email;
    }
    if (manager.gender.isNotEmpty) {
      _selectedGender = UserProfileManager.normalizeGender(manager.gender);
    }
    if (manager.experience.isNotEmpty && manager.experience != '0') {
      _experienceController.text = manager.experience;
    }
    if (manager.specialization.isNotEmpty && manager.specialization != 'Nurse Care') {
      _selectedSpecialization = manager.specialization;
    }
    if (manager.country.isNotEmpty) {
      _countryController.text = manager.country;
    }
    if (manager.state.isNotEmpty) {
      _stateController.text = manager.state;
    }
    if (manager.district.isNotEmpty) {
      _districtController.text = manager.district;
    }
    if (manager.area.isNotEmpty) {
      _areaController.text = manager.area;
    }
    if (manager.location.isNotEmpty) {
      _locationController.text = manager.location;
    }
    if (manager.latitude != null) {
      _latitude = manager.latitude;
    }
    if (manager.longitude != null) {
      _longitude = manager.longitude;
    }
    if (manager.profileImageFile != null && manager.profileImageFile!.existsSync()) {
      _profileImageFile = manager.profileImageFile;
      _hasProfilePhoto = true;
    } else if (manager.profilePhotoUrl != null && manager.profilePhotoUrl!.isNotEmpty) {
      _hasProfilePhoto = true;
    }

    _fetchProfileFromBackend();
  }

  Future<void> _fetchProfileFromBackend() async {
    try {
      final user = await ProfileRepositoryImpl().getProfile();
      if (user != null && mounted) {
        setState(() {
          if (_fullNameController.text.isEmpty && user.fullName != null && user.fullName!.isNotEmpty) {
            _fullNameController.text = user.fullName!;
          }
          if (user.email != null && user.email!.trim().isNotEmpty && user.email!.trim() != 'null') {
            _emailController.text = user.email!.trim();
          }
          if (user.dob != null && user.dob!.trim().isNotEmpty && user.dob!.trim() != 'null') {
            final cleaned = UserProfileManager.formatCleanDob(user.dob);
            if (cleaned.isNotEmpty) {
              _dobController.text = cleaned;
            }
          }
          if (user.gender != null && user.gender!.trim().isNotEmpty && user.gender!.trim() != 'null') {
            final normalized = UserProfileManager.normalizeGender(user.gender);
            if (normalized != null) {
              _selectedGender = normalized;
            }
          }
          if (_experienceController.text.isEmpty && user.experienceYears != null) {
            _experienceController.text = user.experienceYears.toString();
          }
          if (_selectedSpecialization == null && user.specialization != null && user.specialization!.isNotEmpty) {
            _selectedSpecialization = user.specialization;
          }
          if (_locationController.text.isEmpty && user.address != null && user.address!.isNotEmpty) {
            _locationController.text = user.address!;
          }
          if (_districtController.text.isEmpty && user.city != null && user.city!.isNotEmpty) {
            _districtController.text = user.city!;
          }
          if (_latitude == null && user.latitude != null) {
            _latitude = user.latitude;
          }
          if (_longitude == null && user.longitude != null) {
            _longitude = user.longitude;
          }
          if (!_hasProfilePhoto && user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty) {
            _hasProfilePhoto = true;
          }
        });
      }
    } catch (_) {}
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_onFieldChanged);
    _dobController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _experienceController.removeListener(_onFieldChanged);
    _countryController.removeListener(_onFieldChanged);
    _stateController.removeListener(_onFieldChanged);
    _districtController.removeListener(_onFieldChanged);
    _areaController.removeListener(_onFieldChanged);
    _locationController.removeListener(_onFieldChanged);

    _fullNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _areaController.dispose();
    _locationController.dispose();

    _focusNodes.forEach((_, node) => node.dispose());
    super.dispose();
  }

  // Dynamic progress calculation as user enters details
  double _calculateProgress() {
    int filledFields = 0;
    const int totalFields = 12;

    if (_hasProfilePhoto) filledFields++;
    if (_fullNameController.text.trim().isNotEmpty) filledFields++;
    if (_dobController.text.trim().isNotEmpty) filledFields++;
    if (_selectedGender != null) filledFields++;
    if (_emailController.text.trim().isNotEmpty) filledFields++;
    if (_experienceController.text.trim().isNotEmpty) filledFields++;
    if (_selectedSpecialization != null && _selectedSpecialization!.isNotEmpty) filledFields++;
    if (_countryController.text.trim().isNotEmpty) filledFields++;
    if (_stateController.text.trim().isNotEmpty) filledFields++;
    if (_districtController.text.trim().isNotEmpty) filledFields++;
    if (_areaController.text.trim().isNotEmpty) filledFields++;
    if (_locationController.text.trim().isNotEmpty) filledFields++;

    return (filledFields / totalFields).clamp(0.1, 1.0);
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime(now.year - 20, now.month, now.day);
    final DateTime firstDate = DateTime(now.year - 70);
    final DateTime lastDate = DateTime(now.year - 18);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF5C00),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0052FF),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final formattedDate =
          "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
      setState(() {
        _dobController.text = formattedDate;
      });
    }
  }

  void _showPhotoPicker() {
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
              const Text(
                'Upload Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a source to upload your profile picture',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPhotoOption(
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
                            setState(() {
                              _profileImageFile = file;
                              _hasProfilePhoto = true;
                            });
                            UserProfileManager.instance.setProfileImage(file);
                          }
                        }
                      } catch (e) {
                        debugPrint('Registration Step 1 camera error: $e');
                      }
                    },
                  ),
                  _buildPhotoOption(
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
                            debugPrint('========== IMAGE UPLOAD DEBUG ==========');
                            debugPrint('Step 1 Photo picked from Gallery: ${file.path}');
                            debugPrint('=========================================');
                            setState(() {
                              _profileImageFile = file;
                              _hasProfilePhoto = true;
                            });
                            UserProfileManager.instance.setProfileImage(file);
                          }
                        }
                      } catch (e) {
                        debugPrint('Registration Step 1 gallery error: $e');
                      }
                    },
                  ),
                  if (_hasProfilePhoto)
                    _buildPhotoOption(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove',
                      color: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _profileImageFile = null;
                          _hasProfilePhoto = false;
                        });
                        UserProfileManager.instance.setProfileImage(null);
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

  Widget _buildPhotoOption({
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

  Future<void> _onNextPressed() async {
    if (_isLoading) return;

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select your Gender'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
      
      if (_selectedSpecialization == null || _selectedSpecialization!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select your Nursing Specialization'),
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

      // Save user details & profile photo to central manager
      UserProfileManager.instance.setProfileImage(_profileImageFile);
      UserProfileManager.instance.updateProfileDetails(
        fullName: _fullNameController.text.trim(),
        phoneNumber: widget.phoneNumber,
        email: _emailController.text.trim(),
        dob: UserProfileManager.formatCleanDob(_dobController.text.trim()),
        gender: UserProfileManager.normalizeGender(_selectedGender) ?? _selectedGender,
        experience: _experienceController.text.trim(),
        specialization: _selectedSpecialization,
        country: _countryController.text.trim(),
        state: _stateController.text.trim(),
        district: _districtController.text.trim(),
        area: _areaController.text.trim(),
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      try {
        // Call Update Profile API and await backend confirmation
        final success = await ProfileRepositoryImpl().updateProfile(
          UpdateProfileRequest(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            gender: UserProfileManager.normalizeGender(_selectedGender) ?? _selectedGender ?? 'Female',
            dob: UserProfileManager.formatCleanDob(_dobController.text.trim()),
            specialization: _selectedSpecialization ?? 'General Care',
            experienceYears: _experienceController.text.trim(),
            address: _locationController.text.trim(),
            city: _districtController.text.trim(),
            pincode: '500001',
            latitude: _latitude,
            longitude: _longitude,
          ),
          profilePhoto: _profileImageFile,
        );

        if (!mounted) return;

        if (success) {
          // Navigate to Registration Step 2 Screen ONLY on backend confirmation
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => RegistrationStep2Screen(
                phoneNumber: widget.phoneNumber,
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update profile details. Please try again.'),
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
            content: Text('Error updating profile: $e'),
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
  }

  void _showSpecializationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Select Nursing Specialization',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _specializations.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final item = _specializations[index];
                    final isSelected = _selectedSpecialization == item;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      title: Text(
                        item,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF0052FF) : const Color(0xFF1E293B),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0052FF))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedSpecialization = item;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final details = await LocationService.instance.fetchCurrentLocationDetails();
      if (details != null && mounted) {
        setState(() {
          _latitude = details.latitude;
          _longitude = details.longitude;
          if (details.country.isNotEmpty) _countryController.text = details.country;
          if (details.state.isNotEmpty) _stateController.text = details.state;
          if (details.district.isNotEmpty) _districtController.text = details.district;
          if (details.area.isNotEmpty) _areaController.text = details.area;
          if (details.formattedAddress.isNotEmpty) _locationController.text = details.formattedAddress;
        });

        // Also update UserProfileManager immediately
        UserProfileManager.instance.updateProfileDetails(
          latitude: details.latitude,
          longitude: details.longitude,
          country: details.country,
          state: details.state,
          district: details.district,
          area: details.area,
          location: details.formattedAddress,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GPS Location (${details.latitude.toStringAsFixed(4)}, ${details.longitude.toStringAsFixed(4)}) fetched successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0052FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not access current location. Please grant GPS permission or select on map.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LocationDetails>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLat: _latitude ?? UserProfileManager.instance.latitude ?? 17.385044,
          initialLng: _longitude ?? UserProfileManager.instance.longitude ?? 78.486671,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        if (result.country.isNotEmpty) _countryController.text = result.country;
        if (result.state.isNotEmpty) _stateController.text = result.state;
        if (result.district.isNotEmpty) _districtController.text = result.district;
        if (result.area.isNotEmpty) _areaController.text = result.area;
        if (result.formattedAddress.isNotEmpty) _locationController.text = result.formattedAddress;
      });

      // Also update UserProfileManager immediately
      UserProfileManager.instance.updateProfileDetails(
        latitude: result.latitude,
        longitude: result.longitude,
        country: result.country,
        state: result.state,
        district: result.district,
        area: result.area,
        location: result.formattedAddress,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Location (${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}) selected from Map!',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF5C00),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
    final progress = _calculateProgress();

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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              color: const Color(0xFFFCFCFD),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Step 1 of 2',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}% Done',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5C00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 2-Step Progress Bars with Orange Fill
                  Row(
                    children: [
                      // Step 1: Smoothly animates orange line as user enters details
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
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeInOut,
                                    width: constraints.maxWidth * progress,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5C00), // Active Orange
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Step 2 Segment (Inactive grey in Step 1)
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Screen Title and Subtitle
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'Let’s Get You Started',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B1938),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Enter your personal and location details',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // TOP MIDDLE PROFILE PICTURE UPLOAD
                      Center(
                        child: GestureDetector(
                          onTap: _showPhotoPicker,
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _hasProfilePhoto
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF1F5F9),
                                      border: Border.all(
                                        color: _hasProfilePhoto
                                            ? const Color(0xFFFF5C00)
                                            : const Color(0xFFCBD5E1),
                                        width: 2.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x1A000000),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _profileImageFile != null
                                        ? ClipOval(
                                            child: Image.file(
                                              _profileImageFile!,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : (UserProfileManager.instance.fullProfilePhotoUrl != null &&
                                                UserProfileManager.instance.fullProfilePhotoUrl!.isNotEmpty)
                                            ? ClipOval(
                                                child: Image.network(
                                                  UserProfileManager.instance.fullProfilePhotoUrl!,
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(
                                                    Icons.person_rounded,
                                                    size: 58,
                                                    color: Color(0xFF0052FF),
                                                  ),
                                                ),
                                              )
                                            : _hasProfilePhoto
                                                ? ClipOval(
                                                    child: Container(
                                                      color: const Color(0x1A0052FF),
                                                      child: const Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            Icons.person_rounded,
                                                            size: 58,
                                                            color: Color(0xFF0052FF),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.person_outline_rounded,
                                                    size: 48,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                  ),
                                  // Camera badge button
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFFF5C00),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x33FF5C00),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _hasProfilePhoto ? 'Profile Photo Added' : 'Upload Profile Picture',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _hasProfilePhoto
                                          ? const Color(0xFFFF5C00)
                                          : const Color(0xFF0052FF),
                                    ),
                                  ),
                                  if (_hasProfilePhoto) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: Color(0xFFFF5C00),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 1. Full Name Field
                      _buildFieldLabel('Full Name'),
                      _buildInputField(
                        controller: _fullNameController,
                        focusNode: _getFocusNode('fullName'),
                        hintText: 'Enter your full name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // 2. Mobile Number Field (Prefilled / Read Only Style)
                      _buildFieldLabel('Mobile Number'),
                      Container(
                        width: double.infinity,
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.phoneNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. Date of Birth Field
                      _buildFieldLabel('Date of Birth'),
                      GestureDetector(
                        onTap: _selectDateOfBirth,
                        child: AbsorbPointer(
                          child: _buildInputField(
                            controller: _dobController,
                            focusNode: _getFocusNode('dob'),
                            hintText: 'DD/MM/YYYY',
                            keyboardType: TextInputType.datetime,
                            suffixIcon: const Icon(
                              Icons.calendar_today_rounded,
                              color: Color(0xFFFF5C00),
                              size: 20,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please select your Date of Birth';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Gender Selection Field
                      _buildFieldLabel('Gender'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGenderOption('Male', Icons.male_rounded),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildGenderOption('Female', Icons.female_rounded),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildGenderOption('Others', Icons.person_outline_rounded),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 4. Email ID Field
                      _buildFieldLabel('Email ID'),
                      _buildInputField(
                        controller: _emailController,
                        focusNode: _getFocusNode('email'),
                        hintText: 'Enter your email ID',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email ID';
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // 5. Years of Experience Field (Max 2 Digits)
                      _buildFieldLabel('Years of Experience'),
                      _buildInputField(
                        controller: _experienceController,
                        focusNode: _getFocusNode('experience'),
                        hintText: 'Enter years of experience (max 2 digits)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter years of experience';
                          }
                          if (value.trim().length > 2) {
                            return 'Experience cannot exceed 2 digits';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // 5. Nursing Specialization Dropdown Selector Field
                      _buildFieldLabel('Nursing Specialization'),
                      GestureDetector(
                        onTap: _showSpecializationPicker,
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedSpecialization ?? 'Select your specialization',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _selectedSpecialization != null
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFF94A3B8),
                                    fontWeight: _selectedSpecialization != null
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFF64748B),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Text(
                          'e.g. General Care, Elder Care, Post-Surgery',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // LOCATION DETAILS SECTION (AT THE VERY END / LAST)
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0x1AFF5C00),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFFF5C00),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Location Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Location Action Buttons: Current Location & Select on Map
                      Row(
                        children: [
                          // 1. Current GPS Location Button
                          Expanded(
                            child: InkWell(
                              onTap: _isFetchingLocation ? null : _useCurrentLocation,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF0052FF).withValues(alpha: 0.3),
                                    width: 1.2,
                                  ),
                                ),
                                child: _isFetchingLocation
                                    ? const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF0052FF),
                                          ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.my_location_rounded,
                                            size: 18,
                                            color: Color(0xFF0052FF),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Current Location',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0052FF),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 2. Select on Google Map Button
                          Expanded(
                            child: InkWell(
                              onTap: _openMapPicker,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFF5C00).withValues(alpha: 0.3),
                                    width: 1.2,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.map_rounded,
                                      size: 18,
                                      color: Color(0xFFFF5C00),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Select on Map',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFF5C00),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_latitude != null && _longitude != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.gps_fixed_rounded, color: Color(0xFF16A34A), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'GPS Coordinates: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)} (Ready)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Divider with subtitle
                      Row(
                        children: const [
                          Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              'Or verify / edit fields',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 6. Country Field
                      _buildFieldLabel('Country'),
                      _buildInputField(
                        controller: _countryController,
                        focusNode: _getFocusNode('country'),
                        hintText: 'Enter your country (e.g. India)',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your country';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // 7. State Field
                      _buildFieldLabel('State'),
                      _buildInputField(
                        controller: _stateController,
                        focusNode: _getFocusNode('state'),
                        hintText: 'Enter your state',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your state';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // 8. District Field ("Diste")
                      _buildFieldLabel('District'),
                      _buildInputField(
                        controller: _districtController,
                        focusNode: _getFocusNode('district'),
                        hintText: 'Enter your district',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your district';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // 9. Area Field
                      _buildFieldLabel('Area'),
                      _buildInputField(
                        controller: _areaController,
                        focusNode: _getFocusNode('area'),
                        hintText: 'Enter your area or locality',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your area';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // 10. Location / Full Address Field ("Loction")
                      _buildFieldLabel('Location / Street Address'),
                      _buildInputField(
                        controller: _locationController,
                        focusNode: _getFocusNode('location'),
                        hintText: 'Enter your complete location or address details',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your location details';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 36),

                      // Next Gradient Button
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
                          onPressed: _isLoading ? null : _onNextPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Next',
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
          ],
        ),
      ),
    ),
  );
}

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender != null &&
        _selectedGender!.trim().toLowerCase() == gender.trim().toLowerCase();
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0052FF) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF0052FF) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                gender,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0052FF) : const Color(0xFF334155),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEF4444),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? const Color(0xFF0052FF) : const Color(0xFFE2E8F0),
          width: isFocused ? 1.8 : 1.2,
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
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 15,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.normal,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
          errorStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xFFEF4444),
          ),
        ),
      ),
    );
  }
}
