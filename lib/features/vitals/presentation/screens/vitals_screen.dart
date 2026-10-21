import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:howpa_nurse/features/visits/presentation/screens/visits_screen.dart';
import 'package:howpa_nurse/features/vitals/presentation/screens/update_vitals_screen.dart';
import 'package:howpa_nurse/features/profile/presentation/screens/profile_screen.dart';
import 'package:howpa_nurse/features/visits/data/models/visit_models.dart';
import 'package:howpa_nurse/features/visits/data/repositories/visits_repository.dart';

class VitalsItem {
  final String id;
  final String? orderId;
  final String patientName;
  final String timeText;
  final String statusText;
  final String noteText;
  final String avatarUrl;
  final String? patientAge;
  final String? patientGender;
  final bool isFamilyMember;
  final String? relation;

  VitalsItem({
    required this.id,
    this.orderId,
    required this.patientName,
    required this.timeText,
    required this.statusText,
    required this.noteText,
    required this.avatarUrl,
    this.patientAge,
    this.patientGender,
    this.isFamilyMember = false,
    this.relation,
  });
}

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  final _visitsRepo = VisitsRepositoryImpl();
  int _currentBottomNavIndex = 2; // Vitals selected
  bool _isLoading = true;
  String _searchQuery = '';
  List<VitalsItem> _vitalsList = [];

  @override
  void initState() {
    super.initState();
    _loadVitalsData();
  }

  Future<void> _loadVitalsData({String? query}) async {
    setState(() => _isLoading = true);
    final visits = await _visitsRepo.getTodayVisits();
    if (mounted) {
      setState(() {
        _vitalsList = visits.where((v) {
          if (query == null || query.isEmpty) return true;
          return v.patientName.toLowerCase().contains(query.toLowerCase());
        }).map((v) {
          return VitalsItem(
            id: v.id,
            orderId: v.displayOrderId,
            patientName: v.patientName,
            timeText: v.time,
            statusText: 'Vitals updated recently',
            noteText: 'Please monitor BP every 2 hours and update...',
            avatarUrl: v.avatarUrl,
            patientAge: v.patientAge,
            patientGender: v.patientGender,
            isFamilyMember: v.isFamilyMember,
            relation: v.relation,
          );
        }).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text(
                'Vitals',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B728E), // Bluish grey
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _loadVitalsData(query: val);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by patient name',
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // List of Patients
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _vitalsList.isEmpty
                      ? const Center(
                          child: Text(
                            'No patients found',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadVitalsData(query: _searchQuery),
                          color: const Color(0xFF0052FF),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _vitalsList.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              color: Color(0xFFF1F5F9),
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              return _buildVitalsItem(_vitalsList[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildVitalsItem(VitalsItem item) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1F5F9),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: ClipOval(
                  child: _buildAvatar(item.avatarUrl, item.patientName, 56),
                ),
              ),
              const SizedBox(width: 16),
              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.patientName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.timeText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDemographics(
                        gender: item.patientGender,
                        age: item.patientAge,
                        isFamilyMember: item.isFamilyMember,
                        bookedByName: null,
                      ),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (item.orderId != null && item.orderId!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tag_rounded, size: 11, color: Color(0xFF64748B)),
                            const SizedBox(width: 3),
                            Text(
                              'Order ID: ${item.orderId}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.image_outlined, // Matching the small blue icon in the design
                          size: 14,
                          color: Color(0xFF0052FF),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.statusText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Text(
                    //   item.noteText,
                    //   style: const TextStyle(
                    //     fontSize: 13,
                    //     color: Color(0xFF64748B),
                    //   ),
                    //   maxLines: 1,
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Update Vitals Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateVitalsScreen(
                      appointmentId: item.id,
                      orderId: item.orderId,
                      patientName: item.patientName,
                      avatarUrl: item.avatarUrl,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.monitor_heart_outlined,
                size: 20,
                color: Color(0xFF0052FF),
              ),
              label: const Text(
                'Update Vitals',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0052FF),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF0052FF), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
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
              Navigator.popUntil(context, (route) => route.isFirst); // Go back to Home
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VisitsScreen()),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
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

  Widget _buildAvatar(String avatarUrl, String patientName, double size) {
    final clean = avatarUrl.trim();
    if (clean.isNotEmpty && clean != 'null' && clean != 'undefined') {
      if (clean.startsWith('data:image/')) {
        try {
          final commaIdx = clean.indexOf(',');
          final base64Str = commaIdx != -1 ? clean.substring(commaIdx + 1) : clean;
          final bytes = base64Decode(base64Str.replaceAll(RegExp(r'\s+'), ''));
          return Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallbackAvatar(size),
          );
        } catch (_) {}
      }

      if (clean.startsWith('file://') ||
          (!clean.startsWith('http://') &&
              !clean.startsWith('https://') &&
              File(clean.replaceFirst('file://', '')).existsSync())) {
        try {
          final filePath = clean.replaceFirst('file://', '');
          final file = File(filePath);
          if (file.existsSync()) {
            return Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallbackAvatar(size),
            );
          }
        } catch (_) {}
      }

      final fullUrl = formatImageUrl(clean);
      if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
        return Image.network(
          fullUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar(size);
          },
        );
      }
    }

    return _buildFallbackAvatar(size);
  }

  Widget _buildFallbackAvatar(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        color: const Color(0xFF94A3B8),
        size: size * 0.55,
      ),
    );
  }
}
