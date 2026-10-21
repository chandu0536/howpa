import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:howpa_nurse/features/vitals/presentation/screens/update_vitals_screen.dart';
import 'package:howpa_nurse/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:howpa_nurse/features/profile/presentation/screens/profile_screen.dart';
import 'package:howpa_nurse/core/services/user_profile_manager.dart';
import 'package:howpa_nurse/core/services/booking_notification_manager.dart';
import 'package:howpa_nurse/features/visits/data/models/visit_models.dart';
import 'package:howpa_nurse/features/visits/data/repositories/visits_repository.dart';
import 'package:howpa_nurse/features/vitals/presentation/widgets/view_vitals_bottom_sheet.dart';
import 'package:howpa_nurse/features/vitals/data/models/vitals_details_model.dart';
import 'package:howpa_nurse/core/network/api_exceptions.dart';

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
  final bool isFamilyMember;
  final String? patientAge;
  final String? patientGender;
  final String? relation;
  final String? bookedByName;
  final String? appointmentId;
  final String? requestId;
  final String? orderId;
  final DateTime? scheduledDate;

  NewRequestItem({
    required this.id,
    this.orderId,
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
    this.isFamilyMember = false,
    this.patientAge,
    this.patientGender,
    this.relation,
    this.bookedByName,
    this.appointmentId,
    this.requestId,
    this.scheduledDate,
  });

  String get formattedAppointmentDate {
    final d = scheduledDate ?? DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = days[d.weekday - 1];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dayName, $dd-$mm-$yyyy';
  }

  String get displayOrderId {
    if (orderId != null && orderId!.trim().isNotEmpty && orderId != 'null') {
      return orderId!.trim();
    }
    if (appointmentId != null && appointmentId!.trim().isNotEmpty && appointmentId != 'null' && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(appointmentId!.trim())) {
      return appointmentId!.trim();
    }
    if (requestId != null && requestId!.trim().isNotEmpty && requestId != 'null' && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(requestId!.trim())) {
      return requestId!.trim();
    }
    if (id.isNotEmpty && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      return id;
    }
    return '';
  }
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
  final bool isFamilyMember;
  final String? patientAge;
  final String? patientGender;
  final String? relation;
  final String? bookedByName;
  final String? appointmentId;
  final String? requestId;
  final String? orderId;
  final DateTime? scheduledDate;

  TodayVisitItem({
    required this.id,
    this.orderId,
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
    this.isFamilyMember = false,
    this.patientAge,
    this.patientGender,
    this.relation,
    this.bookedByName,
    this.appointmentId,
    this.requestId,
    this.scheduledDate,
  });

  String get formattedAppointmentDate {
    final d = scheduledDate ?? DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = days[d.weekday - 1];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dayName, $dd-$mm-$yyyy';
  }

  String get displayOrderId {
    if (orderId != null && orderId!.trim().isNotEmpty && orderId != 'null') {
      return orderId!.trim();
    }
    if (appointmentId != null && appointmentId!.trim().isNotEmpty && appointmentId != 'null' && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(appointmentId!.trim())) {
      return appointmentId!.trim();
    }
    if (requestId != null && requestId!.trim().isNotEmpty && requestId != 'null' && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(requestId!.trim())) {
      return requestId!.trim();
    }
    if (id.isNotEmpty && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      return id;
    }
    return '';
  }

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
    bool? isFamilyMember,
    String? patientAge,
    String? patientGender,
    String? relation,
    String? bookedByName,
    String? appointmentId,
    String? requestId,
    String? orderId,
    DateTime? scheduledDate,
  }) {
    return TodayVisitItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
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
      isFamilyMember: isFamilyMember ?? this.isFamilyMember,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      relation: relation ?? this.relation,
      bookedByName: bookedByName ?? this.bookedByName,
      appointmentId: appointmentId ?? this.appointmentId,
      requestId: requestId ?? this.requestId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
    );
  }
}

class CompletedVisitItem {
  final String id;
  final String? orderId;
  final String? appointmentId;
  final String? requestId;
  final String patientName;
  final String dateTime;
  final String duration;
  final String doctorName;
  final String address;
  final String avatarUrl;
  final PatientVitalsSummary? vitalsSummary;
  final DateTime? scheduledDate;
  final bool isFamilyMember;
  final String? patientAge;
  final String? patientGender;
  final String? relation;
  final String? bookedByName;

  CompletedVisitItem({
    required this.id,
    this.orderId,
    this.appointmentId,
    this.requestId,
    required this.patientName,
    required this.dateTime,
    required this.duration,
    required this.doctorName,
    required this.address,
    required this.avatarUrl,
    this.vitalsSummary,
    this.scheduledDate,
    this.isFamilyMember = false,
    this.patientAge,
    this.patientGender,
    this.relation,
    this.bookedByName,
  });

  String get formattedAppointmentDate {
    final d = scheduledDate ?? DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = days[d.weekday - 1];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dayName, $dd-$mm-$yyyy';
  }

  String get displayOrderId {
    if (orderId != null && orderId!.trim().isNotEmpty && orderId != 'null') {
      return orderId!.trim();
    }
    if (id.isNotEmpty && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      return id;
    }
    return '';
  }
}

class VisitsScreen extends StatefulWidget {
  final int initialTabIndex; // 0: New Requests, 1: Today, 2: Completed
  final String? highlightedVisitId; // ID of visit clicked on home screen
  final String? highlightedPatientName; // Name of person clicked on home screen

  const VisitsScreen({
    super.key,
    this.initialTabIndex = 0,
    this.highlightedVisitId,
    this.highlightedPatientName,
  });

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  static String _cleanDisplayTime(String rawTime) {
    if (rawTime.trim().isEmpty) return '';
    var s = rawTime.trim();
    final timeMatch = RegExp(r'(\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)(?:\s*-\s*\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm))?)').firstMatch(s);
    if (timeMatch != null) {
      return timeMatch.group(1)!.trim();
    }
    s = s
        .replaceAll(RegExp(r'^(Today|Scheduled)\s*[•,\-]?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*[•,\-]?\s*(Today|Scheduled)$', caseSensitive: false), '')
        .trim();
    if (s.toLowerCase() == 'today' || s.toLowerCase() == 'scheduled') return '';
    return s;
  }
  final _visitsRepo = VisitsRepositoryImpl();
  late int _selectedTabIndex; // 0: New Requests, 1: Today, 2: Completed
  late final PageController _pageController;
  int _currentBottomNavIndex = 1; // Visits selected
  String _searchQuery = '';
  bool _isSearching = false;
  String? _highlightedVisitId;
  String? _highlightedPatientName;
  bool _isHighlightVisible = false;
  final GlobalKey _targetCardKey = GlobalKey();
  bool _hasScrolledToTarget = false;
  Timer? _blinkTimer;
  Timer? _autoRefreshTimer;
  final Set<String> _knownRequestIds = {};
  bool _isFetchingData = false;

  bool _isSameVisit({
    required String id1,
    String? apt1,
    String? req1,
    String? ord1,
    String? name1,
    DateTime? date1,
    required String id2,
    String? apt2,
    String? req2,
    String? ord2,
    String? name2,
    DateTime? date2,
  }) {
    if (id1.isNotEmpty && id1 == id2) return true;
    if (apt1 != null && apt1.isNotEmpty) {
      if (apt1 == apt2 || apt1 == id2 || apt1 == req2) return true;
    }
    if (apt2 != null && apt2.isNotEmpty) {
      if (apt2 == id1 || apt2 == req1) return true;
    }
    if (req1 != null && req1.isNotEmpty) {
      if (req1 == req2 || req1 == id2 || req1 == apt2) return true;
    }
    if (req2 != null && req2.isNotEmpty) {
      if (req2 == id1 || req2 == apt1) return true;
    }
    if (ord1 != null && ord1.isNotEmpty && ord2 != null && ord2.isNotEmpty) {
      if (ord1 == ord2) return true;
    }
    if (name1 != null &&
        name2 != null &&
        name1.isNotEmpty &&
        name2.isNotEmpty &&
        name1.toLowerCase() != 'patient' &&
        name1.trim().toLowerCase() == name2.trim().toLowerCase()) {
      if (date1 != null && date2 != null) {
        if (date1.year == date2.year && date1.month == date2.month && date1.day == date2.day) {
          return true;
        }
      }
    }
    return false;
  }

  void _mergeOrAddCompleted(List<CompletedVisitItem> list, CompletedVisitItem newItem) {
    final idx = list.indexWhere((existing) => _isSameVisit(
      id1: existing.id,
      apt1: existing.appointmentId,
      req1: existing.requestId,
      ord1: existing.orderId,
      name1: existing.patientName,
      date1: existing.scheduledDate,
      id2: newItem.id,
      apt2: newItem.appointmentId,
      req2: newItem.requestId,
      ord2: newItem.orderId,
      name2: newItem.patientName,
      date2: newItem.scheduledDate,
    ));

    if (idx != -1) {
      final existing = list[idx];
      // Prefer Nurse order ID (e.g. starts with 'NS')
      final bestOrderId = (newItem.orderId != null && newItem.orderId!.startsWith('NS'))
          ? newItem.orderId
          : (existing.orderId != null && existing.orderId!.startsWith('NS')
              ? existing.orderId
              : (newItem.orderId?.isNotEmpty == true ? newItem.orderId : existing.orderId));

      list[idx] = CompletedVisitItem(
        id: existing.id,
        orderId: bestOrderId,
        appointmentId: existing.appointmentId ?? newItem.appointmentId,
        requestId: existing.requestId ?? newItem.requestId,
        patientName: existing.patientName.isNotEmpty && existing.patientName != 'Patient'
            ? existing.patientName
            : newItem.patientName,
        dateTime: existing.dateTime.isNotEmpty ? existing.dateTime : newItem.dateTime,
        duration: existing.duration.isNotEmpty ? existing.duration : newItem.duration,
        doctorName: existing.doctorName.isNotEmpty && existing.doctorName != 'Doctor'
            ? existing.doctorName
            : newItem.doctorName,
        address: existing.address.isNotEmpty && existing.address != 'Patient Address'
            ? existing.address
            : newItem.address,
        avatarUrl: existing.avatarUrl.isNotEmpty ? existing.avatarUrl : newItem.avatarUrl,
        scheduledDate: existing.scheduledDate ?? newItem.scheduledDate,
        vitalsSummary: existing.vitalsSummary ?? newItem.vitalsSummary,
        isFamilyMember: existing.isFamilyMember || newItem.isFamilyMember,
        patientAge: (existing.patientAge != null && existing.patientAge!.isNotEmpty)
            ? existing.patientAge
            : newItem.patientAge,
        patientGender: (existing.patientGender != null && existing.patientGender!.isNotEmpty)
            ? existing.patientGender
            : newItem.patientGender,
        relation: existing.relation ?? newItem.relation,
        bookedByName: existing.bookedByName ?? newItem.bookedByName,
      );
    } else {
      list.add(newItem);
    }
  }

  void _switchTab(int index) {
    if (_selectedTabIndex != index) {
      setState(() {
        _selectedTabIndex = index;
      });
    }
    if (_pageController.hasClients && _pageController.page?.round() != index) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToTargetIfAvailable() {
    if (_hasScrolledToTarget) return;
    if ((_highlightedVisitId == null || _highlightedVisitId!.isEmpty) &&
        (_highlightedPatientName == null || _highlightedPatientName!.isEmpty)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted && !_hasScrolledToTarget && _targetCardKey.currentContext != null) {
          _hasScrolledToTarget = true;
          Scrollable.ensureVisible(
            _targetCardKey.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            alignment: 0.15,
          );
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _pageController = PageController(initialPage: _selectedTabIndex);
    _highlightedVisitId = widget.highlightedVisitId;
    _highlightedPatientName = widget.highlightedPatientName;
    if (_highlightedVisitId != null || _highlightedPatientName != null) {
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
      _scrollToTargetIfAvailable();
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
          orderId: r.displayOrderId,
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
          isFamilyMember: r.isFamilyMember,
          patientAge: r.patientAge,
          patientGender: r.patientGender,
          relation: r.relation,
          bookedByName: r.bookedByName,
          appointmentId: r.appointmentId,
          requestId: r.requestId,
          scheduledDate: r.scheduledDate,
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
        final existingIndex = _todayVisits.indexWhere((existing) =>
            existing.id == t.id ||
            (t.appointmentId != null && t.appointmentId!.isNotEmpty && existing.id == t.appointmentId) ||
            (t.requestId != null && t.requestId!.isNotEmpty && existing.id == t.requestId) ||
            (existing.appointmentId != null && existing.appointmentId!.isNotEmpty && existing.appointmentId == t.appointmentId) ||
            (existing.requestId != null && existing.requestId!.isNotEmpty && existing.requestId == t.requestId));
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
          orderId: t.displayOrderId.isNotEmpty ? t.displayOrderId : (existingItem?.orderId ?? ''),
          patientName: t.patientName,
          timeInterval: t.time,
          address: t.address,
          distance: t.distance,
          accentColor: accentCol,
          timeColor: accentCol,
          buttonText: btnText,
          isArrivalButton: isArrival,
          avatarUrl: t.avatarUrl.isNotEmpty ? t.avatarUrl : (existingItem?.avatarUrl ?? ''),
          phoneNumber: t.phoneNumber.isNotEmpty ? t.phoneNumber : (existingItem?.phoneNumber ?? ''),
          latitude: t.latitude ?? existingItem?.latitude,
          longitude: t.longitude ?? existingItem?.longitude,
          isVitalsUpdated: vitalsUpdated,
          doctorName: t.doctorName.isNotEmpty ? t.doctorName : (existingItem?.doctorName ?? 'Doctor'),
          isFamilyMember: t.isFamilyMember || (existingItem?.isFamilyMember ?? false),
          patientAge: t.patientAge ?? existingItem?.patientAge,
          patientGender: t.patientGender ?? existingItem?.patientGender,
          relation: t.relation ?? existingItem?.relation,
          bookedByName: t.bookedByName ?? existingItem?.bookedByName,
          appointmentId: t.appointmentId ?? existingItem?.appointmentId,
          requestId: t.requestId ?? existingItem?.requestId,
          scheduledDate: t.scheduledDate ?? existingItem?.scheduledDate,
        );
      }).toList();

      // Only invoke setState if data actually changed or if initial load
      final currentCompletedCount = _completedGroups.values.fold<int>(0, (sum, list) => sum + list.length);
      final bool dataChanged = !isAutoRefresh ||
          _newRequests.length != mappedNewRequests.length ||
          _todayVisits.length != mappedTodayVisits.length ||
          currentCompletedCount != completed.length ||
          _hasDataChanged(mappedNewRequests, mappedTodayVisits);

      if (dataChanged) {
        setState(() {
          // 1. Process Completed Visits with full deduplication (ONLY 1 card per visit)
          if (!_completedGroups.containsKey('This Week')) {
            _completedGroups['This Week'] = [];
          }

          final List<CompletedVisitItem> deduplicatedCompleted = [];
          
          // Merge existing items from _completedGroups
          for (final list in _completedGroups.values) {
            for (final item in list) {
              _mergeOrAddCompleted(deduplicatedCompleted, item);
            }
          }

          // Merge new items from completed parameter
          for (final c in completed) {
            final item = CompletedVisitItem(
              id: c.id,
              orderId: c.displayOrderId,
              appointmentId: c.appointmentId,
              requestId: c.requestId,
              patientName: c.patientName,
              dateTime: c.time,
              duration: c.distance,
              doctorName: c.doctorName.isNotEmpty ? c.doctorName : 'Doctor',
              address: c.address,
              avatarUrl: c.avatarUrl,
              scheduledDate: c.scheduledDate,
              isFamilyMember: c.isFamilyMember,
              patientAge: c.patientAge,
              patientGender: c.patientGender,
              relation: c.relation,
              bookedByName: c.bookedByName,
            );
            _mergeOrAddCompleted(deduplicatedCompleted, item);
            VisitsRepositoryImpl.markVisitCompleted(
              c.id,
              appointmentId: c.appointmentId,
              requestId: c.requestId,
              orderId: c.orderId,
            );
          }

          _completedGroups['This Week'] = deduplicatedCompleted;

          // 2. Filter New Requests: Remove if already in Today or Completed
          final filteredNew = mappedNewRequests.where((r) {
            final isInToday = _todayVisits.any((t) => _isSameVisit(
              id1: t.id, apt1: t.appointmentId, req1: t.requestId, ord1: t.orderId,
              id2: r.id, apt2: r.appointmentId, req2: r.requestId, ord2: r.orderId,
            ));
            final isCompleted = deduplicatedCompleted.any((c) => _isSameVisit(
              id1: c.id, apt1: c.appointmentId, req1: c.requestId, ord1: c.orderId,
              id2: r.id, apt2: r.appointmentId, req2: r.requestId, ord2: r.orderId,
            )) || VisitsRepositoryImpl.isVisitCompleted(r.id) ||
                (r.appointmentId != null && VisitsRepositoryImpl.isVisitCompleted(r.appointmentId!)) ||
                (r.requestId != null && VisitsRepositoryImpl.isVisitCompleted(r.requestId!));
            return !isInToday && !isCompleted;
          }).toList();

          _newRequests.clear();
          _newRequests.addAll(filteredNew);

          // 3. Process Today Visits: Combine and keep ONLY active, uncompleted visits
          final candidateTodayVisits = <TodayVisitItem>[];
          candidateTodayVisits.addAll(_todayVisits);
          for (final fetched in mappedTodayVisits) {
            final idx = candidateTodayVisits.indexWhere((existing) => _isSameVisit(
              id1: existing.id, apt1: existing.appointmentId, req1: existing.requestId, ord1: existing.orderId,
              id2: fetched.id, apt2: fetched.appointmentId, req2: fetched.requestId, ord2: fetched.orderId,
            ));
            if (idx != -1) {
              final existing = candidateTodayVisits[idx];
              candidateTodayVisits[idx] = fetched.copyWith(
                avatarUrl: fetched.avatarUrl.isNotEmpty ? fetched.avatarUrl : existing.avatarUrl,
                buttonText: existing.buttonText != 'Started' ? existing.buttonText : fetched.buttonText,
                accentColor: existing.accentColor,
                timeColor: existing.timeColor,
                isArrivalButton: existing.isArrivalButton,
                isVitalsUpdated: existing.isVitalsUpdated || fetched.isVitalsUpdated,
                patientAge: (fetched.patientAge != null && fetched.patientAge!.isNotEmpty)
                    ? fetched.patientAge
                    : existing.patientAge,
                patientGender: (fetched.patientGender != null && fetched.patientGender!.isNotEmpty)
                    ? fetched.patientGender
                    : existing.patientGender,
                isFamilyMember: fetched.isFamilyMember || existing.isFamilyMember,
                relation: (fetched.relation != null && fetched.relation!.isNotEmpty)
                    ? fetched.relation
                    : existing.relation,
                bookedByName: (fetched.bookedByName != null && fetched.bookedByName!.isNotEmpty)
                    ? fetched.bookedByName
                    : existing.bookedByName,
              );
            } else {
              candidateTodayVisits.add(fetched);
            }
          }

          final activeTodayMap = <String, TodayVisitItem>{};
          for (final item in candidateTodayVisits) {
            final isCompleted = deduplicatedCompleted.any((c) => _isSameVisit(
              id1: c.id, apt1: c.appointmentId, req1: c.requestId, ord1: c.orderId, name1: c.patientName, date1: c.scheduledDate,
              id2: item.id, apt2: item.appointmentId, req2: item.requestId, ord2: item.orderId, name2: item.patientName, date2: item.scheduledDate,
            )) ||
            VisitsRepositoryImpl.isVisitCompleted(item.id) ||
            (item.appointmentId != null && VisitsRepositoryImpl.isVisitCompleted(item.appointmentId!)) ||
            (item.requestId != null && VisitsRepositoryImpl.isVisitCompleted(item.requestId!)) ||
            (item.orderId != null && VisitsRepositoryImpl.isVisitCompleted(item.orderId!)) ||
            item.buttonText == 'Completed' ||
            item.isVitalsUpdated;

            if (isCompleted) {
              // Add to completed list if not already present
              final compItem = CompletedVisitItem(
                id: item.id,
                orderId: item.displayOrderId,
                appointmentId: item.appointmentId,
                requestId: item.requestId,
                patientName: item.patientName,
                dateTime: item.timeInterval,
                duration: item.distance,
                doctorName: item.doctorName.isNotEmpty ? item.doctorName : 'Doctor',
                address: item.address,
                avatarUrl: item.avatarUrl,
                scheduledDate: item.scheduledDate,
                isFamilyMember: item.isFamilyMember,
                patientAge: item.patientAge,
                patientGender: item.patientGender,
                relation: item.relation,
                bookedByName: item.bookedByName,
              );
              _mergeOrAddCompleted(deduplicatedCompleted, compItem);
              VisitsRepositoryImpl.markVisitCompleted(
                item.id,
                appointmentId: item.appointmentId,
                requestId: item.requestId,
                orderId: item.orderId,
              );
            } else {
              final existingActiveIdx = activeTodayMap.values.toList().indexWhere((act) => _isSameVisit(
                id1: act.id, apt1: act.appointmentId, req1: act.requestId, ord1: act.orderId,
                id2: item.id, apt2: item.appointmentId, req2: item.requestId, ord2: item.orderId,
              ));
              if (existingActiveIdx == -1) {
                activeTodayMap[item.id] = item;
              }
            }
          }

          _todayVisits.clear();
          _todayVisits.addAll(activeTodayMap.values);
          _completedGroups['This Week'] = deduplicatedCompleted;
        });
        _scrollToTargetIfAvailable();
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
        orderId: item.displayOrderId,
        patientName: item.patientName,
        address: item.address,
        distance: item.distance,
        serviceTag: item.serviceTag,
        time: item.time,
        avatarUrl: item.avatarUrl,
        phoneNumber: item.phoneNumber,
        latitude: item.latitude,
        longitude: item.longitude,
        isFamilyMember: item.isFamilyMember,
        patientAge: item.patientAge,
        patientGender: item.patientGender,
        relation: item.relation,
        bookedByName: item.bookedByName,
        scheduledDate: item.scheduledDate,
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
      onTakenByOther: () {
        if (mounted) {
          setState(() {
            _newRequests.removeWhere((r) => r.id == item.id);
          });
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
    final cleanAddress = address.trim();
    final bool isDummyAddress = cleanAddress.isEmpty ||
        cleanAddress.toLowerCase() == 'patient home address' ||
        cleanAddress.toLowerCase() == 'patient address' ||
        cleanAddress.toLowerCase() == 'selected delivery address';

    final bool hasValidCoords = lat != null && lng != null && lat != 0 && lng != 0;

    if (!hasValidCoords && isDummyAddress) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_off_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Patient exact location coordinates are not available for this appointment.'),
                ),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    Uri mapUri;
    if (hasValidCoords) {
      mapUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    } else {
      mapUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(cleanAddress)}');
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
    _blinkTimer?.cancel();
    _blinkTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isHighlightVisible = false;
          _highlightedPatientName = null;
          _highlightedVisitId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _blinkTimer?.cancel();
    _pageController.dispose();
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
    // 1. Build Today item immediately
    final todayItem = TodayVisitItem(
      id: item.id,
      orderId: item.displayOrderId,
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
      isFamilyMember: item.isFamilyMember,
      patientAge: item.patientAge,
      patientGender: item.patientGender,
      relation: item.relation,
      bookedByName: item.bookedByName,
      appointmentId: item.appointmentId,
      requestId: item.requestId,
      scheduledDate: item.scheduledDate,
    );

    // 2. Optimistically update local state & immediately redirect to Today tab
    setState(() {
      _newRequests.removeWhere((r) =>
          r.id == item.id ||
          (item.displayOrderId.isNotEmpty && r.orderId == item.displayOrderId));
      if (!_todayVisits.any((t) =>
          t.id == item.id ||
          (item.displayOrderId.isNotEmpty && t.orderId == item.displayOrderId))) {
        _todayVisits.insert(0, todayItem);
      }
      _selectedTabIndex = 1;
    });
    _switchTab(1);

    // 3. Send API call with all available identifiers
    try {
      final targetOrderId = item.displayOrderId.isNotEmpty
          ? item.displayOrderId
          : (item.orderId ?? (item.id.startsWith('NS') ? item.id : null));

      await _visitsRepo.acceptVisitRequest(
        item.id,
        requestId: item.requestId,
        orderId: targetOrderId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit request accepted! Moved to Today\'s schedule.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        final isExpired = e.statusCode == 410 || e.message.toLowerCase().contains('expired');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isExpired
                  ? 'This visit request has expired on the server.'
                  : (e.message.isNotEmpty ? e.message : 'Failed to accept visit request.'),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      await _loadVisitsData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      await _loadVisitsData();
    }
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
        
        VisitsRepositoryImpl.markVisitCompleted(
          completedItem.id,
          appointmentId: completedItem.appointmentId,
          requestId: completedItem.requestId,
          orderId: completedItem.orderId,
        );

        if (!_completedGroups.containsKey('This Week')) {
          _completedGroups['This Week'] = [];
        }
        
        final newComp = CompletedVisitItem(
          id: completedItem.id,
          orderId: completedItem.displayOrderId,
          appointmentId: completedItem.appointmentId,
          requestId: completedItem.requestId,
          patientName: completedItem.patientName,
          dateTime: 'Today  •  Just now',
          duration: completedItem.distance,
          doctorName: completedItem.doctorName.isNotEmpty ? completedItem.doctorName : 'Doctor',
          address: completedItem.address,
          avatarUrl: completedItem.avatarUrl,
          scheduledDate: completedItem.scheduledDate,
          isFamilyMember: completedItem.isFamilyMember,
          patientAge: completedItem.patientAge,
          patientGender: completedItem.patientGender,
          relation: completedItem.relation,
          bookedByName: completedItem.bookedByName,
        );

        _mergeOrAddCompleted(_completedGroups['This Week']!, newComp);
        
        // Auto switch to Completed tab
        _selectedTabIndex = 2;
      });
      _switchTab(2);

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
          orderId: item.displayOrderId,
          patientName: item.patientName,
          avatarUrl: item.avatarUrl,
        ),
      ),
    );

    if (result != null && (result == true || result is PatientVitalsSummary)) {
      final PatientVitalsSummary? returnedSummary = result is PatientVitalsSummary ? result : null;
      final idx = _todayVisits.indexWhere((v) => _isSameVisit(
        id1: v.id, apt1: v.appointmentId, req1: v.requestId, ord1: v.orderId,
        id2: item.id, apt2: item.appointmentId, req2: item.requestId, ord2: item.orderId,
      ));
      final completedItem = idx != -1 ? _todayVisits.removeAt(idx) : item;

      VisitsRepositoryImpl.markVisitCompleted(
        completedItem.id,
        appointmentId: completedItem.appointmentId,
        requestId: completedItem.requestId,
        orderId: completedItem.orderId,
      );

      if (returnedSummary != null) {
        VisitsRepositoryImpl.saveVitalsSummary(returnedSummary);
      }

      setState(() {
        if (!_completedGroups.containsKey('This Week')) {
          _completedGroups['This Week'] = [];
        }

        final newComp = CompletedVisitItem(
          id: completedItem.id,
          orderId: completedItem.displayOrderId,
          appointmentId: completedItem.appointmentId,
          requestId: completedItem.requestId,
          patientName: completedItem.patientName,
          dateTime: 'Today  •  Just now',
          duration: completedItem.distance,
          doctorName: completedItem.doctorName.isNotEmpty ? completedItem.doctorName : 'Doctor',
          address: completedItem.address,
          avatarUrl: completedItem.avatarUrl,
          vitalsSummary: returnedSummary,
          scheduledDate: completedItem.scheduledDate,
          isFamilyMember: completedItem.isFamilyMember || (returnedSummary?.isFamilyMember ?? false),
          patientAge: completedItem.patientAge ?? (returnedSummary != null && returnedSummary.patientAge.isNotEmpty ? returnedSummary.patientAge : null),
          patientGender: completedItem.patientGender ?? (returnedSummary != null && returnedSummary.patientGender.isNotEmpty ? returnedSummary.patientGender : null),
          relation: completedItem.relation ?? (returnedSummary != null && returnedSummary.relation.isNotEmpty ? returnedSummary.relation : null),
          bookedByName: completedItem.bookedByName,
        );

        _mergeOrAddCompleted(_completedGroups['This Week']!, newComp);

        // Auto switch to Completed tab
        _selectedTabIndex = 2;
      });
      _switchTab(2);

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

            // Filter Tabs Bar (New Requests, Today, Completed) - Full width instant touch
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterTab(
                      index: 0,
                      label: 'New Requests',
                      badge: '${_newRequests.length}',
                      badgeBg: const Color(0xFFFF5C00),
                      badgeIcon: null,
                    ),
                  ),
                  Expanded(
                    child: _buildFilterTab(
                      index: 1,
                      label: 'Today',
                      badge: '${_todayVisits.length}',
                      badgeBg: const Color(0xFF0052FF),
                      badgeIcon: null,
                    ),
                  ),
                  Expanded(
                    child: _buildFilterTab(
                      index: 2,
                      label: 'Completed',
                      badge: '${_completedGroups.values.fold(0, (sum, list) => sum + list.length)}',
                      badgeBg: const Color(0xFF10B981),
                      badgeIcon: null,
                    ),
                  ),
                ],
              ),
            ),

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _switchTab(index),
        splashColor: const Color(0x15FF5C00),
        highlightColor: const Color(0x0AFF5C00),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? const Color(0xFFFF5C00) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 5),

                  // Circle / Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: badgeIcon != null
                        ? Icon(badgeIcon, color: Colors.white, size: 11)
                        : Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Active tab underline indicator bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: 3,
                width: isSelected ? 48 : 0,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF5C00) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBodyContent() {
    return PageView(
      controller: _pageController,
      physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
      onPageChanged: (index) {
        if (_selectedTabIndex != index) {
          setState(() {
            _selectedTabIndex = index;
          });
        }
      },
      children: [
        _KeepAliveTabWrapper(child: _buildNewRequestsView()),
        _KeepAliveTabWrapper(child: _buildTodayVisitsView()),
        _KeepAliveTabWrapper(child: _buildCompletedVisitsView()),
      ],
    );
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
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: const Center(
                        child: Text(
                          'No matching requests found',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                      ),
                    ),
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 14.0, 14.0, 14.0),
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
                              child: _buildPatientAvatarWidget(item.avatarUrl, item.patientName, 56),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                    const SizedBox(width: 6),
                                    if (item.isFamilyMember)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFBFDBFE)),
                                        ),
                                        child: Text(
                                          item.relation != null && item.relation!.isNotEmpty && item.relation != 'Family Member'
                                              ? item.relation!
                                              : 'Family Member',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
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
                                    bookedByName: item.bookedByName,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                if (item.displayOrderId.isNotEmpty) ...[
                                  const SizedBox(height: 4),
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
                                          Flexible(
                                            child: Text(
                                              'Order ID: ${item.displayOrderId}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Service Tags & Preferences
                      Wrap(
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF5C00),
                                    ),
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
                                    Flexible(
                                      child: Text(
                                        'Female Nurse Preferred',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDB2777),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Appointment Time & Date Container (Time displayed above Date/Day to prevent overlap)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_cleanDisplayTime(item.time).isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: Color(0xFF0052FF),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _cleanDisplayTime(item.time),
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
                              const SizedBox(height: 4),
                            ],
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 13,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.formattedAppointmentDate,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
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
                // Orange vertical accent bar on left
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: 4,
                  child: Container(color: const Color(0xFFFF5C00)),
                ),
              ],
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

    _scrollToTargetIfAvailable();

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
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: const Center(
                        child: Text(
                          'No matching visits found',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                      ),
                    ),
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
    final bool isExactTarget = (_highlightedVisitId != null && _highlightedVisitId!.isNotEmpty && item.id == _highlightedVisitId) ||
        (_highlightedPatientName != null &&
            _highlightedPatientName!.isNotEmpty &&
            item.patientName.trim().toLowerCase() == _highlightedPatientName!.trim().toLowerCase());

    final bool isHighlighted = _isHighlightVisible && isExactTarget;

    return AnimatedContainer(
      key: isExactTarget ? _targetCardKey : null,
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 14.0, 14.0, 14.0),
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
                              child: _buildPatientAvatarWidget(item.avatarUrl, item.patientName, 52),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                    const SizedBox(width: 6),
                                    if (item.isFamilyMember)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFBFDBFE)),
                                        ),
                                        child: Text(
                                          item.relation != null && item.relation!.isNotEmpty && item.relation != 'Family Member'
                                              ? item.relation!
                                              : 'Family Member',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
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
                                    bookedByName: item.bookedByName,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                if (item.displayOrderId.isNotEmpty) ...[
                                  const SizedBox(height: 4),
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
                                          Flexible(
                                            child: Text(
                                              'Order ID: ${item.displayOrderId}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                      const SizedBox(height: 10),

                      // Appointment Time & Date Container (Full width across card: Time on TOP, Date & Day UNDER IT)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_cleanDisplayTime(item.timeInterval).isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: Color(0xFF0052FF),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _cleanDisplayTime(item.timeInterval),
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
                              const SizedBox(height: 4),
                            ],
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 13,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.formattedAppointmentDate,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
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
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    color: isHighlighted ? const Color(0xFFFF5C00) : item.accentColor,
                  ),
                ),
              ],
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
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(
              child: Text(
                'No matching completed visits found',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 14.0, 14.0, 14.0),
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
                              child: _buildPatientAvatarWidget(item.avatarUrl, item.patientName, 52),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                    const SizedBox(width: 6),
                                    if (item.isFamilyMember)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFBFDBFE)),
                                        ),
                                        child: Text(
                                          item.relation != null && item.relation!.isNotEmpty && item.relation != 'Family Member'
                                              ? item.relation!
                                              : 'Family Member',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
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
                                    bookedByName: item.bookedByName,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                if (item.displayOrderId.isNotEmpty) ...[
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
                                          Flexible(
                                            child: Text(
                                              'Order ID: ${item.displayOrderId}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Appointment Time & Date Container (Full width across card: Time on TOP, Date & Day UNDER IT)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_cleanDisplayTime(item.dateTime).isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _cleanDisplayTime(item.dateTime),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF059669),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 13,
                                  color: Color(0xFF047857),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.formattedAppointmentDate,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF065F46),
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

                      const SizedBox(height: 12),

                      // View Vitals & Reports Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            PatientVitalsSummary? summary = item.vitalsSummary;
                            summary ??= await _visitsRepo.getVitalsForAppointment(item.id);
                            summary ??= await _visitsRepo.getVitalsForAppointment(item.patientName);
                            if (summary != null && mounted) {
                              ViewVitalsBottomSheet.show(context, summary);
                            }
                          },
                          icon: const Icon(
                            Icons.monitor_heart_outlined,
                            size: 17,
                            color: Color(0xFF10B981),
                          ),
                          label: const Text(
                            'View Vitals & Reports',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFECFDF5),
                            side: const BorderSide(color: Color(0xFFA7F3D0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: 4,
                  child: Container(color: const Color(0xFF10B981)),
                ),
              ],
            ),
          ),
        );
      }
  Widget _buildPatientAvatarWidget(String avatarUrl, String patientName, double size) {
    final clean = avatarUrl.trim();
    if (clean.isNotEmpty && clean != 'null' && clean != 'undefined') {
      // 1. Data URI / Base64 image
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
            errorBuilder: (_, _, _) => _buildPatientFallbackAvatar(size),
          );
        } catch (_) {}
      }

      // 2. Local File
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
              errorBuilder: (_, _, _) => _buildPatientFallbackAvatar(size),
            );
          }
        } catch (_) {}
      }

      // 3. Network URL (http/https or relative endpoint formatted with baseUrl)
      final fullUrl = formatImageUrl(clean);
      if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
        return Image.network(
          fullUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPatientFallbackAvatar(size);
          },
        );
      }
    }

    return _buildPatientFallbackAvatar(size);
  }

  Widget _buildPatientFallbackAvatar(double size) {
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

/// Helper wrapper that preserves the tab's state and scroll position across swipes
class _KeepAliveTabWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveTabWrapper({required this.child});

  @override
  State<_KeepAliveTabWrapper> createState() => _KeepAliveTabWrapperState();
}

class _KeepAliveTabWrapperState extends State<_KeepAliveTabWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
