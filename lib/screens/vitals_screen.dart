import 'package:flutter/material.dart';
import 'package:howpa_nurse/screens/visits_screen.dart';
import 'package:howpa_nurse/screens/update_vitals_screen.dart';
import 'package:howpa_nurse/screens/profile_screen.dart';

class VitalsItem {
  final String id;
  final String patientName;
  final String timeText;
  final String statusText;
  final String noteText;
  final String avatarUrl;

  VitalsItem({
    required this.id,
    required this.patientName,
    required this.timeText,
    required this.statusText,
    required this.noteText,
    required this.avatarUrl,
  });
}

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  int _currentBottomNavIndex = 2; // Vitals selected

  final List<VitalsItem> _vitalsList = [
    VitalsItem(
      id: '1',
      patientName: 'Mrs. Kamala Devi',
      timeText: '10:42 AM',
      statusText: 'Vitals updated 2 hours ago',
      noteText: 'Please monitor BP every 2 hours and update...',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200',
    ),
    VitalsItem(
      id: '2',
      patientName: 'Mr. Ramesh Babu',
      timeText: '9:15 AM',
      statusText: 'Vitals updated 1 hour ago',
      noteText: 'Continue the same medication. Diet should be low...',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
    ),
    VitalsItem(
      id: '3',
      patientName: 'Mr. Arjun Rao',
      timeText: 'Yesterday',
      statusText: 'Vitals updated yesterday',
      noteText: 'X-ray looks good. Start light physiotherapy...',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200',
    ),
    VitalsItem(
      id: '4',
      patientName: 'Mrs. Sunitha Rani',
      timeText: 'Mon, 30 Jun',
      statusText: 'Vitals updated on 30 Jun',
      noteText: 'Apply the prescribed ointment twice daily and...',
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=200',
    ),
    VitalsItem(
      id: '5',
      patientName: 'Mr. Subba Rao',
      timeText: 'Sun, 29 Jun',
      statusText: 'Vitals updated on 29 Jun',
      noteText: 'Fasting sugar levels are improving. Keep...',
      avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=200',
    ),
    VitalsItem(
      id: '6',
      patientName: 'Mrs. Lakshmi Priya',
      timeText: 'Sat, 28 Jun',
      statusText: 'Vitals updated on 28 Jun',
      noteText: 'Ensure she takes the syrup after food. Watch for...',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
    ),
  ];

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
                child: const TextField(
                  decoration: InputDecoration(
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
                  child: Image.network(
                    item.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person_rounded, color: Color(0xFF94A3B8), size: 30);
                    },
                  ),
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
}
