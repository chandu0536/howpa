import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/user_profile_manager.dart';
import '../models/visit_models.dart';

import '../../../../core/network/token_storage.dart';

abstract class VisitsRepository {
  Future<List<VisitRequestItem>> getNearbyRequests();
  Future<List<VisitRequestItem>> getTodayVisits();
  Future<List<VisitRequestItem>> getUpcomingVisits();
  Future<bool> acceptVisitRequest(String appointmentId);
  Future<bool> rejectVisitRequest(String appointmentId, {String? reason});
  Future<bool> updateVisitStatus(String appointmentId, String status);
  Future<bool> recordPatientVitals(RecordVitalsRequest request);
  Future<List<dynamic>> getVitalsHistory({String? search, String? appointmentId});
  Future<bool> submitDiagnosticReport(SubmitReportRequest request);
  Future<List<VisitRequestItem>> getCompletedVisitHistory();
}

class VisitsRepositoryImpl implements VisitsRepository {
  final ApiClient _client;

  static final List<VisitRequestItem> _cachedNearbyRequests = [];
  static final List<VisitRequestItem> _cachedTodayVisits = [];
  static final List<VisitRequestItem> _cachedCompletedVisits = [];

  static final Map<String, VisitRequestItem> _locallyAcceptedVisits = {};
  static final Set<String> _locallyRejectedIds = {};
  static final Set<String> _locallyCompletedIds = {};

  VisitsRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient.instance;

  @override
  Future<List<VisitRequestItem>> getNearbyRequests() async {
    if (!TokenStorage.isOnline) {
      return [];
    }
    try {
      final response = await _client.get(ApiEndpoints.requests);
      List<VisitRequestItem> fetched = [];
      if (response != null) {
        if (response is List) {
          fetched = response
              .whereType<Map<String, dynamic>>()
              .map((item) => VisitRequestItem.fromJson(item))
              .toList();
        } else if (response is Map<String, dynamic>) {
          final listData = response['requests'] ??
              response['nearbyRequests'] ??
              response['broadcasts'] ??
              response['visitRequests'] ??
              response['data'] ??
              response['requestsList'] ??
              response['appointments'];
          if (listData is List) {
            fetched = listData
                .whereType<Map<String, dynamic>>()
                .map((item) => VisitRequestItem.fromJson(item))
                .toList();
          }
        }
        
        final nurseGender = UserProfileManager.instance.gender.trim().toLowerCase();
        final isFemaleNurse = nurseGender == 'female' || nurseGender == 'f';

        final filtered = fetched.where((item) {
          if (item.id.isEmpty) return false;
          if (_locallyAcceptedVisits.containsKey(item.id)) return false;
          if (_locallyRejectedIds.contains(item.id)) return false;
          if (_locallyCompletedIds.contains(item.id)) return false;

          // If patient preferred a female nurse, only show request to female nurses
          if (item.femaleNursePreferred && !isFemaleNurse && nurseGender.isNotEmpty) {
            return false;
          }

          final st = item.status.toUpperCase();
          if (st == 'ACCEPTED' || st == 'ARRIVED' || st == 'STARTED' || st == 'COMPLETED' || st == 'REJECTED' || st == 'CANCELLED') {
            return false;
          }
          return true;
        }).toList();

        _cachedNearbyRequests.clear();
        _cachedNearbyRequests.addAll(filtered);
      }
    } catch (_) {}
    return List.unmodifiable(_cachedNearbyRequests);
  }

  @override
  Future<List<VisitRequestItem>> getTodayVisits() async {
    try {
      final response = await _client.get('${ApiEndpoints.visits}?filter=today');
      if (response != null) {
        List<dynamic>? listData;
        if (response is Map<String, dynamic>) {
          listData = (response['activeVisits'] ?? response['visits'] ?? response['data']) as List<dynamic>?;
        } else if (response is List) {
          listData = response;
        }
        if (listData != null) {
          final fetched = listData
              .whereType<Map<String, dynamic>>()
              .map((item) => VisitRequestItem.fromJson(item))
              .where((item) => !_locallyRejectedIds.contains(item.id) && !_locallyCompletedIds.contains(item.id))
              .toList();

          final enriched = <VisitRequestItem>[];
          for (final f in fetched) {
            VisitRequestItem? existing;
            final cacheIdx = _cachedTodayVisits.indexWhere((c) => c.id == f.id);
            if (cacheIdx != -1) {
              existing = _cachedTodayVisits[cacheIdx];
            } else if (_locallyAcceptedVisits.containsKey(f.id)) {
              existing = _locallyAcceptedVisits[f.id];
            }

            final realName = (f.patientName.isNotEmpty && f.patientName != 'Patient')
                ? f.patientName
                : (existing != null && existing.patientName.isNotEmpty && existing.patientName != 'Patient'
                    ? existing.patientName
                    : f.patientName);

            final realAddr = (f.address.isNotEmpty && f.address != 'Selected Delivery Address' && f.address != 'Patient Home Address')
                ? f.address
                : (existing != null && existing.address.isNotEmpty ? existing.address : f.address);

            final realAvatar = f.avatarUrl.isNotEmpty ? f.avatarUrl : (existing?.avatarUrl ?? '');
            final realPhone = f.phoneNumber.isNotEmpty
                ? f.phoneNumber
                : (existing?.phoneNumber ?? f.phoneNumber);

            enriched.add(VisitRequestItem(
              id: f.id,
              patientName: realName,
              address: realAddr,
              distance: f.distance,
              serviceTag: f.serviceTag,
              time: f.time,
              avatarUrl: realAvatar,
              status: f.status,
              notes: f.notes,
              conditionImages: f.conditionImages,
              phoneNumber: realPhone,
              latitude: f.latitude ?? existing?.latitude,
              longitude: f.longitude ?? existing?.longitude,
              isVitalsUpdated: f.isVitalsUpdated || (existing?.isVitalsUpdated ?? false),
              doctorName: f.doctorName.isNotEmpty ? f.doctorName : (existing?.doctorName ?? ''),
            ));
          }

          _cachedTodayVisits.clear();
          _cachedTodayVisits.addAll(enriched);

          // Clear synced items from local memory
          for (final f in enriched) {
            _locallyAcceptedVisits.remove(f.id);
          }

          // Preserve locally accepted items until backend reflects them
          for (final localAcc in _locallyAcceptedVisits.values) {
            if (!_cachedTodayVisits.any((t) => t.id == localAcc.id)) {
              _cachedTodayVisits.add(localAcc);
            }
          }
        }
      }
    } catch (_) {}
    return List.unmodifiable(_cachedTodayVisits);
  }

  @override
  Future<List<VisitRequestItem>> getUpcomingVisits() async {
    return getTodayVisits();
  }

  @override
  Future<bool> acceptVisitRequest(String appointmentId) async {
    // Instant local state update
    final index = _cachedNearbyRequests.indexWhere((r) => r.id == appointmentId);
    VisitRequestItem? item;
    if (index != -1) {
      item = _cachedNearbyRequests.removeAt(index);
    }
    
    final acceptedItem = VisitRequestItem(
      id: appointmentId,
      patientName: item?.patientName ?? 'Patient',
      address: item?.address ?? 'Patient Address',
      distance: item?.distance ?? '1.5 km',
      serviceTag: item?.serviceTag ?? 'Home Care',
      time: item?.time ?? 'Today • Scheduled',
      avatarUrl: item?.avatarUrl ?? '',
      status: 'ACCEPTED',
      notes: item?.notes ?? 'Assigned for nursing home care visit.',
      phoneNumber: item?.phoneNumber ?? '',
      latitude: item?.latitude,
      longitude: item?.longitude,
    );

    _locallyAcceptedVisits[appointmentId] = acceptedItem;
    _locallyRejectedIds.remove(appointmentId);

    if (!_cachedTodayVisits.any((t) => t.id == appointmentId)) {
      _cachedTodayVisits.add(acceptedItem);
    }

    try {
      final nurseId = UserProfileManager.instance.nurseId;
      final body = <String, dynamic>{
        'requestId': appointmentId,
        'appointmentId': appointmentId,
        'id': appointmentId,
        '_id': appointmentId,
      };
      if (nurseId.isNotEmpty) {
        body['nurseId'] = nurseId;
      }

      final response = await _client.post(
        ApiEndpoints.requestsAccept,
        body: body,
      );
      if (response != null && response['data'] != null && response['data'] is Map<String, dynamic>) {
        final serverAccepted = VisitRequestItem.fromJson(response['data'] as Map<String, dynamic>);
        final mergedName = (serverAccepted.patientName.isNotEmpty && serverAccepted.patientName != 'Patient')
            ? serverAccepted.patientName
            : acceptedItem.patientName;
        final mergedAddr = (serverAccepted.address.isNotEmpty && serverAccepted.address != 'Selected Delivery Address' && serverAccepted.address != 'Patient Home Address')
            ? serverAccepted.address
            : acceptedItem.address;

        final finalItem = VisitRequestItem(
          id: serverAccepted.id.isNotEmpty ? serverAccepted.id : appointmentId,
          patientName: mergedName,
          address: mergedAddr,
          distance: serverAccepted.distance,
          serviceTag: serverAccepted.serviceTag,
          time: serverAccepted.time,
          avatarUrl: serverAccepted.avatarUrl.isNotEmpty ? serverAccepted.avatarUrl : acceptedItem.avatarUrl,
          status: 'ACCEPTED',
          notes: serverAccepted.notes,
          phoneNumber: serverAccepted.phoneNumber,
          latitude: serverAccepted.latitude ?? acceptedItem.latitude,
          longitude: serverAccepted.longitude ?? acceptedItem.longitude,
          isVitalsUpdated: serverAccepted.isVitalsUpdated || acceptedItem.isVitalsUpdated,
          doctorName: serverAccepted.doctorName.isNotEmpty ? serverAccepted.doctorName : acceptedItem.doctorName,
        );

        _locallyAcceptedVisits[appointmentId] = finalItem;
        final todayIdx = _cachedTodayVisits.indexWhere((t) => t.id == appointmentId || t.id == finalItem.id);
        if (todayIdx != -1) {
          _cachedTodayVisits[todayIdx] = finalItem;
        } else {
          _cachedTodayVisits.add(finalItem);
        }
      }
    } catch (_) {}

    return true;
  }

  @override
  Future<bool> rejectVisitRequest(String appointmentId, {String? reason}) async {
    // Instant local state update
    _locallyAcceptedVisits.remove(appointmentId);
    _locallyRejectedIds.add(appointmentId);

    _cachedNearbyRequests.removeWhere((r) => r.id == appointmentId);
    _cachedTodayVisits.removeWhere((r) => r.id == appointmentId);

    // Async sync with backend in background
    _client.post(
      ApiEndpoints.requestsReject,
      body: {'requestId': appointmentId, 'appointmentId': appointmentId, 'reason': reason ?? 'Occupied'},
    ).catchError((_) => null);

    return true;
  }

  @override
  Future<bool> updateVisitStatus(String appointmentId, String status) async {
    // Instant local AJAX state update
    final index = _cachedTodayVisits.indexWhere((r) => r.id == appointmentId);
    if (index != -1) {
      final item = _cachedTodayVisits[index];
      if (status == 'COMPLETED') {
        _cachedTodayVisits.removeAt(index);
        _cachedCompletedVisits.insert(0, VisitRequestItem(
          id: item.id,
          patientName: item.patientName,
          address: item.address,
          distance: item.distance,
          serviceTag: item.serviceTag,
          time: 'Today • Just now',
          avatarUrl: item.avatarUrl,
          status: 'COMPLETED',
          notes: item.notes,
          phoneNumber: item.phoneNumber,
          latitude: item.latitude,
          longitude: item.longitude,
        ));
      } else {
        _cachedTodayVisits[index] = VisitRequestItem(
          id: item.id,
          patientName: item.patientName,
          address: item.address,
          distance: item.distance,
          serviceTag: item.serviceTag,
          time: item.time,
          avatarUrl: item.avatarUrl,
          status: status,
          notes: item.notes,
          phoneNumber: item.phoneNumber,
          latitude: item.latitude,
          longitude: item.longitude,
        );
      }
    }

    // Async sync with backend in background
    _client.patch(
      ApiEndpoints.visits,
      body: {'requestId': appointmentId, 'appointmentId': appointmentId, 'status': status},
    ).catchError((_) => null);

    return true;
  }

  @override
  Future<bool> recordPatientVitals(RecordVitalsRequest request) async {
    try {
      // ── Map vital name → backend file field key ──
      const vitalFileKeys = <String, String>{
        'Blood Pressure': 'bp_image',
        'Heart Rate': 'pulse_image',
        'Temperature': 'temp_image',
        'Blood Sugar': 'sugar_image',
        'SpO2': 'spo2_image',
        'Weight': 'weight_image',
      };

      final filesMap = <String, File>{};

      // 1. Per-vital proof photos  →  bp_image, sugar_image, spo2_image, etc.
      final vitalImages = request.vitalImages;
      if (vitalImages != null) {
        for (final entry in vitalImages.entries) {
          final file = File(entry.value);
          if (!file.existsSync()) continue;
          // Look up exact backend key, fall back to generic vital_<name>
          final backendKey = vitalFileKeys[entry.key] ??
              'vital_${entry.key.toLowerCase().replaceAll(' ', '_')}';
          filesMap[backendKey] = file;
        }
      }

      // 2. Condition / wound photos  →  condition_photos[]
      final conditionImages = request.conditionImages;
      if (conditionImages != null) {
        for (int i = 0; i < conditionImages.length; i++) {
          final file = File(conditionImages[i]);
          if (!file.existsSync()) continue;
          // Backend accepts repeated key: condition_photos
          filesMap['condition_photos[$i]'] = file;
          filesMap['wound_photos[$i]'] = file; // alias
        }
      }

      // 3. Old reports / records  →  old_reports[]
      final oldReportFiles = request.oldReportFiles;
      if (oldReportFiles != null) {
        for (int i = 0; i < oldReportFiles.length; i++) {
          final file = File(oldReportFiles[i]);
          if (!file.existsSync()) continue;
          filesMap['old_reports[$i]'] = file;
          filesMap['patient_reports[$i]'] = file; // alias
        }
      }

      // 4. Custom vitals proof photos
      final customVitals = request.customVitals;
      if (customVitals != null) {
        for (int i = 0; i < customVitals.length; i++) {
          final imgPath = customVitals[i]['imagePath'];
          if (imgPath != null && imgPath.isNotEmpty) {
            final file = File(imgPath);
            if (file.existsSync()) {
              final cleanType = (customVitals[i]['type'] ?? 'custom')
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
              filesMap['vital_$cleanType'] = file;
              filesMap['custom_vital_${i}_image'] = file;
            }
          }
        }
      }

      if (filesMap.isNotEmpty) {
        // ── Multipart upload with exact backend field names ──
        await _client.multipartRequest(
          method: 'POST',
          url: ApiEndpoints.vitals,
          fields: request.toFormFields(),
          files: filesMap,
        );
      } else {
        // ── Pure JSON fallback (no file attachments) ──
        await _client.post(ApiEndpoints.vitals, body: request.toJson());
      }

      // ── Local state: mark visit as completed ──
      _locallyCompletedIds.add(request.appointmentId);
      final idx =
          _cachedTodayVisits.indexWhere((t) => t.id == request.appointmentId);
      if (idx != -1) {
        final item = _cachedTodayVisits.removeAt(idx);
        final completedItem = VisitRequestItem(
          id: item.id,
          patientName: item.patientName,
          address: item.address,
          distance: item.distance,
          serviceTag: item.serviceTag,
          time: item.time,
          avatarUrl: item.avatarUrl,
          status: 'COMPLETED',
          notes: item.notes,
          phoneNumber: item.phoneNumber,
          latitude: item.latitude,
          longitude: item.longitude,
          isVitalsUpdated: true,
          doctorName: item.doctorName,
        );
        _cachedCompletedVisits.removeWhere((c) => c.id == item.id);
        _cachedCompletedVisits.insert(0, completedItem);
      }
    } catch (_) {}
    return true;
  }



  @override
  Future<List<dynamic>> getVitalsHistory({String? search, String? appointmentId}) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (appointmentId != null && appointmentId.isNotEmpty) queryParams['appointmentId'] = appointmentId;

      final response = await _client.get(
        ApiEndpoints.vitals,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response != null && response is Map<String, dynamic>) {
        final listData = response['data'] ?? response['vitals'];
        if (listData is List) return listData;
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<bool> submitDiagnosticReport(SubmitReportRequest request) async {
    _client.post(ApiEndpoints.reports, body: request.toJson()).catchError((_) => null);
    return true;
  }

  @override
  Future<List<VisitRequestItem>> getCompletedVisitHistory() async {
    try {
      // Try working endpoints first; /history often returns 500 on server
      dynamic response =
          await _client.get('${ApiEndpoints.visits}?filter=completed').catchError((_) => null);
      response ??= await _client
          .get('${ApiEndpoints.history}?status=COMPLETED&page=1&limit=50')
          .catchError((_) => null);
      response ??= await _client
          .get('${ApiEndpoints.history}?status=ALL&page=1&limit=50')
          .catchError((_) => null);
      response ??= await _client.get(ApiEndpoints.history).catchError((_) => null);

      if (response != null) {
        List<dynamic>? listData;
        if (response is Map<String, dynamic>) {
          listData = (response['history'] ??
              response['completedVisits'] ??
              response['visits'] ??
              response['activeVisits'] ??
              response['requests'] ??
              response['data']) as List<dynamic>?;
        } else if (response is List) {
          listData = response;
        }
        if (listData != null && listData.isNotEmpty) {
          final fetched = listData
              .whereType<Map<String, dynamic>>()
              .map((item) => VisitRequestItem.fromJson(item))
              .where((item) {
                final st = item.status.toUpperCase();
                return st == 'COMPLETED' || st == 'DONE';
              })
              .toList();

          for (final f in fetched) {
            final idx = _cachedCompletedVisits.indexWhere((c) => c.id == f.id);
            if (idx != -1) {
              _cachedCompletedVisits[idx] = f;
            } else {
              _cachedCompletedVisits.add(f);
            }
          }
        }
      }
    } catch (_) {}
    return List.unmodifiable(_cachedCompletedVisits);
  }
}

