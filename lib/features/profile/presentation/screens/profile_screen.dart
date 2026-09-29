import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:howpa_nurse/core/network/token_storage.dart';
import 'package:howpa_nurse/core/routes/app_routes.dart';
import 'package:howpa_nurse/features/visits/presentation/screens/visits_screen.dart';
import 'package:howpa_nurse/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:howpa_nurse/features/profile/presentation/screens/personal_details_screen.dart';
import 'package:howpa_nurse/features/profile/presentation/screens/payment_earnings_screen.dart';
import 'package:howpa_nurse/core/services/user_profile_manager.dart';
import 'package:howpa_nurse/features/profile/data/models/profile_models.dart';
import 'package:howpa_nurse/features/profile/data/repositories/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileRepo = ProfileRepositoryImpl();
  int _currentBottomNavIndex = 3; // Profile selected
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkLostImageData();
  }

  Future<void> _checkLostImageData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      final file = response.file;
      if (file != null) {
        final f = File(file.path);
        if (f.existsSync()) {
          _uploadPickedImage(f);
        }
      }
    } catch (e) {
      debugPrint('Error retrieving lost image data: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _profileRepo.getProfile();
      if (user != null && mounted) {
        UserProfileManager.instance.updateProfileDetails(
          nurseId: user.id,
          fullName: user.fullName,
          phoneNumber: user.phone,
          email: user.email,
          dob: user.dob,
          gender: user.gender,
          experience: user.experienceYears?.toString(),
          specialization: user.specialization,
          location: user.address,
          area: user.city,
          district: user.city,
          state: 'Telangana',
          profilePhotoUrl: user.profilePhotoUrl,
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _uploadPickedImage(File file) async {
    UserProfileManager.instance.setProfileImage(file);
    setState(() {});

    try {
      final success = await _profileRepo.updateProfile(
        UpdateProfileRequest(
          fullName: UserProfileManager.instance.fullName,
          email: UserProfileManager.instance.email,
          gender: UserProfileManager.instance.gender.isNotEmpty ? UserProfileManager.instance.gender : 'Female',
          dob: UserProfileManager.instance.dob,
          specialization: UserProfileManager.instance.specialization,
          experienceYears: UserProfileManager.instance.experience,
          address: UserProfileManager.instance.location,
          city: UserProfileManager.instance.district,
          pincode: '500001',
          latitude: UserProfileManager.instance.latitude,
          longitude: UserProfileManager.instance.longitude,
        ),
        profilePhoto: file,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo uploaded and synced successfully!'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
          _loadProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated locally. Server sync pending.'),
              backgroundColor: Color(0xFFF59E0B),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading profile photo to server: $e');
    }
  }

  void _changeProfilePhoto() {
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
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final XFile? photo = await _picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 75,
                        );
                        if (photo != null) {
                          final file = File(photo.path);
                          if (file.existsSync()) {
                            await _uploadPickedImage(file);
                          }
                        }
                      } catch (e) {
                        debugPrint('Camera image pick error: $e');
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5C00).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF5C00), size: 26),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Camera',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 75,
                        );
                        if (image != null) {
                          final file = File(image.path);
                          if (file.existsSync()) {
                            await _uploadPickedImage(file);
                          }
                        }
                      } catch (e) {
                        debugPrint('Gallery image pick error: $e');
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0052FF).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0052FF), size: 26),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Gallery',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListenableBuilder(
                listenable: UserProfileManager.instance,
                builder: (context, child) {
                  final name = UserProfileManager.instance.fullName;
                  final spec = UserProfileManager.instance.specialization;

                  return Column(
                    children: [
                      const SizedBox(height: 40),
                      // Avatar with camera icon
                      Center(
                        child: GestureDetector(
                          onTap: _changeProfilePhoto,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                                ),
                                child: UserProfileManager.instance.buildAvatarWidget(
                                  size: 100,
                                  fallbackBgColor: const Color(0xFFFF5C00),
                                  fallbackIconColor: Colors.white,
                                  iconSize: 50,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0052FF), size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name and Verified Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: Color(0xFF0052FF), size: 22),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Specialization
                      Text(
                        spec,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Menu Options Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      title: 'Personal Details',
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF0052FF),
                      iconBgColor: const Color(0xFFEFF4FF),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalDetailsScreen()));
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
                    _buildMenuItem(
                      title: 'Payment / Earnings',
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xFFFF5C00),
                      iconBgColor: const Color(0xFFFFF4ED),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentEarningsScreen()));
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
                    _buildMenuItem(
                      title: 'Help & Support',
                      icon: Icons.headset_mic_outlined,
                      iconColor: const Color(0xFF0052FF),
                      iconBgColor: const Color(0xFFEFF4FF),
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
                    _buildMenuItem(
                      title: 'Terms & Privacy Policy',
                      icon: Icons.policy_outlined,
                      iconColor: const Color(0xFFFF5C00),
                      iconBgColor: const Color(0xFFFFF4ED),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Log Out Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text('Are you sure you want to log out of your account?'),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await TokenStorage.clear();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.phoneLogin,
                                    (route) => false,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                              child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFFE0E7FF), // Light blue background for selected pill
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0052FF));
            }
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Color(0xFF94A3B8));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF0052FF), size: 24);
            }
            return const IconThemeData(color: Color(0xFF94A3B8), size: 24);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentBottomNavIndex,
          onDestinationSelected: (index) {
            if (index == _currentBottomNavIndex) return;
            if (index == 0) {
              Navigator.popUntil(context, (route) => route.isFirst);
            } else if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const VisitsScreen()));
            } else if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const VitalsScreen()));
            } else {
              setState(() {
                _currentBottomNavIndex = index;
              });
            }
          },
          backgroundColor: Colors.white,
          elevation: 0,
          height: 65,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Visits',
            ),
            NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined),
              selectedIcon: Icon(Icons.monitor_heart_rounded),
              label: 'Vitals',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
