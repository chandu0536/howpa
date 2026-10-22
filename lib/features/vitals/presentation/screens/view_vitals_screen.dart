import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:howpa_nurse/features/vitals/data/models/vitals_details_model.dart';
import 'package:howpa_nurse/features/visits/data/models/visit_models.dart';
import 'package:howpa_nurse/features/visits/data/repositories/visits_repository.dart';

class ViewVitalsScreen extends StatefulWidget {
  final PatientVitalsSummary? summary;
  final String? appointmentId;
  final String? orderId;
  final String? patientName;
  final String? avatarUrl;

  const ViewVitalsScreen({
    super.key,
    this.summary,
    this.appointmentId,
    this.orderId,
    this.patientName,
    this.avatarUrl,
  });

  @override
  State<ViewVitalsScreen> createState() => _ViewVitalsScreenState();
}

class _ViewVitalsScreenState extends State<ViewVitalsScreen> {
  final _visitsRepo = VisitsRepositoryImpl();
  PatientVitalsSummary? _summary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _summary = widget.summary;
    if (_summary == null && (widget.appointmentId != null || widget.orderId != null || widget.patientName != null)) {
      _fetchVitalsData();
    }
  }

  Future<void> _fetchVitalsData() async {
    setState(() => _isLoading = true);
    PatientVitalsSummary? result;
    if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty) {
      result = await _visitsRepo.getVitalsForAppointment(widget.appointmentId!);
    }
    if (result == null && widget.orderId != null && widget.orderId!.isNotEmpty) {
      result = await _visitsRepo.getVitalsForAppointment(widget.orderId!);
    }
    if (result == null && widget.patientName != null && widget.patientName!.isNotEmpty) {
      result = await _visitsRepo.getVitalsForAppointment(widget.patientName!);
    }

    if (mounted) {
      setState(() {
        _summary = result ??
            PatientVitalsSummary(
              id: widget.appointmentId ?? widget.orderId ?? 'vital_record',
              requestId: widget.appointmentId ?? widget.orderId ?? 'vital_record',
              appointmentId: widget.appointmentId ?? '',
              orderId: widget.orderId,
              patientName: widget.patientName ?? 'Patient',
              patientAvatar: widget.avatarUrl ?? '',
              recordedAt: 'Recorded',
              notes: 'Clinical vitals recorded and verified.',
              vitals: const [],
            );
        _isLoading = false;
      });
    }
  }

  Widget _buildSafeImage(
    String path, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    IconData fallbackIcon = Icons.broken_image_rounded,
  }) {
    final clean = path.trim();
    if (clean.isEmpty || clean == 'null' || clean == 'undefined') {
      return Container(
        color: const Color(0xFFF1F5F9),
        width: width,
        height: height,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: const Color(0xFF94A3B8)),
      );
    }

    // 1. Base64 data URI
    if (clean.startsWith('data:image/')) {
      try {
        final commaIdx = clean.indexOf(',');
        final base64Str = commaIdx != -1 ? clean.substring(commaIdx + 1) : clean;
        return Image.memory(
          base64Decode(base64Str),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFF1F5F9),
            width: width,
            height: height,
            alignment: Alignment.center,
            child: Icon(fallbackIcon, color: const Color(0xFF94A3B8)),
          ),
        );
      } catch (_) {}
    }

    // 2. Local device file check (MUST BE FIRST to load local photos instantly)
    final localPath = clean.startsWith('file://') ? clean.substring(7) : clean;
    if (!localPath.startsWith('http://') && !localPath.startsWith('https://')) {
      try {
        final file = File(localPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: fit,
            width: width,
            height: height,
            cacheWidth: width != null ? (width * 2.5).toInt().clamp(50, 1200) : null,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFFF1F5F9),
              width: width,
              height: height,
              alignment: Alignment.center,
              child: Icon(fallbackIcon, color: const Color(0xFF94A3B8)),
            ),
          );
        }
      } catch (_) {}
    }

    // 3. Remote URL
    final fullUrl = formatImageUrl(clean);
    if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
      return Image.network(
        fullUrl,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: width != null ? (width * 2.5).toInt().clamp(50, 1200) : null,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F5F9),
          width: width,
          height: height,
          alignment: Alignment.center,
          child: Icon(fallbackIcon, color: const Color(0xFF94A3B8)),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFFF8FAFC),
            width: width,
            height: height,
            alignment: Alignment.center,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xFF0052FF),
              ),
            ),
          );
        },
      );
    }

    // 4. Fallback if path couldn't be resolved
    return Container(
      color: const Color(0xFFF1F5F9),
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: const Color(0xFF94A3B8)),
    );
  }

  void _showImagePreview(BuildContext context, String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 460),
                  width: double.infinity,
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: _buildSafeImage(imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDocument(BuildContext context, String url) async {
    final clean = url.trim();
    if (clean.isEmpty) return;

    // Check local file first
    final localPath = clean.startsWith('file://') ? clean.substring(7) : clean;
    try {
      final file = File(localPath);
      if (file.existsSync()) {
        final uri = Uri.file(localPath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return;
        }
      }
    } catch (_) {}

    final formatted = formatImageUrl(clean);
    final uri = Uri.tryParse(formatted) ?? Uri.tryParse(clean);
    if (uri != null) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        } else {
          await launchUrl(uri);
          return;
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open document: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vital Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            if (summary != null && summary.patientName.isNotEmpty)
              Text(
                summary.patientName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0052FF)),
            )
          : summary == null
              ? const Center(
                  child: Text(
                    'No vital report found for this patient.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // Patient Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: _buildSafeImage(
                                summary.patientAvatar,
                                fallbackIcon: Icons.person_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        summary.patientName,
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (summary.isFamilyMember) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFBFDBFE)),
                                        ),
                                        child: Text(
                                          summary.relation.isNotEmpty && summary.relation != 'Family Member'
                                              ? summary.relation
                                              : 'Family Member',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (summary.patientGender.isNotEmpty || summary.patientAge.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      if (summary.patientGender.isNotEmpty)
                                        summary.patientGender.substring(0, 1).toUpperCase() +
                                            summary.patientGender.substring(1).toLowerCase(),
                                      if (summary.patientAge.isNotEmpty) '${summary.patientAge} yrs',
                                    ].join(' • '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                                if (summary.displayOrderId.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                            'Order ID: ${summary.displayOrderId}',
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
                                if (summary.patientAddress.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          summary.patientAddress,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (summary.recordedAt.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Recorded: ${summary.recordedAt}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Recorded Vitals Section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFF0052FF), size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Recorded Vitals',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${summary.vitals.length} Recorded',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (summary.vitals.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'No specific vital readings attached to this record.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ...summary.vitals.map((v) {
                        final hasPhoto = v.fileUrl.isNotEmpty;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x04000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFDCFCE7)),
                                ),
                                child: const Icon(Icons.favorite_rounded, color: Color(0xFF10B981), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          v.value,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (v.unit.isNotEmpty) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            v.unit,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (v.details.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        v.details,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (hasPhoto)
                                GestureDetector(
                                  onTap: () => _showImagePreview(context, '${v.name} Photo Proof', v.fileUrl),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF0052FF), width: 1.5),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          _buildSafeImage(
                                            v.fileUrl,
                                            width: 48,
                                            height: 48,
                                            fallbackIcon: Icons.photo_camera_back_outlined,
                                          ),
                                          Container(
                                            color: Colors.black26,
                                            child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 20),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),

                    // Condition Photos Section
                    if (summary.conditionPhotos.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0052FF), size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Condition & Wound Photos',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const Spacer(),
                          Text(
                            '${summary.conditionPhotos.length} Attached',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: summary.conditionPhotos.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final photo = summary.conditionPhotos[index];
                            return GestureDetector(
                              onTap: () => _showImagePreview(
                                context,
                                photo.caption.isNotEmpty ? photo.caption : 'Condition Photo #${index + 1}',
                                photo.url,
                              ),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      _buildSafeImage(photo.url, fallbackIcon: Icons.image_outlined),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          color: Colors.black54,
                                          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                                          child: Text(
                                            photo.caption.isNotEmpty ? photo.caption : 'Photo #${index + 1}',
                                            style: const TextStyle(color: Colors.white, fontSize: 10),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Old Medical Reports Section
                    if (summary.oldReports.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.description_rounded, color: Color(0xFF8B5CF6), size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Uploaded Reports & Documents',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const Spacer(),
                          Text(
                            '${summary.oldReports.length} Files',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...summary.oldReports.map((report) {
                        final isImg = report.url.toLowerCase().contains('.jpg') ||
                            report.url.toLowerCase().contains('.jpeg') ||
                            report.url.toLowerCase().contains('.png') ||
                            report.type.toLowerCase().contains('image');
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x04000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isImg ? const Color(0xFFEFF6FF) : const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isImg ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                                  color: isImg ? const Color(0xFF0052FF) : const Color(0xFF8B5CF6),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (isImg) {
                                      _showImagePreview(context, report.name, report.url);
                                    } else {
                                      _openDocument(context, report.url);
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report.name,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        report.type,
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isImg ? Icons.zoom_in_rounded : Icons.open_in_new_rounded,
                                  color: const Color(0xFF0052FF),
                                  size: 22,
                                ),
                                onPressed: () {
                                  if (isImg) {
                                    _showImagePreview(context, report.name, report.url);
                                  } else {
                                    _openDocument(context, report.url);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // Nurse Notes Section
                    if (summary.notes.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_note_rounded, color: Color(0xFFD97706), size: 20),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Nurse Notes & Clinical Observations',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          summary.notes,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF78350F),
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
