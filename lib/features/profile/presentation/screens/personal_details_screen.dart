import 'package:flutter/material.dart';
import 'package:howpa_nurse/core/services/user_profile_manager.dart';
import 'package:howpa_nurse/features/profile/data/repositories/profile_repository.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _profileRepo = ProfileRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await _profileRepo.getProfile();
    if (user != null && mounted) {
      UserProfileManager.instance.updateProfileDetails(
        fullName: user.fullName,
        phoneNumber: user.phone,
        location: user.address,
        area: user.city,
        district: user.city,
        state: 'Telangana',
        specialization: user.specialization,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Personal Details',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.lock_outline_rounded, color: Color(0xFF0F172A), size: 18),
          ],
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: UserProfileManager.instance,
        builder: (context, child) {
          final profile = UserProfileManager.instance;
          final hasPhoto = profile.hasProfileImage;
          final photoFile = profile.profileImageFile;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'These details are locked and cannot be edited.\nContact support for changes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child: ClipOval(
                          child: hasPhoto && photoFile != null
                              ? Image.file(
                                  photoFile,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                )
                              : Image.network(
                                  'https://images.unsplash.com/photo-1594824436951-7f12bc5a6f23?auto=format&fit=crop&q=80&w=200',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, size: 50, color: Colors.grey),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Fields
                      _buildDetailCard(
                        title: 'Full Name',
                        value: profile.fullName,
                        icon: Icons.person_outline_rounded,
                      ),
                      _buildDetailCard(
                        title: 'Mobile Number',
                        value: profile.phoneNumber,
                        icon: Icons.phone_outlined,
                      ),
                      _buildDetailCard(
                        title: 'Email ID',
                        value: profile.email,
                        icon: Icons.email_outlined,
                      ),
                      _buildDetailCard(
                        title: 'Home Address',
                        value: profile.location,
                        icon: Icons.home_outlined,
                      ),
                      _buildDetailCard(
                        title: 'Years of Experience',
                        value: '${profile.experience} Years',
                        icon: Icons.work_outline_rounded,
                      ),
                      _buildDetailCard(
                        title: 'Nursing Specialization',
                        value: profile.specialization,
                        icon: Icons.favorite_border_rounded,
                      ),
                      _buildDetailCard(
                        title: 'City / Area',
                        value: '${profile.area}, ${profile.district}, ${profile.state}',
                        icon: Icons.location_on_outlined,
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF4FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0052FF), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
