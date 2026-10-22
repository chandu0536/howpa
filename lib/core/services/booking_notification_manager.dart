import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:howpa_nurse/features/visits/data/models/visit_models.dart';
import 'package:howpa_nurse/features/visits/data/repositories/visits_repository.dart';

class BookingNotificationManager {
  static bool isPopupShowing = false;
  static final Set<String> _shownRequestIds = {};
  static AudioPlayer? _audioPlayer;

  // Active dialog tracking for auto-dismissal when accepted by another nurse
  static String? _currentShowingId;
  static BuildContext? _currentDialogContext;
  static BuildContext? _currentParentContext;
  static Timer? _availabilityPollingTimer;
  static VoidCallback? _currentOnTakenByOther;

  static void markAsShown(String id) {
    _shownRequestIds.add(id);
  }

  static bool hasBeenShown(String id) {
    return _shownRequestIds.contains(id);
  }

  static void clearAll() {
    _shownRequestIds.clear();
    isPopupShowing = false;
    _currentShowingId = null;
    _currentDialogContext = null;
    _currentParentContext = null;
    _availabilityPollingTimer?.cancel();
    _availabilityPollingTimer = null;
    _currentOnTakenByOther = null;
    stopBuzzer();
  }

  static Future<void> stopBuzzer() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer?.stop();
        await _audioPlayer?.dispose();
        _audioPlayer = null;
      }
    } catch (_) {}
  }

  static void _cleanupPopupState() {
    isPopupShowing = false;
    _currentShowingId = null;
    _currentDialogContext = null;
    _availabilityPollingTimer?.cancel();
    _availabilityPollingTimer = null;
    _currentOnTakenByOther = null;
    stopBuzzer();
  }

  static void reset() {
    _cleanupPopupState();
  }

  /// Programmatically dismiss the active popup if the given requestId matches
  /// (e.g. when another nurse accepts it, or an FCM push notification informs us it was taken)
  static void dismissIfMatching(String id, {String reason = 'This visit request was accepted by another nurse.'}) {
    if (isPopupShowing && _currentShowingId == id) {
      debugPrint('⚡ [BOOKING POPUP] Auto-dismissing popup for request $id: $reason');
      final dialogCtx = _currentDialogContext;
      final parentCtx = _currentParentContext;
      final onTaken = _currentOnTakenByOther;

      _cleanupPopupState();

      if (dialogCtx != null && dialogCtx.mounted) {
        try {
          Navigator.of(dialogCtx, rootNavigator: true).pop('TAKEN_BY_OTHER');
        } catch (_) {}
      }

      onTaken?.call();

      if (parentCtx != null && parentCtx.mounted) {
        ScaffoldMessenger.of(parentCtx).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reason,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE11D48),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  static Future<void> showNewBookingDialog({
    required BuildContext context,
    required VisitRequestItem item,
    required Future<void> Function() onAccept,
    required Future<void> Function() onReject,
    VoidCallback? onTakenByOther,
  }) async {
    if (isPopupShowing || _shownRequestIds.contains(item.id)) return;

    isPopupShowing = true;
    _currentShowingId = item.id;
    _currentParentContext = context;
    _currentOnTakenByOther = onTakenByOther;
    _shownRequestIds.add(item.id);

    // Play Buzzer Audio (Looping until accepted, rejected, or auto-dismissed)
    try {
      await stopBuzzer();
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setVolume(1.0);
      await _audioPlayer!.play(AssetSource('images/buzzer_gojek.mp3'));
    } catch (e) {
      debugPrint('Error playing buzzer audio: $e');
    }

    // Live Availability Poller: Polls every 2 seconds to check if another nurse took the visit
    _availabilityPollingTimer?.cancel();
    _availabilityPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!isPopupShowing || _currentShowingId != item.id) {
        timer.cancel();
        return;
      }
      try {
        final repo = VisitsRepositoryImpl();
        final list = await repo.getNearbyRequests();
        final isStillAvailable = list.any((r) => r.id == item.id);
        if (!isStillAvailable) {
          debugPrint('⚡ [BOOKING POPUP] Request ${item.id} is no longer pending (taken by another nurse)!');
          timer.cancel();
          dismissIfMatching(
            item.id,
            reason: 'This visit request was accepted by another nurse.',
          );
        }
      } catch (e) {
        debugPrint('⚠️ Error polling visit availability: $e');
      }
    });

    try {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) {
          _currentDialogContext = dialogCtx;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 16,
            backgroundColor: Colors.white,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  // Glowing Bell Badge
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFECDD3), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33F43F5E),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFFE11D48),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Popup Title & Tagline
                  const Text(
                    '🚨 NEW NURSE BOOKING!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A new patient visit request has just arrived.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (item.displayOrderId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tag_rounded, size: 13, color: Color(0xFF0052FF)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Order ID: ${item.displayOrderId}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0052FF),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Patient Details Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF1F5F9),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              ),
                              child: ClipOval(
                                child: _buildAvatarWidget(item.avatarUrl, item.patientName, 44),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Patient Name + Family/Self Badge
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
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.people_alt_rounded, size: 11, color: Color(0xFF2563EB)),
                                              const SizedBox(width: 3),
                                              Text(
                                                item.relation != null && item.relation!.isNotEmpty && item.relation != 'Family Member'
                                                    ? item.relation!
                                                    : 'Family Member',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.person_outline_rounded, size: 11, color: Color(0xFF64748B)),
                                              SizedBox(width: 3),
                                              Text(
                                                'Self',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),

                                  // Age & Gender subtitle
                                  const SizedBox(height: 3),
                                  Text(
                                    formatDemographics(
                                      gender: item.patientGender,
                                      age: item.patientAge,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),

                                  // If booked by user for family member
                                  if (item.isFamilyMember && item.bookedByName != null && item.bookedByName!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Requested by: ${item.bookedByName}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 5),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF3EC),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.serviceTag,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFF5C00),
                                          ),
                                        ),
                                      ),
                                      if (item.displayOrderId.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Text(
                                            'ID: ${item.displayOrderId}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF475569),
                                            ),
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
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF0052FF)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.address,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (item.bookedServices.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Booked Services (${item.bookedServices.length})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...item.bookedServices.map((svc) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  if (svc.imageUrl != null && svc.imageUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        svc.imageUrl!,
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.medical_services_outlined,
                                          size: 18,
                                          color: Color(0xFF0052FF),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.medical_services_outlined,
                                        size: 16,
                                        color: Color(0xFF0052FF),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      svc.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (svc.price != null && svc.price! > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '₹${svc.price!.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.time.isNotEmpty &&
                                  !item.time.toLowerCase().contains('today') &&
                                  !item.time.toLowerCase().contains('scheduled')) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF0052FF)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.time,
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
                                  const Icon(Icons.calendar_month_rounded, size: 13, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.formattedAppointmentDate,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
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
                        if (item.distance.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF0052FF)),
                              const SizedBox(width: 4),
                              Text(
                                item.distance,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0052FF)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            _cleanupPopupState();
                            Navigator.pop(dialogCtx);
                            await onReject();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF3B30), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF3B30)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0052FF), Color(0xFFFF5C00)],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              _cleanupPopupState();
                              Navigator.pop(dialogCtx);
                              await onAccept();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Accept Visit',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Top-Right Close Button ("Into Mark")
            Positioned(
              top: 14,
              right: 14,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _cleanupPopupState();
                    Navigator.of(dialogCtx).pop();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
        },
      );
    } finally {
      _cleanupPopupState();
    }
  }

  static Widget _buildAvatarWidget(String avatarUrl, String patientName, double size) {
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

  static Widget _buildFallbackAvatar(double size) {
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
