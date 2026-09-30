import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:howpa_nurse/features/vitals/presentation/screens/update_vitals_screen.dart';
import 'package:howpa_nurse/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:howpa_nurse/features/profile/presentation/screens/profile_screen.dart';
import 'package:howpa_nurse/core/services/user_profile_manager.dart';
import 'package:howpa_nurse/core/services/booking_notification_manager.dart';
import 'package:howpa_nurse/features/visits/data/models/visit_models.dart';
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
  final String phoneNumber;
  final double? latitude;
  final double? longitude;
  final bool femaleNursePreferred;

  NewRequestItem({
    required this.id,
    required this.patientName,
    required this.address,
    required this.distance,
    required this.serviceTag,
    required this.time,
    required this.avatarUrl,
    this.phoneNumber = '+91 98765 43210',
    this.latitude,
    this.longitude,
    this.femaleNursePreferred = false,
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
  final String phoneNumber;
  final double? latitude;
  final double? longitude;
  final bool isVitalsUpdated;
  final String doctorName;

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
    this.phoneNumber = '',
    this.latitude,
    this.longitude,
    this.isVitalsUpdated = false,
    this.doctorName = 'Doctor',
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
    String? phoneNumber,
    double? latitude,
    double? longitude,
    bool? isVitalsUpdated,
    String? doctorName,
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
      phoneNumber: phoneNumber ?? this.phoneNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVitalsUpdated: isVitalsUpdated ?? this.isVitalsUpdated,
      doctorName: doctorName ?? this.doctorName,
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
  Timer? _autoRefreshTimer;
  final Set<String> _knownRequestIds = {};
  bool _isFetchingData = false;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _highlightedPatientName = widget.highlightedPatientName;
    if (_highlightedPatientName != null) {
      _startHighlightFade();
    }

    // 1. Instant Cache Hydration: Render immediately in 0ms!
    _loadFromCache();

    // 2. Non-blocking background network refresh
    _loadVisitsData();

    // 3. Background auto-refresh every 20 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && !_isSearching && _searchQuery.isEmpty) {
        _loadVisitsData(isAutoRefresh: true);
      }
    });
  }

  void _loadFromCache() {
    final nearby = VisitsRepositoryImpl.getCachedNearbyRequests();
    final today = VisitsRepositoryImpl.getCachedTodayVisits();
    final completed = VisitsRepositoryImpl.getCachedCompletedVisits();

    if (nearby.isNotEmpty || today.isNotEmpty || completed.isNotEmpty) {
      _applyData(nearby, today, completed, isInitialCache: true);
    }
  }

  Future<void> _loadVisitsData({bool isAutoRefresh = false}) async {
    if (_isFetchingData) return;
    if (isAutoRefresh && (_isSearching || _searchQuery.isNotEmpty)) return;

    _isFetchingData = true;

    try {
      // Execute API calls concurrently in parallel
      final results = await Future.wait([
        _visitsRepo.getNearbyRequests(),
        _visitsRepo.getTodayVisits(),
        _visitsRepo.getCompletedVisitHistory(),
      ]);

      if (!mounted) return;

      _applyData(results[0], results[1], results[2], isAutoRefresh: isAutoRefresh);
    } catch (_) {
      // Ignore background refresh network glitches gracefully
    } finally {
      _isFetchingData = false;
    }
  }

  void _applyData(
    List<VisitRequestItem> nearby,
    List<VisitRequestItem> today,
    List<VisitRequestItem> completed, {
    bool isAutoRefresh = false,
    bool isInitialCache = false,
  }) {

      // Check for newly arrived booking requests to trigger Pop-Up notification
      NewRequestItem? brandNewRequest;

      final mappedNewRequests = nearby.map((r) {
        final item = NewRequestItem(
          id: r.id,
          patientName: r.patientName,
          address: r.address,
          distance: r.distance,
          serviceTag: r.serviceTag,
          time: r.time,
          avatarUrl: r.avatarUrl,
          phoneNumber: r.phoneNumber,
          latitude: r.latitude,
          longitude: r.longitude,
          femaleNursePreferred: r.femaleNursePreferred,
        );

        if (r.id.isNotEmpty &&
            !BookingNotificationManager.hasBeenShown(r.id) &&
            r.status.toUpperCase() != 'COMPLETED' &&
            r.status.toUpperCase() != 'REJECTED' &&
            r.status.toUpperCase() != 'CANCELLED') {
          brandNewRequest ??= item;
        }
        _knownRequestIds.add(r.id);
        return item;
      }).toList();

      final mappedTodayVisits = today.map((t) {
        final existingIndex = _todayVisits.indexWhere((existing) => existing.id == t.id);
        final existingItem = existingIndex != -1 ? _todayVisits[existingIndex] : null;

        String btnText = 'Started';
        Color accentCol = const Color(0xFF0052FF);
        bool isArrival = false;
        bool vitalsUpdated = t.isVitalsUpdated || t.status == 'VITALS_UPDATED';

        if (existingItem != null) {
          if (existingItem.isVitalsUpdated) vitalsUpdated = true;
          if (existingItem.buttonText == 'Completed' || vitalsUpdated) {
            btnText = 'Completed';
            accentCol = const Color(0xFF10B981);
          } else if (existingItem.buttonText == 'Update Vitals' || t.status == 'ARRIVED') {
            btnText = 'Update Vitals';
            accentCol = const Color(0xFFF59E0B);
          } else if (existingItem.buttonText == 'Arrival' || t.status == 'STARTED' || t.status == 'ARRIVING') {
            btnText = 'Arrival';
            accentCol = const Color(0xFFFF5C00);
            isArrival = true;
          }
        } else {
          if (t.status == 'ARRIVING' || t.status == 'STARTED') {
            btnText = 'Arrival';
            accentCol = const Color(0xFFFF5C00);
            isArrival = true;
          } else if (t.status == 'ARRIVED') {
            btnText = vitalsUpdated ? 'Completed' : 'Update Vitals';
            accentCol = vitalsUpdated ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
          } else if (vitalsUpdated) {
            btnText = 'Completed';
            accentCol = const Color(0xFF10B981);
          }
        }

        return TodayVisitItem(
          id: t.id,
          patientName: t.patientName,
          timeInterval: t.time,
          address: t.address,
          distance: t.distance,
          accentColor: accentCol,
          timeColor: accentCol,
          buttonText: btnText,
          isArrivalButton: isArrival,
          avatarUrl: t.avatarUrl,
          phoneNumber: t.phoneNumber,
          latitude: t.latitude,
          longitude: t.longitude,
          isVitalsUpdated: vitalsUpdated,
          doctorName: t.doctorName,
        );
      }).toList();

      // Only invoke setState if data actually changed or if initial load
      final bool dataChanged = !isAutoRefresh ||
          _newRequests.length != mappedNewRequests.length ||
          _todayVisits.length != mappedTodayVisits.length ||
          _hasDataChanged(mappedNewRequests, mappedTodayVisits);

      if (dataChanged) {
        setState(() {
          // Filter out any requests that are already accepted in today's visits
          final filteredNew = mappedNewRequests.where((r) => !_todayVisits.any((t) => t.id == r.id)).toList();
          _newRequests.clear();
          _newRequests.addAll(filteredNew);

          // Preserve locally accepted items if backend filter=today API hasn't synced them yet
          final mergedTodayMap = <String, TodayVisitItem>{};
          for (final existing in _todayVisits) {
            mergedTodayMap[existing.id] = existing;
          }
          for (final fetched in mappedTodayVisits) {
            mergedTodayMap[fetched.id] = fetched;
          }

          if (!_completedGroups.containsKey('This Week')) {
            _completedGroups['This Week'] = [];
          }

          if (completed.isNotEmpty) {
            final existingCompletedIds = _completedGroups['This Week']!.map((c) => c.id).toSet();
            for (final c in completed) {
              if (!existingCompletedIds.contains(c.id)) {
                _completedGroups['This Week']!.add(CompletedVisitItem(
                  id: c.id,
                  patientName: c.patientName,
                  dateTime: c.time,
                  duration: c.distance,
                  doctorName: c.doctorName.isNotEmpty ? c.doctorName : 'Doctor',
                  address: c.address,
                  avatarUrl: c.avatarUrl,
                ));
              }
            }
          }

          // Separate today visits into active visits vs completed visits
          final activeTodayMap = <String, TodayVisitItem>{};
          for (final item in mergedTodayMap.values) {
            if (item.buttonText == 'Completed' || item.isVitalsUpdated) {
              if (!_completedGroups['This Week']!.any((c) => c.id == item.id)) {
                _completedGroups['This Week']!.insert(0, CompletedVisitItem(
                  id: item.id,
                  patientName: item.patientName,
                  dateTime: item.timeInterval,
                  duration: item.distance,
                  doctorName: item.doctorName.isNotEmpty ? item.doctorName : 'Doctor',
                  address: item.address,
                  avatarUrl: item.avatarUrl,
                ));
              }
            } else {
              activeTodayMap[item.id] = item;
            }
          }

          _todayVisits.clear();
          _todayVisits.addAll(activeTodayMap.values);
        });
      }

      // Trigger alert popup notification for new booking
      if (!isInitialCache && brandNewRequest != null && !BookingNotificationManager.isPopupShowing) {
        _showNewBookingAlertNotification(brandNewRequest!);
      }
  }

  bool _hasDataChanged(List<NewRequestItem> newReqs, List<TodayVisitItem> todayVisits) {
    if (newReqs.length != _newRequests.length || todayVisits.length != _todayVisits.length) {
      return true;
    }
    for (int i = 0; i < newReqs.length; i++) {
      if (newReqs[i].id != _newRequests[i].id) return true;
    }
    for (int i = 0; i < todayVisits.length; i++) {
      if (todayVisits[i].id != _todayVisits[i].id || todayVisits[i].buttonText != _todayVisits[i].buttonText) {
        return true;
      }
    }
    return false;
  }

  void _showNewBookingAlertNotification(NewRequestItem item) {
    if (BookingNotificationManager.isPopupShowing || !mounted) return;

    BookingNotificationManager.showNewBookingDialog(
      context: context,
      item: VisitRequestItem(
        id: item.id,
        patientName: item.patientName,
        address: item.address,
        distance: item.distance,
        serviceTag: item.serviceTag,
        time: item.time,
        avatarUrl: item.avatarUrl,
        phoneNumber: item.phoneNumber,
        latitude: item.latitude,
        longitude: item.longitude,
      ),
      onAccept: () async {
        await _onAcceptRequest(item);
      },
      onReject: () async {
        await _visitsRepo.rejectVisitRequest(item.id);
        if (mounted) {
          setState(() {
            _newRequests.removeWhere((r) => r.id == item.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit request declined'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone dialer: $e')),
        );
      }
    }
  }

  Future<void> _openGoogleMaps(double? lat, double? lng, String address) async {
    Uri mapUri;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    }
    try {
      if (!await launchUrl(mapUri, mode: LaunchMode.externalApplication)) {
        await launchUrl(mapUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Google Maps: $e')),
        );
      }
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
    _autoRefreshTimer?.cancel();
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
    // Instant optimistic UI update (AJAX feel)
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
        phoneNumber: item.phoneNumber,
        latitude: item.latitude,
        longitude: item.longitude,
        isVitalsUpdated: false,
      ));

      // Automatically switch to Today's Visits tab so user sees accepted request immediately!
      _selectedTabIndex = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visit request accepted! Moved to Today\'s schedule.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    // Sync with backend API in background
    _visitsRepo.acceptVisitRequest(item.id);
  }

  Future<void> _onTodayVisitAction(TodayVisitItem item) async {
    final index = _todayVisits.indexWhere((v) => v.id == item.id);
    if (index == -1) return;

    if (item.buttonText == 'Started') {
      // Instant UI update to Arrival
      setState(() {
        _todayVisits[index] = item.copyWith(
          buttonText: 'Arrival',
          isArrivalButton: true,
          accentColor: const Color(0xFFFF5C00),
          timeColor: const Color(0xFFFF5C00),
        );
      });
      _visitsRepo.updateVisitStatus(item.id, 'STARTED');
    } else if (item.buttonText == 'Arrival') {
      // Instant UI update to Update Vitals
      setState(() {
        _todayVisits[index] = item.copyWith(
          buttonText: 'Update Vitals',
          isArrivalButton: false,
          accentColor: const Color(0xFFF59E0B),
          timeColor: const Color(0xFFF59E0B),
        );
      });
      _visitsRepo.updateVisitStatus(item.id, 'ARRIVED');
      _navigateToUpdateVitals(_todayVisits[index]);
    } else if (item.buttonText == 'Update Vitals') {
      _navigateToUpdateVitals(item);
    } else if (item.buttonText == 'Completed') {
      // STRICT VITALS GUARD: Patient vitals must be recorded first!
      if (!item.isVitalsUpdated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please update patient vitals first to complete this visit!'),
              backgroundColor: Color(0xFFEF4444),
              duration: Duration(seconds: 3),
            ),
          );
        }
        _navigateToUpdateVitals(item);
        return;
      }

      // Vitals updated -> Complete Visit and move to Completed tab
      setState(() {
        final completedItem = _todayVisits.removeAt(index);
        
        if (!_completedGroups.containsKey('This Week')) {
          _completedGroups['This Week'] = [];
        }
        
        _completedGroups['This Week']!.insert(0, CompletedVisitItem(
          id: completedItem.id,
          patientName: completedItem.patientName,
          dateTime: 'Today  •  Just now',
          duration: completedItem.distance,
          doctorName: 'Dr. Assigned',
          address: completedItem.address,
          avatarUrl: completedItem.avatarUrl,
        ));
        
        // Auto switch to Completed tab
        _selectedTabIndex = 2;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visit marked as Completed!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      _visitsRepo.updateVisitStatus(item.id, 'COMPLETED');
    }
  }

  Future<void> _navigateToUpdateVitals(TodayVisitItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateVitalsScreen(
          appointmentId: item.id,
          patientName: item.patientName,
          avatarUrl: item.avatarUrl,
        ),
      ),
    );

    if (result == true) {
      final idx = _todayVisits.indexWhere((v) => v.id == item.id);
      final completedItem = idx != -1 ? _todayVisits.removeAt(idx) : item;

      setState(() {
        if (!_completedGroups.containsKey('This Week')) {
          _completedGroups['This Week'] = [];
        }

        _completedGroups['This Week']!.removeWhere((c) => c.id == completedItem.id);
        _completedGroups['This Week']!.insert(0, CompletedVisitItem(
          id: completedItem.id,
          patientName: completedItem.patientName,
          dateTime: 'Today  •  Just now',
          duration: completedItem.distance,
          doctorName: completedItem.doctorName.isNotEmpty ? completedItem.doctorName : 'Doctor',
          address: completedItem.address,
          avatarUrl: completedItem.avatarUrl,
        ));

        // Auto switch to Completed tab
        _selectedTabIndex = 2;
      });

      _visitsRepo.updateVisitStatus(item.id, 'COMPLETED');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vitals recorded and visit marked as Completed!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
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
                            return UserProfileManager.instance.buildAvatarWidget(
                              size: 40,
                              fallbackBgColor: const Color(0xFF0052FF),
                              fallbackIconColor: Colors.white,
                              iconSize: 24,
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
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  addAutomaticKeepAlives: true,
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
                      // Top Row: Avatar + Name, Address, Distance + Call Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
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
                                GestureDetector(
                                  onTap: () => _openGoogleMaps(item.latitude, item.longitude, item.address),
                                  child: Row(
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
                          const SizedBox(width: 8),
                          // Phone Call Circle Button
                          GestureDetector(
                            onTap: () => _makePhoneCall(item.phoneNumber),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4ED),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFFEDD5)),
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                color: Color(0xFFFF8A00),
                                size: 20,
                              ),
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
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
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
                                if (item.femaleNursePreferred)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDF2F8),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFBCFE8), width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.female_rounded,
                                          size: 13,
                                          color: Color(0xFFDB2777),
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'Female Nurse Preferred',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFDB2777),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
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
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  addAutomaticKeepAlives: true,
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
                            onTap: () => _makePhoneCall(item.phoneNumber),
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
                            child: GestureDetector(
                              onTap: () => _openGoogleMaps(item.latitude, item.longitude, item.address),
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
                          ),
                          const SizedBox(width: 8),

                          // Navigate Action Box (Bottom Right)
                          GestureDetector(
                            onTap: () => _openGoogleMaps(item.latitude, item.longitude, item.address),
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

                      // Full Width Action Button (Started -> Arrival -> Update Vitals -> Completed)
                      Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: item.buttonText == 'Completed'
                              ? const Color(0xFF10B981)
                              : (item.buttonText == 'Update Vitals'
                                  ? const Color(0xFFF59E0B)
                                  : (item.isArrivalButton
                                      ? const Color(0xFFFF5C00)
                                      : const Color(0xFF0052FF))),
                          boxShadow: [
                            BoxShadow(
                              color: (item.buttonText == 'Completed'
                                      ? const Color(0xFF10B981)
                                      : (item.buttonText == 'Update Vitals'
                                          ? const Color(0xFFF59E0B)
                                          : (item.isArrivalButton
                                              ? const Color(0xFFFF5C00)
                                              : const Color(0xFF0052FF))))
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
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
                              if (item.buttonText == 'Completed')
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              if (item.buttonText == 'Update Vitals')
                                const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 20),
                              if (item.isArrivalButton)
                                const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
                              if (item.buttonText == 'Started')
                                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
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
