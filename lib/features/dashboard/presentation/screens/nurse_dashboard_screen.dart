import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:howpa_nurse/features/visits/presentation/screens/visits_screen.dart';
import 'package:howpa_nurse/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:howpa_nurse/features/profile/presentation/screens/profile_screen.dart';
import 'package:howpa_nurse/features/payment_earnings/presentation/screens/payment_earnings_screen.dart';
import 'package:howpa_nurse/core/services/user_profile_manager.dart';
import 'package:howpa_nurse/core/services/sound_service.dart';
import '../../data/models/dashboard_data_model.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import 'package:howpa_nurse/features/visits/presentation/cubit/visits_cubit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:howpa_nurse/core/services/location_service.dart';
import 'package:howpa_nurse/features/visits/presentation/cubit/visits_state.dart';
import 'package:howpa_nurse/features/visits/data/models/visit_model.dart';
import 'package:howpa_nurse/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:howpa_nurse/features/profile/presentation/cubit/profile_state.dart';
import 'package:howpa_nurse/core/services/notification_service.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  int _currentBottomNavIndex = 0;

  late AnimationController _radarAnimationController;

  // Sliding Poster Carousel State (Infinite Smooth Auto-Slide)
  late PageController _posterPageController;
  int _currentPosterIndex = 0;
  Timer? _posterAutoSlideTimer;

  final List<String> _dashboardPosters = [
    'assets/images/dashboard poster screen.png',
    'assets/images/dashboard poster 2 screen .png',
    'assets/images/dashboard poster 3 screen.png',
  ];

  StreamSubscription<BroadcastRequestModel>? _appointmentSubscription;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _livePollingTimer;
  bool _isModalShowing = false;
  final Set<String> _dismissedRequestIds = {};

  @override
  void initState() {
    super.initState();
    _radarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Listen for real-time incoming appointment push notifications from backend & FCM
    _appointmentSubscription = NotificationService.instance.onAppointmentReceived.listen((req) {
      if (mounted && _isOnline) {
        _dismissedRequestIds.remove(req.appointmentId); // Ensure new alert is eligible to show
        _showNewVisitRequestModal(req);
      }
    });

    // Start real-time GPS location tracking with 10-meter distance filter
    if (_isOnline) {
      _startLocationTracking();
    }

    // Initialize PageController with high initial page for infinite smooth forward sliding
    const int initialPage = 999;
    _posterPageController = PageController(initialPage: initialPage);
    _currentPosterIndex = initialPage % _dashboardPosters.length;

    // Start 5-second automatic sliding timer
    _startPosterAutoSlideTimer();

    // Start live requests background polling every 8s when nurse is online
    _startLiveRequestsPolling();

    // Initial fetch for dashboard, visits & profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardCubit>().loadDashboard();
        context.read<VisitsCubit>().fetchVisits();
        context.read<ProfileCubit>().fetchProfile();
      }
    });
  }

  void _startLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = LocationService.instance
        .getPositionStream(distanceFilter: 10)
        .listen((pos) {
      if (mounted && _isOnline) {
        context.read<DashboardCubit>().updateLocation(
          latitude: pos.latitude,
          longitude: pos.longitude,
          heading: pos.heading,
          speed: pos.speed,
          accuracy: pos.accuracy,
        );
      }
    }, onError: (err) {
      // Ignored in release mode
    });
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void _startLiveRequestsPolling() {
    _livePollingTimer?.cancel();
    _livePollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && _isOnline) {
        context.read<VisitsCubit>().fetchVisits(silent: true);
        context.read<DashboardCubit>().loadDashboard(silent: true);
      }
    });
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
    _stopLocationTracking();
    _appointmentSubscription?.cancel();
    _livePollingTimer?.cancel();
    SoundService.instance.stopBuzzer();
    _posterAutoSlideTimer?.cancel();
    _posterPageController.dispose();
    _radarAnimationController.dispose();
    super.dispose();
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetCtx) {
        return BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            final list = state is ProfileLoaded ? state.notifications : [];
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${list.length} alerts',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: list.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none_rounded, size: 48, color: Color(0xFFCBD5E1)),
                                SizedBox(height: 10),
                                Text(
                                  'No new notifications',
                                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (context, index) {
                              final notif = list[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEFF6FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.notifications_rounded, color: Color(0xFF0052FF), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notif.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            notif.body,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNewVisitRequestModal([BroadcastRequestModel? request]) {
    if (_isModalShowing) return;

    // Resolve dynamic request from param or live broadcast requests in VisitsCubit
    BroadcastRequestModel? activeRequest = request;
    if (activeRequest == null && context.read<VisitsCubit>().state is VisitsLoaded) {
      final broadcastList = (context.read<VisitsCubit>().state as VisitsLoaded).broadcastRequests;
      for (final candidate in broadcastList) {
        if (!_dismissedRequestIds.contains(candidate.appointmentId)) {
          activeRequest = candidate;
          break;
        }
      }
      if (activeRequest == null && broadcastList.isNotEmpty) {
        activeRequest = broadcastList.first;
      }
    }

    if (activeRequest == null) {
      context.read<VisitsCubit>().fetchVisits();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No new visit requests waiting at the moment.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    _isModalShowing = true;

    // Play incoming appointment buzzer sound in loop
    SoundService.instance.playBuzzer(loop: true);

    final BroadcastRequestModel req = activeRequest;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle pill bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Animated Bell & Soundwaves Top Icon Block
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left Soundwaves
                    Row(
                      children: [
                        _buildSoundwaveBar(10),
                        const SizedBox(width: 3),
                        _buildSoundwaveBar(16),
                        const SizedBox(width: 3),
                        _buildSoundwaveBar(22),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Center Glowing Orange Bell Circle
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFF5EE),
                        border: Border.all(
                          color: const Color(0xFFFF5C00),
                          width: 2.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26FF5C00),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFFFF5C00),
                        size: 26,
                      ),
                    ),

                    const SizedBox(width: 10),
                    // Right Soundwaves
                    Row(
                      children: [
                        _buildSoundwaveBar(22),
                        const SizedBox(width: 3),
                        _buildSoundwaveBar(16),
                        const SizedBox(width: 3),
                        _buildSoundwaveBar(10),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Title & Warning Subtitle
              const Text(
                'New Visit Request',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "You'll receive less requests if you reject too many times.",
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Patient Card Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF1F5F9),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Header Row
                    Row(
                      children: [
                        // Dynamic Patient Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF1F5F9),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          ),
                          child: ClipOval(
                            child: req.avatarUrl.trim().isNotEmpty
                                ? Image.network(
                                    req.avatarUrl.trim(),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      final initial = req.patientName.trim().isNotEmpty
                                          ? req.patientName.trim().substring(0, 1).toUpperCase()
                                          : 'P';
                                      return Container(
                                        color: const Color(0xFFE2E8F0),
                                        child: Center(
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              color: Color(0xFF475569),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: const Color(0xFFE2E8F0),
                                    child: Center(
                                      child: Text(
                                        req.patientName.trim().isNotEmpty
                                            ? req.patientName.trim().substring(0, 1).toUpperCase()
                                            : 'P',
                                        style: const TextStyle(
                                          color: Color(0xFF475569),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.patientName,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${req.patientAge.isNotEmpty ? "${req.patientAge} yrs  •  " : ""}${req.patientGender.isNotEmpty ? req.patientGender : "Patient"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Dynamic Service Type Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3EC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFFD4BE), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.medical_services_outlined,
                                      size: 11,
                                      color: Color(0xFFFF5C00),
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        req.serviceType,
                                        style: const TextStyle(
                                          fontSize: 10.5,
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
                            ],
                          ),
                        ),

                        // Fee Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Text(
                            req.fee,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF5C00),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),

                    // Scheduled Time Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF2563EB),
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scheduled Time',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              req.requestedTime,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),

                    // Distance & Location Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF2563EB),
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Distance & Location',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                req.distance,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF5C00),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                req.address,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Doctor's Note Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.article_outlined,
                              color: Color(0xFF2563EB),
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Doctor's Note",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  req.doctorNote,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF334155),
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Reject & Accept Action Buttons Row
              Row(
                children: [
                  // Reject Button (Red Outline)
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF64748B),
                          width: 1.5,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          _dismissedRequestIds.add(req.appointmentId);
                          _isModalShowing = false;
                          SoundService.instance.stopBuzzer();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening New Requests for ${req.patientName}...'),
                              backgroundColor: const Color(0xFF475569),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VisitsScreen(
                                initialTabIndex: 0, // Tab 0: New Requests Page
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.visibility_outlined,
                              color: Color(0xFF475569),
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Ignore',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Accept Button (Gradient Blue to Orange)
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0052FF),
                            Color(0xFFFF5C00),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x260052FF),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          _dismissedRequestIds.add(req.appointmentId);
                          _isModalShowing = false;
                          SoundService.instance.stopBuzzer();
                          Navigator.pop(context);
                          if (req.appointmentId.isNotEmpty) {
                            context.read<VisitsCubit>().acceptRequest(req.appointmentId);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Visit Request for ${req.patientName} Accepted! Navigating to Visits...'),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VisitsScreen(
                                initialTabIndex: 1,
                                highlightedPatientName: req.patientName,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Accept',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _isModalShowing = false;
      SoundService.instance.stopBuzzer();
    });
  }

  Widget _buildSoundwaveBar(double height) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFF5C00),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DashboardCubit, DashboardState>(
          listener: (context, state) {
            if (state is DashboardLoaded) {
              if (_isOnline != state.data.isOnline) {
                setState(() {
                  _isOnline = state.data.isOnline;
                });
                if (_isOnline) {
                  _startLiveRequestsPolling();
                  _startLocationTracking();
                } else {
                  _livePollingTimer?.cancel();
                  _stopLocationTracking();
                }
              }
            }
          },
        ),
        BlocListener<VisitsCubit, VisitsState>(
          listener: (context, state) {
            if (state is VisitsLoaded && _isOnline && !_isModalShowing) {
              if (state.broadcastRequests.isNotEmpty) {
                for (final candidate in state.broadcastRequests) {
                  if (!_dismissedRequestIds.contains(candidate.appointmentId)) {
                    // Trigger high-importance system push notification
                    NotificationService.instance.showVisitRequestNotification(
                      patientName: candidate.patientName,
                      serviceType: candidate.serviceType,
                      fee: candidate.fee,
                      distance: candidate.distance,
                      appointmentId: candidate.appointmentId,
                    );
                    _showNewVisitRequestModal(candidate);
                    break;
                  }
                }
              }
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
            int todayVisitsCount = 0;
            int completedCount = 0;
            String earningsFormatted = '₹0';
            int waitingRequestsCount = 0;
            List<ScheduleItemModel> todaySchedule = [];

            if (state is DashboardLoaded) {
              todayVisitsCount = state.data.todayVisits;
              completedCount = state.data.completedVisits;
              earningsFormatted = state.data.todayEarnings;
              waitingRequestsCount = state.data.waitingRequests;
              todaySchedule = state.data.todaySchedule;
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (!context.mounted) return;
                await context.read<DashboardCubit>().loadDashboard();
                if (!context.mounted) return;
                await context.read<VisitsCubit>().fetchVisits();
                if (!context.mounted) return;
                await context.read<ProfileCubit>().fetchProfile();
              },
              color: const Color(0xFF0052FF),
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

                        // Notifications Bell Button
                        GestureDetector(
                          onTap: _showNotificationsModal,
                          child: Container(
                            width: 38,
                            height: 38,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x08000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF0F172A),
                              size: 20,
                            ),
                          ),
                        ),

                        // Compact Nurse Avatar - Synchronized with UserProfileManager & Navigates to ProfileScreen
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          },
                          child: Container(
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
                                final mgr = UserProfileManager.instance;
                                final hasLocalPhoto = mgr.hasProfileImage && mgr.profileImageFile != null;
                                final photoUrl = mgr.profileImageUrl?.trim();
                                final hasNetworkPhoto = photoUrl != null && photoUrl.isNotEmpty;
                                final initial = mgr.fullName.trim().isNotEmpty
                                    ? mgr.fullName.trim().substring(0, 1).toUpperCase()
                                    : 'N';

                                if (hasLocalPhoto) {
                                  return ClipOval(
                                    child: Image.file(
                                      mgr.profileImageFile!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  );
                                } else if (hasNetworkPhoto) {
                                  return ClipOval(
                                    child: Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }

                                return Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 2. Compact Online Status Switcher Pill Bar
                    GestureDetector(
                      onTap: () {
                        final nextStatus = !_isOnline;
                        setState(() {
                          _isOnline = nextStatus;
                        });
                        context.read<DashboardCubit>().toggleDutyStatus(nextStatus);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  nextStatus ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  nextStatus
                                      ? "You're now ONLINE. Ready for visit requests!"
                                      : "You're now OFFLINE. Visit requests paused.",
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                            backgroundColor: nextStatus ? const Color(0xFF04A74C) : const Color(0xFF334155),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
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
                                if (waitingRequestsCount > 0 && _isOnline) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _showNewVisitRequestModal(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF1F2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFECDD3), width: 1.0),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFE11D48)),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              '$waitingRequestsCount Request(s) Waiting • Tap to View',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFE11D48),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
                            value: todayVisitsCount.toString(),
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
                            value: completedCount.toString(),
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
                            value: earningsFormatted,
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

                    // 7. Dynamic Schedule Cards or Empty State
                    if (todaySchedule.isEmpty)
                      _buildEmptyScheduleState(_isOnline)
                    else
                      ...todaySchedule.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildScheduleCard(
                          patientName: item.patientName,
                          timeRange: item.timeRange,
                          address: item.address,
                          avatarUrl: item.avatarUrl,
                          serviceType: item.serviceType,
                          status: item.status,
                          phone: item.phone,
                        ),
                      )),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
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
    ),
  );
}

  Widget _buildEmptyScheduleState(bool isOnline) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.event_available_rounded : Icons.event_busy_rounded,
              color: isOnline ? const Color(0xFF0052FF) : const Color(0xFF94A3B8),
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Visits Scheduled for Today',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isOnline
                ? "You're online and active! New patient visit requests will appear here as soon as they are assigned."
                : "You're currently offline. Switch your status to online above to start receiving visit requests.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
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
    String serviceType = 'Home Nursing Care',
    String status = 'Scheduled',
    String phone = '',
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEEF2FF),
                  ),
                  child: ClipOval(
                    child: avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  patientName.isNotEmpty ? patientName.substring(0, 1).toUpperCase() : 'P',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF0052FF),
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              patientName.isNotEmpty ? patientName.substring(0, 1).toUpperCase() : 'P',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF0052FF),
                              ),
                            ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    constraints: const BoxConstraints(minWidth: 58, minHeight: 48),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.near_me_outlined,
                          color: Color(0xFF0052FF),
                          size: 17,
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

            // Address Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1.5),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 18,
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
