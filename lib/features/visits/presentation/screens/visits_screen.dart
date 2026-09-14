import 'dart:async';
import 'package:flutter/material.dart';
import 'package:howpa_nurse/features/vitals/presentation/screens/update_vitals_screen.dart';
import 'package:howpa_nurse/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:howpa_nurse/features/profile/presentation/screens/profile_screen.dart';
import 'package:howpa_nurse/core/services/user_profile_manager.dart';
import 'package:howpa_nurse/features/visits/data/repositories/visits_repository.dart';

// Data models for each tab
class NewRequestItem {
  final String id;
  final String patientName;
  final String address;
  final String distance;
  final String serviceTag;
  final String time;
  final String avatarUrl;

  NewRequestItem({
    required this.id,
    required this.patientName,
    required this.address,
    required this.distance,
    required this.serviceTag,
    required this.time,
    required this.avatarUrl,
  });
}

class TodayVisitItem {
  final String id;
  final String patientName;
  final String timeInterval;
  final String address;
  final String distance;
  final Color accentColor;
  final Color timeColor;
  final String buttonText;
  final bool isArrivalButton;
  final bool hasConfirmedTag;
  final String avatarUrl;

  TodayVisitItem({
    required this.id,
    required this.patientName,
    required this.timeInterval,
    required this.address,
    required this.distance,
    required this.accentColor,
    required this.timeColor,
    required this.buttonText,
    this.isArrivalButton = false,
    this.hasConfirmedTag = false,
    required this.avatarUrl,
  });

  TodayVisitItem copyWith({
    String? id,
    String? patientName,
    String? timeInterval,
    String? address,
    String? distance,
    Color? accentColor,
    Color? timeColor,
    String? buttonText,
    bool? isArrivalButton,
    bool? hasConfirmedTag,
    String? avatarUrl,
  }) {
    return TodayVisitItem(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      timeInterval: timeInterval ?? this.timeInterval,
      address: address ?? this.address,
      distance: distance ?? this.distance,
      accentColor: accentColor ?? this.accentColor,
      timeColor: timeColor ?? this.timeColor,
      buttonText: buttonText ?? this.buttonText,
      isArrivalButton: isArrivalButton ?? this.isArrivalButton,
      hasConfirmedTag: hasConfirmedTag ?? this.hasConfirmedTag,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class CompletedVisitItem {
  final String id;
  final String patientName;
  final String dateTime;
  final String duration;
  final String doctorName;
  final String address;
  final String avatarUrl;

  CompletedVisitItem({
    required this.id,
    required this.patientName,
    required this.dateTime,
    required this.duration,
    required this.doctorName,
    required this.address,
    required this.avatarUrl,
  });
}

class VisitsScreen extends StatefulWidget {
  final int initialTabIndex; // 0: New Requests, 1: Today, 2: Completed
  final String? highlightedPatientName; // Name of person clicked on home screen

  const VisitsScreen({
    super.key,
    this.initialTabIndex = 0,
    this.highlightedPatientName,
  });

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final _visitsRepo = VisitsRepositoryImpl();
  late int _selectedTabIndex; // 0: New Requests, 1: Today, 2: Completed
  int _currentBottomNavIndex = 1; // Visits selected
  String _searchQuery = '';
  bool _isSearching = false;
  String? _highlightedPatientName;
  bool _isHighlightVisible = false;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _highlightedPatientName = widget.highlightedPatientName;
    if (_highlightedPatientName != null) {
      _startHighlightFade();
    }
    _loadVisitsData();
  }

  Future<void> _loadVisitsData() async {
    final nearby = await _visitsRepo.getNearbyRequests();
    final today = await _visitsRepo.getTodayVisits();
    final completed = await _visitsRepo.getCompletedVisitHistory();

    if (mounted) {
      setState(() {
        _newRequests.clear();
        _newRequests.addAll(nearby.map((r) => NewRequestItem(
          id: r.id,
          patientName: r.patientName,
          address: r.address,
          distance: r.distance,
          serviceTag: r.serviceTag,
          time: r.time,
          avatarUrl: r.avatarUrl,
        )));

        _todayVisits.clear();
        _todayVisits.addAll(today.map((t) => TodayVisitItem(
          id: t.id,
          patientName: t.patientName,
          timeInterval: t.time,
          address: t.address,
          distance: t.distance,
          accentColor: t.status == 'ARRIVING' ? const Color(0xFFFF5C00) : const Color(0xFF0052FF),
          timeColor: t.status == 'ARRIVING' ? const Color(0xFFFF5C00) : const Color(0xFF0052FF),
          buttonText: t.status == 'ARRIVING' ? 'Arrival' : 'Started',
          isArrivalButton: t.status == 'ARRIVING',
          avatarUrl: t.avatarUrl,
        )));

        if (completed.isNotEmpty) {
          _completedGroups['This Week'] = completed.map((c) => CompletedVisitItem(
            id: c.id,
            patientName: c.patientName,
            dateTime: c.time,
            duration: c.distance,
            doctorName: 'Dr. Assigned',
            address: c.address,
            avatarUrl: c.avatarUrl,
          )).toList();
        }
      });
    }
  }

  void _startHighlightFade() {
    _isHighlightVisible = true;
    _blinkTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isHighlightVisible = false;
          _highlightedPatientName = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  void _onRejectRequest(NewRequestItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to reject this visit request?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _visitsRepo.rejectVisitRequest(item.id);
              setState(() {
                _newRequests.removeWhere((r) => r.id == item.id);
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Visit request rejected')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
            child: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _onAcceptRequest(NewRequestItem item) async {
    final success = await _visitsRepo.acceptVisitRequest(item.id);
    if (!mounted) return;

    if (success) {
      setState(() {
        _newRequests.removeWhere((r) => r.id == item.id);
        
        _todayVisits.add(TodayVisitItem(
          id: item.id,
          patientName: item.patientName,
          timeInterval: item.time.replaceAll(RegExp(r'Today,\s*'), ''),
          address: item.address,
          distance: item.distance,
          accentColor: const Color(0xFF0052FF),
          timeColor: const Color(0xFF0052FF),
          buttonText: 'Started',
          avatarUrl: item.avatarUrl,
        ));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit request accepted!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept visit request. Please try again.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _onTodayVisitAction(TodayVisitItem item) async {
    final index = _todayVisits.indexWhere((v) => v.id == item.id);
    if (index == -1) return;

    if (item.buttonText == 'Started') {
      final success = await _visitsRepo.updateVisitStatus(item.id, 'STARTED');
      if (!mounted) return;
      if (success) {
        setState(() {
          _todayVisits[index] = item.copyWith(
            buttonText: 'Arrival',
            isArrivalButton: true,
            accentColor: const Color(0xFFFF5C00),
            timeColor: const Color(0xFFFF5C00),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start visit. Please check network connection.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } else if (item.buttonText == 'Arrival') {
      final success = await _visitsRepo.updateVisitStatus(item.id, 'ARRIVED');
      if (!mounted) return;
      if (success) {
        setState(() {
          _todayVisits[index] = item.copyWith(
            buttonText: 'Update Vitals',
            isArrivalButton: false,
            accentColor: const Color(0xFF10B981),
            timeColor: const Color(0xFF10B981),
          );
        });
        _navigateToUpdateVitals(_todayVisits[index]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark arrival. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } else if (item.buttonText == 'Update Vitals') {
      _navigateToUpdateVitals(item);
    } else if (item.buttonText == 'Completed') {
      final success = await _visitsRepo.updateVisitStatus(item.id, 'COMPLETED');
      if (!mounted) return;
      if (success) {
        setState(() {
          final completedItem = _todayVisits.removeAt(index);
          
          if (!_completedGroups.containsKey('This Week')) {
            _completedGroups['This Week'] = [];
          }
          
          _completedGroups['This Week']!.insert(0, CompletedVisitItem(
            id: completedItem.id,
            patientName: completedItem.patientName,
            dateTime: 'Today  •  Just now',
            duration: '30 mins',
            doctorName: 'Dr. Assigned',
            address: completedItem.address,
            avatarUrl: completedItem.avatarUrl,
          ));
          
          _selectedTabIndex = 2;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete visit. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _navigateToUpdateVitals(TodayVisitItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateVitalsScreen(
          patientName: item.patientName,
          avatarUrl: item.avatarUrl,
        ),
      ),
    );

    if (result == true) {
      final idx = _todayVisits.indexWhere((v) => v.id == item.id);
      if (idx != -1) {
        setState(() {
          _todayVisits[idx] = _todayVisits[idx].copyWith(
            buttonText: 'Completed',
            accentColor: const Color(0xFF0F766E),
            timeColor: const Color(0xFF0F766E),
          );
        });
      }
    }
  }

  // Tab 0 Data: New Requests
  final List<NewRequestItem> _newRequests = [];

  // Tab 1 Data: Today Visits
  final List<TodayVisitItem> _todayVisits = [];

  // Tab 2 Data: Completed Visits (Grouped by This Week, Last Week, Earlier)
  final Map<String, List<CompletedVisitItem>> _completedGroups = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Visits',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchQuery = '';
                            }
                          });
                        },
                        icon: Icon(
                          _isSearching ? Icons.close_rounded : Icons.search_rounded,
                          color: const Color(0xFF0F172A),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Nurse Profile Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0052FF),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A0052FF),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListenableBuilder(
                          listenable: UserProfileManager.instance,
                          builder: (context, child) {
                            final hasPhoto = UserProfileManager.instance.hasProfileImage;
                            final photoFile = UserProfileManager.instance.profileImageFile;
                            if (hasPhoto && photoFile != null) {
                              return ClipOval(
                                child: Image.file(
                                  photoFile,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              );
                            }
                            return ClipOval(
                              child: Image.network(
                                'https://images.unsplash.com/photo-1594824813571-215f396469a0?auto=format&fit=crop&q=80&w=200',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Filter Tabs Bar (New Requests, Today, Completed)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterTab(
                    index: 0,
                    label: 'New Requests',
                    badge: '${_newRequests.length}',
                    badgeBg: const Color(0xFFFF5C00),
                    badgeIcon: null,
                  ),
                  const SizedBox(width: 16),
                  _buildFilterTab(
                    index: 1,
                    label: 'Today',
                    badge: '${_todayVisits.length}',
                    badgeBg: const Color(0xFF0052FF),
                    badgeIcon: null,
                  ),
                  const SizedBox(width: 16),
                  _buildFilterTab(
                    index: 2,
                    label: 'Completed',
                    badge: '${_completedGroups.values.fold(0, (sum, list) => sum + list.length)}',
                    badgeBg: const Color(0xFF10B981),
                    badgeIcon: null,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Single Unified Search Bar for All Tabs
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    autofocus: true,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by patient name or address...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Pull Down to Refresh Row
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Main Tab Content View Switcher
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadVisitsData,
                color: const Color(0xFFFF5C00),
                child: _buildTabBodyContent(),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFF1F5F9),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentBottomNavIndex,
          onTap: (index) {
            if (index == 0) {
              Navigator.popUntil(context, (route) => route.isFirst);
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VitalsScreen()),
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
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF0052FF),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 22),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded, size: 22),
              label: 'Visits',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart_outlined, size: 22),
              label: 'Vitals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 22),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required int index,
    required String label,
    required String badge,
    required Color badgeBg,
    required IconData? badgeIcon,
  }) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? const Color(0xFFFF5C00) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 6),

                // Circle Badge Pill
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: badgeIcon != null
                      ? Icon(badgeIcon, color: Colors.white, size: 12)
                      : Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
          // Active tab underline indicator bar
          Container(
            height: 3,
            width: isSelected ? 90 : 0,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF5C00) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBodyContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildNewRequestsView();
      case 1:
        return _buildTodayVisitsView();
      case 2:
        return _buildCompletedVisitsView();
      default:
        return _buildNewRequestsView();
    }
  }

  // TAB 0: New Requests View
  Widget _buildNewRequestsView() {
    final filtered = _newRequests.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.patientName.toLowerCase().contains(q) ||
             item.address.toLowerCase().contains(q) ||
             item.serviceTag.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Requests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${filtered.length} New',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF5C00),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No matching requests found',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildNewRequestCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNewRequestCard(NewRequestItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Orange vertical accent bar on left
              Container(width: 4, color: const Color(0xFFFF5C00)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar + Name, Address, Distance
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF1F5F9),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                item.avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF64748B),
                                    size: 28,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.patientName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: Color(0xFF0052FF),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.address,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.near_me_rounded,
                                      size: 13,
                                      color: Color(0xFF0052FF),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.distance,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0052FF),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Middle Info Row: Service Tag (Left) + Date/Time (Right)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Service Tag Pill
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3EC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFD4BE), width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.link_rounded,
                                    size: 13,
                                    color: Color(0xFFFF5C00),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.serviceTag,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF5C00),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Date/Time
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    item.time,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Action Buttons Row: Reject & Accept
                      Row(
                        children: [
                          // Reject Button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _onRejectRequest(item),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFF3B30), width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Reject',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF3B30),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Accept Button (Gradient)
                          Expanded(
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0052FF), Color(0xFFFF5C00)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x330052FF),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => _onAcceptRequest(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Accept',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 1: Today Visits View
  Widget _buildTodayVisitsView() {
    final filtered = _todayVisits.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.patientName.toLowerCase().contains(q) ||
             item.address.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today’s Visits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${filtered.length} Visits',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0052FF),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No matching visits found',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildTodayVisitCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTodayVisitCard(TodayVisitItem item) {
    final bool isHighlighted = _isHighlightVisible && _highlightedPatientName != null &&
        item.patientName.toLowerCase().contains(_highlightedPatientName!.toLowerCase());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFFFF7ED) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFFF5C00) : const Color(0xFFF1F5F9),
          width: isHighlighted ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isHighlighted)
            BoxShadow(
              color: const Color(0xFFFF5C00).withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          else
            const BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                width: 4,
                color: isHighlighted ? const Color(0xFFFF5C00) : item.accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Top Row: Avatar + Name & Time + Call Button (Top Right)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF1F5F9),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                item.avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF64748B),
                                    size: 28,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.patientName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.timeInterval,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: item.timeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Call Circle Button (Top Right)
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4ED),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFFEDD5)),
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                color: Color(0xFFFF8A00),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Bottom Row: Address & Distance + Navigate Box (Bottom Right)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Address & Distance Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        size: 16,
                                        color: Color(0xFF0052FF),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.address,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF475569),
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.near_me_rounded,
                                      size: 14,
                                      color: Color(0xFF0052FF),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.distance,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0052FF),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Navigate Action Box (Bottom Right)
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              constraints: const BoxConstraints(minWidth: 66, minHeight: 58),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFDBEAFE)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.near_me_outlined,
                                    color: Color(0xFF0052FF),
                                    size: 18,
                                  ),
                                  SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Navigate',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0052FF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Full Width Action Button (Arrival or Started)
                      Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: item.buttonText == 'Completed' 
                              ? const Color(0xFF10B981) 
                              : (item.isArrivalButton ? const Color(0xFFFF5C00) : const Color(0xFF0052FF)),
                        ),
                        child: ElevatedButton(
                          onPressed: () => _onTodayVisitAction(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (item.isArrivalButton) const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
                              if (item.isArrivalButton) const SizedBox(width: 8),
                              Text(
                                item.buttonText,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 2: Completed Visits View (Grouped with Search Filter)
  Widget _buildCompletedVisitsView() {
    final hasMatches = _completedGroups.values.any((list) => list.any((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.patientName.toLowerCase().contains(q) ||
             item.doctorName.toLowerCase().contains(q);
    }));

    if (!hasMatches) {
      return const Center(
        child: Text(
          'No matching completed visits found',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: _completedGroups.entries.map((group) {
        final filteredItems = group.value.where((item) {
          if (_searchQuery.trim().isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return item.patientName.toLowerCase().contains(q) ||
                 item.doctorName.toLowerCase().contains(q);
        }).toList();

        if (filteredItems.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                group.key,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            ...filteredItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: _buildCompletedVisitCard(item),
                )),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCompletedVisitCard(CompletedVisitItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Emerald vertical bar on left
              Container(width: 4, color: const Color(0xFF10B981)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar + Name & DateTime
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF1F5F9),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                item.avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF64748B),
                                    size: 28,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.patientName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.dateTime,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Bottom Row: Doctor Name & Address
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.medical_services_outlined,
                                size: 14,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Doctor: ${item.doctorName}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
