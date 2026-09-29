import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:howpa_nurse/features/visits/presentation/screens/visits_screen.dart';
import 'package:howpa_nurse/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:howpa_nurse/features/profile/presentation/screens/profile_screen.dart';
import 'package:howpa_nurse/features/profile/presentation/screens/payment_earnings_screen.dart';
import 'package:howpa_nurse/features/home/data/repositories/dashboard_repository.dart';
import 'package:howpa_nurse/core/services/user_profile_manager.dart';

import 'package:howpa_nurse/features/home/data/models/dashboard_models.dart';
import 'package:howpa_nurse/features/visits/data/models/visit_models.dart';
import 'package:howpa_nurse/features/visits/data/repositories/visits_repository.dart';

import 'package:howpa_nurse/features/profile/data/repositories/profile_repository.dart';
import 'package:howpa_nurse/core/services/booking_notification_manager.dart';

import 'package:howpa_nurse/core/network/token_storage.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> with SingleTickerProviderStateMixin {
  final _dashboardRepo = DashboardRepositoryImpl();
  final _visitsRepo = VisitsRepositoryImpl();
  final _profileRepo = ProfileRepositoryImpl();

  bool _isOnline = true;
  int _currentBottomNavIndex = 0;
  DashboardStats _stats = const DashboardStats();
  List<VisitRequestItem> _todayVisits = [];

  late AnimationController _radarAnimationController;
  Timer? _visitRequestTimer;

  // Sliding Poster Carousel State (Infinite Smooth Auto-Slide)
  late PageController _posterPageController;
  int _currentPosterIndex = 0;
  Timer? _posterAutoSlideTimer;

  final List<String> _dashboardPosters = [
    'assets/images/dashboard poster screen.png',
    'assets/images/dashboard poster 2 screen .png',
    'assets/images/dashboard poster 3 screen.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    _radarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Initialize PageController with high initial page for infinite smooth forward sliding
    const int initialPage = 999;
    _posterPageController = PageController(initialPage: initialPage);
    _currentPosterIndex = initialPage % _dashboardPosters.length;

    // Start 5-second automatic sliding timer
    _startPosterAutoSlideTimer();
  }

  Future<void> _loadDashboardData() async {
    final statsFuture = _dashboardRepo.getDashboard();
    final visitsFuture = _visitsRepo.getTodayVisits();
    final profileFuture = _profileRepo.getProfile();

    final stats = await statsFuture;
    final visits = await visitsFuture;
    await profileFuture;

    if (mounted) {
      setState(() {
        _stats = stats;
        _isOnline = stats.isOnline;
        _todayVisits = visits;
      });
      await TokenStorage.saveOnlineStatus(_isOnline);
      if (_isOnline) {
        _startNearbyRequestsPolling();
      } else {
        _visitRequestTimer?.cancel();
        _visitRequestTimer = null;
      }
    }
  }

  void _startNearbyRequestsPolling() {
    _visitRequestTimer?.cancel();
    _visitRequestTimer = null;
    if (!_isOnline) return;

    _checkForNearbyRequests();

    _visitRequestTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_isOnline) {
        _visitRequestTimer?.cancel();
        _visitRequestTimer = null;
        return;
      }
      _checkForNearbyRequests();
    });
  }

  Future<void> _checkForNearbyRequests() async {
    if (!mounted || !_isOnline) return;
    try {
      final requests = await _visitsRepo.getNearbyRequests();
      if (!mounted || !_isOnline || requests.isEmpty) return;

      final pending = requests.where((r) =>
        r.id.isNotEmpty &&
        !BookingNotificationManager.hasBeenShown(r.id) &&
        r.status.toUpperCase() != 'COMPLETED' &&
        r.status.toUpperCase() != 'REJECTED' &&
        r.status.toUpperCase() != 'CANCELLED'
      ).toList();
      if (pending.isNotEmpty && !BookingNotificationManager.isPopupShowing && _isOnline) {
        final nextReq = pending.first;
        if (mounted && _isOnline) {
          _showNewVisitRequestModal(item: nextReq);
        }
      }
    } catch (_) {}
  }

  void _startPosterAutoSlideTimer() {
    _posterAutoSlideTimer?.cancel();
    _posterAutoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _posterPageController.hasClients) {
        _posterPageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _visitRequestTimer?.cancel();
    _posterAutoSlideTimer?.cancel();
    _posterPageController.dispose();
    _radarAnimationController.dispose();
    super.dispose();
  }

  void _showNewVisitRequestModal({VisitRequestItem? item}) async {
    if (!_isOnline || BookingNotificationManager.isPopupShowing) return;

    VisitRequestItem? targetItem = item;
    if (targetItem == null) {
      final requests = await _visitsRepo.getNearbyRequests();
      if (requests.isNotEmpty) {
        targetItem = requests.first;
      }
    }

    if (targetItem == null || !mounted || !_isOnline) return;

    final reqItem = targetItem;
    BookingNotificationManager.showNewBookingDialog(
      context: context,
      item: reqItem,
      onAccept: () async {
        await _visitsRepo.acceptVisitRequest(reqItem.id);
        await _loadDashboardData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit Request Accepted! Added to today\'s schedule.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      },
      onReject: () async {
        await _visitsRepo.rejectVisitRequest(reqItem.id);
        await _loadDashboardData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit Request Declined'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: const Color(0xFFFF5C00),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Compact Top Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ListenableBuilder(
                      listenable: UserProfileManager.instance,
                      builder: (context, child) {
                        final name = UserProfileManager.instance.fullName;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Hi, $name ',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const Text(
                                  '👋',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Ready to care and make a difference.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Compact Nurse Avatar with Notification Badge Trigger
                  GestureDetector(
                    onTap: _showNewVisitRequestModal,
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
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
                              return UserProfileManager.instance.buildAvatarWidget(
                                size: 40,
                                fallbackBgColor: const Color(0xFF0052FF),
                                fallbackIconColor: Colors.white,
                                iconSize: 22,
                              );
                            },
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF5C00),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 2. Compact Online Status Switcher Pill Bar
              GestureDetector(
                onTap: () {
                  final newStatus = !_isOnline;
                  setState(() {
                    _isOnline = newStatus;
                  });
                  TokenStorage.saveOnlineStatus(newStatus);
                  DashboardRepositoryImpl().toggleDutyStatus(newStatus);
                  if (newStatus) {
                    _startNearbyRequestsPolling();
                  } else {
                    _visitRequestTimer?.cancel();
                    _visitRequestTimer = null;
                    if (BookingNotificationManager.isPopupShowing) {
                      BookingNotificationManager.isPopupShowing = false;
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isOnline ? const Color(0xFF04A74C) : const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _isOnline ? const Color(0x2604A74C) : const Color(0x1A475569),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Concentric Pulse Target Circle Icon
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: Center(
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.8),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isOnline ? "You're Online" : "You're Offline",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _isOnline ? 'Tap to go Offline' : 'Tap to go Online',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Compact Switch Pill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 52,
                        height: 30,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: _isOnline ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isOnline ? const Color(0xFF04A74C) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Compact Radar Card with Trigger Option
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Compact Radar Scanner Graphic
                    SizedBox(
                      width: 65,
                      height: 65,
                      child: AnimatedBuilder(
                        animation: _radarAnimationController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: RadarScannerPainter(
                              angle: _radarAnimationController.value * 2 * math.pi,
                              isActive: _isOnline,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Text Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOnline ? 'Waiting for requests...' : 'Currently Offline',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _isOnline
                                ? "We'll notify you when a new visit request comes in."
                                : "Turn online to start receiving patient visit requests.",
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isOnline ? const Color(0xFF04A74C) : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isOnline ? "You're receiving requests" : "Not receiving requests",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _isOnline ? const Color(0xFF04A74C) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 4. Compact 3 Stat Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.calendar_month_rounded,
                      iconBg: const Color(0xFFEEF2FF),
                      iconColor: const Color(0xFF0052FF),
                      value: '${math.max(_stats.todayVisitsCount, _todayVisits.length)}',
                      valueColor: const Color(0xFF0052FF),
                      label: "Today's Visits",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VisitsScreen(initialTabIndex: 1),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle_outline_rounded,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFF97316),
                      value: '${_stats.completedVisitsCount}',
                      valueColor: const Color(0xFFF97316),
                      label: 'Completed',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VisitsScreen(initialTabIndex: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.currency_rupee_rounded,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      value: '₹${_stats.todayEarnings.toStringAsFixed(0)}',
                      valueColor: const Color(0xFF16A34A),
                      label: 'Earnings Today',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentEarningsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 5. Sliding Dashboard Poster Carousel (3 Posters sliding automatically every 5s)
              Column(
                children: [
                  SizedBox(
                    height: 125,
                    child: PageView.builder(
                      controller: _posterPageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPosterIndex = index % _dashboardPosters.length;
                        });
                      },
                      itemBuilder: (context, index) {
                        final posterImage = _dashboardPosters[index % _dashboardPosters.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              posterImage,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Animated Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _dashboardPosters.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3.0),
                        width: _currentPosterIndex == index ? 22.0 : 7.0,
                        height: 7.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPosterIndex == index
                              ? const Color(0xFFFF5C00)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 6. Compact Today's Schedule Section Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Schedule",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VisitsScreen(initialTabIndex: 1),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF5C00),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 7. Compact Schedule Cards
              if (_todayVisits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No visits scheduled for today.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
                )
              else
                ..._todayVisits.take(3).map(
                      (visit) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildScheduleCard(
                          patientName: visit.patientName,
                          timeRange: visit.time,
                          address: visit.address,
                          avatarUrl: visit.avatarUrl,
                        ),
                      ),
                    ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),

      // Compact Bottom Navigation Bar
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
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VisitsScreen()),
              );
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

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required Color valueColor,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle Icon Box
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 12),
            // Value
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Label + Chevron
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: Color(0xFF334155),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard({
    required String patientName,
    required String timeRange,
    required String address,
    required String avatarUrl,
    VoidCallback? onNavigate,
    VoidCallback? onTapCard,
  }) {
    return GestureDetector(
      onTap: onTapCard ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VisitsScreen(
              initialTabIndex: 1,
              highlightedPatientName: patientName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name/Time + Navigate Box
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF94A3B8),
                        size: 26,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Patient Name & Time Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Color(0xFF0052FF),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            timeRange,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0052FF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Navigate Box Action Card
              GestureDetector(
                onTap: onNavigate ?? () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  constraints: const BoxConstraints(minWidth: 58, minHeight: 52),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
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
                            fontSize: 10,
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

          const SizedBox(height: 10),

          // Address Row - Starts from below the Avatar (far left of card)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1.5),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 28,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}

// Custom Painter for Radar Scanning Animation
class RadarScannerPainter extends CustomPainter {
  final double angle;
  final bool isActive;

  RadarScannerPainter({
    required this.angle,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Concentric rings
    final ringPaint = Paint()
      ..color = isActive ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius * 0.7, ringPaint);
    canvas.drawCircle(center, radius * 0.4, ringPaint);

    if (isActive) {
      // Rotating Sweep Sector Gradient
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: math.pi * 0.5,
          colors: [
            const Color(0xFF04A74C).withValues(alpha: 0.0),
            const Color(0xFF04A74C).withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawCircle(center, radius, sweepPaint);

      // Radar line
      final linePaint = Paint()
        ..color = const Color(0xFF04A74C)
        ..strokeWidth = 1.6;
      canvas.drawLine(center, Offset(center.dx + radius * math.cos(0), center.dy + radius * math.sin(0)), linePaint);
      canvas.restore();

      // Blip Dots
      final dotPaint = Paint()..color = const Color(0xFF04A74C);
      canvas.drawCircle(Offset(center.dx - 12, center.dy - 8), 2.5, dotPaint);
      canvas.drawCircle(Offset(center.dx + 16, center.dy + 12), 3.0, dotPaint);
      canvas.drawCircle(Offset(center.dx + 8, center.dy - 16), 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RadarScannerPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.isActive != isActive;
  }
}
