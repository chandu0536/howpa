import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:howpa_nurse/features/visits/data/models/visit_models.dart';
import 'package:howpa_nurse/features/visits/data/repositories/visits_repository.dart';
import 'package:howpa_nurse/features/vitals/data/models/vitals_details_model.dart';

class ReportFileItem {
  final String name;
  final String path;
  final bool isImage;

  ReportFileItem({
    required this.name,
    required this.path,
    required this.isImage,
  });
}

class DynamicVitalController {
  final TextEditingController nameController;
  final TextEditingController valueController;
  final TextEditingController unitController;
  File? meterPhoto;

  DynamicVitalController({
    String name = '',
    String value = '',
    String unit = '',
    this.meterPhoto,
  })  : nameController = TextEditingController(text: name),
        valueController = TextEditingController(text: value),
        unitController = TextEditingController(text: unit);

  void dispose() {
    nameController.dispose();
    valueController.dispose();
    unitController.dispose();
  }
}

class UpdateVitalsScreen extends StatefulWidget {
  final String appointmentId;
  final String? orderId;
  final String patientName;
  final String avatarUrl;
  final String? patientAge;
  final String? patientGender;
  final DateTime? scheduledDate;
  final String? time;
  final List<BookedServiceItem> bookedServices;

  const UpdateVitalsScreen({
    super.key,
    this.appointmentId = '',
    this.orderId,
    required this.patientName,
    required this.avatarUrl,
    this.patientAge,
    this.patientGender,
    this.scheduledDate,
    this.time,
    this.bookedServices = const [],
  });

  @override
  State<UpdateVitalsScreen> createState() => _UpdateVitalsScreenState();
}

class _UpdateVitalsScreenState extends State<UpdateVitalsScreen> {
  final ImagePicker _picker = ImagePicker();

  // Selected cause indices (multi-selection)
  final Set<int> _selectedCauseIndices = {};
  final TextEditingController _otherCauseController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // 100% Dynamic Vitals List (Zero Hardcoded / Zero Defaults on load)
  final List<DynamicVitalController> _vitalsList = [];

  // Quick vital suggestion chips for fast auto-fill
  static const List<Map<String, String>> _quickChips = [
    {'name': 'Blood Pressure', 'short': 'BP', 'unit': 'mmHg', 'hint': '120/80', 'icon': '🫀'},
    {'name': 'Pulse / Heart Rate', 'short': 'Pulse', 'unit': 'bpm', 'hint': '72', 'icon': '💓'},
    {'name': 'Blood Glucose (Sugar)', 'short': 'Sugar', 'unit': 'mg/dL', 'hint': '110', 'icon': '🩸'},
    {'name': 'SpO2 (Oxygen)', 'short': 'SpO2', 'unit': '%', 'hint': '98', 'icon': '💨'},
    {'name': 'Temperature', 'short': 'Temp', 'unit': '°F', 'hint': '98.6', 'icon': '🌡️'},
    {'name': 'Body Weight', 'short': 'Weight', 'unit': 'kg', 'hint': '65', 'icon': '⚖️'},
  ];

  // Causes list
  final List<Map<String, dynamic>> _causes = [
    {'title': 'Fever', 'icon': Icons.thermostat_rounded, 'color': const Color(0xFF0052FF)},
    {'title': 'Diarrhea', 'icon': Icons.wc_rounded, 'color': const Color(0xFF64748B)},
    {'title': 'Vomiting', 'icon': Icons.sick_outlined, 'color': const Color(0xFF10B981)},
    {'title': 'Cold & Cough', 'icon': Icons.masks_outlined, 'color': const Color(0xFF8B5CF6)},
    {'title': 'Headache', 'icon': Icons.face_retouching_natural_rounded, 'color': const Color(0xFFEF4444)},
    {'title': 'Body Pain', 'icon': Icons.accessibility_new_rounded, 'color': const Color(0xFFF97316)},
    {'title': 'Fatigue', 'icon': Icons.bedtime_outlined, 'color': const Color(0xFF8B5CF6)},
    {'title': 'Other', 'icon': Icons.more_horiz_rounded, 'color': const Color(0xFF64748B)},
  ];

  // List of uploaded condition images (wounds, swelling, rashes)
  final List<XFile> _conditionImages = [];

  // List of uploaded old reports / documents
  final List<ReportFileItem> _oldReports = [];

  bool _isSaving = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _checkLostImageData();
    _notesController.addListener(_validateForm);
  }

  void _validateForm() {
    // Form is valid if at least 1 vital has name & value, OR notes entered, OR condition image uploaded
    final hasValidVital = _vitalsList.any((v) =>
        v.nameController.text.trim().isNotEmpty &&
        v.valueController.text.trim().isNotEmpty);
    final hasNotes = _notesController.text.trim().isNotEmpty;
    final hasConditionPhoto = _conditionImages.isNotEmpty;
    final hasReports = _oldReports.isNotEmpty;

    final isValid = hasValidVital || hasNotes || hasConditionPhoto || hasReports;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _addNewVital({String name = '', String unit = ''}) {
    final controller = DynamicVitalController(name: name, unit: unit);
    controller.nameController.addListener(_validateForm);
    controller.valueController.addListener(_validateForm);
    controller.unitController.addListener(_validateForm);
    setState(() {
      _vitalsList.add(controller);
    });
    _validateForm();
  }

  void _removeVital(int index) {
    if (index >= 0 && index < _vitalsList.length) {
      setState(() {
        final removed = _vitalsList.removeAt(index);
        removed.dispose();
      });
      _validateForm();
    }
  }

  Future<void> _checkLostImageData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      final file = response.file;
      if (file != null && mounted) {
        final f = File(file.path);
        if (f.existsSync()) {
          setState(() {
            _conditionImages.add(file);
          });
          _validateForm();
        }
      }
    } catch (e) {
      debugPrint('Error retrieving lost vitals image data: $e');
    }
  }

  @override
  void dispose() {
    _otherCauseController.dispose();
    _notesController.dispose();
    for (final v in _vitalsList) {
      v.dispose();
    }
    super.dispose();
  }

  // Safe image builder to prevent crashes on invalid/missing image files
  Widget _buildSafeImage(String path, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (path.isEmpty) {
      return Container(
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
      );
    }
    if (kIsWeb || path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F5F9),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
        ),
      );
    }
    try {
      final localPath = path.startsWith('file://') ? path.substring(7) : path;
      final file = File(localPath);
      if (!file.existsSync()) {
        return Container(
          color: const Color(0xFFF1F5F9),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
        );
      }
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: width != null ? (width * 2.5).toInt().clamp(50, 800) : 400,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F5F9),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
        ),
      );
    } catch (_) {
      return Container(
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
      );
    }
  }

  // Pick Meter Photo for a specific Vital Card
  Future<void> _pickMeterPhoto(DynamicVitalController vital) async {
    try {
      final source = await _showSourceSelectionModal(
        title: 'Capture Meter Screen Photo',
        subtitle: 'Photograph the device meter reading (BP, Glucometer, Pulse Oximeter, etc.)',
      );
      if (source == null) return;
      await Future.delayed(const Duration(milliseconds: 150));

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (image != null && mounted) {
        final file = File(image.path);
        if (file.existsSync()) {
          setState(() {
            vital.meterPhoto = file;
          });
          _validateForm();
        }
      }
    } catch (e) {
      debugPrint('Error picking meter photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  // Pick Image Helper for Condition (Wounds / Swelling)
  Future<void> _addConditionImage() async {
    try {
      final source = await _showSourceSelectionModal(
        title: 'Upload Patient Condition Image',
        subtitle: 'Capture or select photos of wounds, swelling, rashes, or dressings.',
      );
      if (source == null) return;
      await Future.delayed(const Duration(milliseconds: 150));

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (image != null && mounted) {
        final file = File(image.path);
        if (file.existsSync()) {
          setState(() {
            _conditionImages.add(image);
          });
          _validateForm();
        }
      }
    } catch (e) {
      debugPrint('Condition image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  // Pick Old Medical Reports (Images or PDF/DOC files)
  Future<void> _addOldReport() async {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const Text(
                  'Upload Medical Report / Prescription',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0052FF)),
                  ),
                  title: const Text('Capture with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Photograph paper prescription or lab sheet'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 150));
                    try {
                      PaintingBinding.instance.imageCache.clear();
                      PaintingBinding.instance.imageCache.clearLiveImages();
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 900,
                        maxHeight: 900,
                        imageQuality: 70,
                      );
                      if (image != null && mounted) {
                        setState(() {
                          _oldReports.add(ReportFileItem(
                            name: image.name.isNotEmpty ? image.name : 'Report Photo.jpg',
                            path: image.path,
                            isImage: true,
                          ));
                        });
                        _validateForm();
                      }
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to take photo: $e')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981)),
                  ),
                  title: const Text('Choose Image from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select image file from device storage'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 150));
                    try {
                      PaintingBinding.instance.imageCache.clear();
                      PaintingBinding.instance.imageCache.clearLiveImages();
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 900,
                        maxHeight: 900,
                        imageQuality: 70,
                      );
                      if (image != null && mounted) {
                        setState(() {
                          _oldReports.add(ReportFileItem(
                            name: image.name.isNotEmpty ? image.name : 'Report Image.jpg',
                            path: image.path,
                            isImage: true,
                          ));
                        });
                        _validateForm();
                      }
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to pick image: $e')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF8B5CF6)),
                  ),
                  title: const Text('Pick Document File (PDF / DOC)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select PDF or document file from storage'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
                      );
                      if (result != null && result.files.isNotEmpty) {
                        final file = result.files.first;
                        if (file.path != null && mounted) {
                          final isImg = ['jpg', 'jpeg', 'png'].contains(file.extension?.toLowerCase());
                          setState(() {
                            _oldReports.add(ReportFileItem(
                              name: file.name,
                              path: file.path!,
                              isImage: isImg,
                            ));
                          });
                          _validateForm();
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error selecting file: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Source selection bottom sheet (Camera vs Gallery)
  Future<ImageSource?> _showSourceSelectionModal({
    required String title,
    String? subtitle,
  }) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, ImageSource.camera),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.camera_alt_rounded, color: Color(0xFF0052FF), size: 30),
                              SizedBox(height: 8),
                              Text(
                                'Camera',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0052FF),
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Take new photo',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, ImageSource.gallery),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.photo_library_rounded, color: Color(0xFF10B981), size: 30),
                              SizedBox(height: 8),
                              Text(
                                'Gallery',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Select from device',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
          ),
        );
      },
    );
  }

  // Full Screen Image Preview Modal
  void _showImagePreviewDialog({
    required String title,
    required String imagePath,
    VoidCallback? onDelete,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 380),
                        width: double.infinity,
                        color: Colors.black,
                        child: _buildSafeImage(imagePath, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (onDelete != null)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  label: const Text('Delete Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitScreening() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Build List of Dynamic Vital Items
      final List<DynamicVitalItem> dynamicVitals = _vitalsList
          .where((v) =>
              v.nameController.text.trim().isNotEmpty &&
              v.valueController.text.trim().isNotEmpty)
          .map((v) => DynamicVitalItem(
                name: v.nameController.text.trim(),
                value: v.valueController.text.trim(),
                unit: v.unitController.text.trim(),
                meterPhoto: v.meterPhoto,
              ))
          .toList();

      // 2. Reason string from selected causes
      final selectedCausesList = _selectedCauseIndices
          .where((i) => i < _causes.length)
          .map((i) {
            if (_causes[i]['title'] == 'Other' && _otherCauseController.text.trim().isNotEmpty) {
              return _otherCauseController.text.trim();
            }
            return _causes[i]['title'] as String;
          })
          .where((s) => s.isNotEmpty)
          .toList();
      final reasonString = selectedCausesList.isNotEmpty
          ? selectedCausesList.join(', ')
          : 'Clinical Screening & Vitals';

      // 3. Condition photos and old reports
      final conditionImagePaths = _conditionImages.map((x) => x.path).toList();
      final reportFilePaths = _oldReports.map((r) => r.path).toList();

      final notesText = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : 'Clinical screening completed.';

      final requestId = widget.appointmentId.isNotEmpty
          ? widget.appointmentId
          : '6730c451b2a3c4d5e6f70819';

      // 4. Submit to Repository (updates local state & posts multipart payload)
      await VisitsRepositoryImpl().submitNurseScreening(
        requestId: requestId,
        notes: notesText,
        reason: reasonString,
        vitals: dynamicVitals,
        conditionImages: conditionImagePaths,
        oldReportFiles: reportFilePaths,
      );

      // 5. Construct PatientVitalsSummary with all local photos for immediate view
      final vitalEntries = dynamicVitals.map((dv) {
        return VitalItemEntry(
          name: dv.name,
          value: dv.value,
          unit: dv.unit,
          details: 'Nurse Measured Vital',
          status: 'Normal',
          fileUrl: dv.meterPhoto?.path ?? '',
        );
      }).toList();

      final conditionEntries = conditionImagePaths.map((p) {
        return ConditionPhotoEntry(
          url: p,
          caption: 'Condition Observation',
        );
      }).toList();

      final reportEntries = _oldReports.map((r) {
        return OldReportEntry(
          url: r.path,
          name: r.name,
          type: r.isImage ? 'Medical Image' : 'PDF Report',
        );
      }).toList();

      final summary = PatientVitalsSummary(
        id: widget.appointmentId.isNotEmpty ? widget.appointmentId : requestId,
        requestId: requestId,
        appointmentId: widget.appointmentId,
        orderId: widget.orderId,
        patientName: widget.patientName,
        patientAvatar: widget.avatarUrl,
        patientAge: widget.patientAge ?? '',
        patientGender: widget.patientGender ?? '',
        vitals: vitalEntries,
        conditionPhotos: conditionEntries,
        oldReports: reportEntries,
        notes: notesText,
        recordedAt: 'Today • Just now',
      );

      // Save summary in repository cache for fast offline/online lookup
      VisitsRepositoryImpl.saveVitalsSummary(summary);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vitals and screening submitted successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, summary);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit screening: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOtherSelected = _selectedCauseIndices.any(
      (idx) => idx < _causes.length && _causes[idx]['title'] == 'Other',
    );

    // Formatted demographics
    final demographics = formatDemographics(
      gender: widget.patientGender,
      age: widget.patientAge,
    );

    // Formatted appointment date/time
    String appointmentTimeText = '';
    if (widget.time != null && widget.time!.isNotEmpty) {
      appointmentTimeText = widget.time!;
    } else if (widget.scheduledDate != null) {
      final d = widget.scheduledDate!;
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yyyy = d.year.toString();
      appointmentTimeText = '$dd-$mm-$yyyy';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Update Vitals & Screening',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Patient Profile Card
                  _buildPatientProfileCard(demographics, appointmentTimeText),

                  // 2. Booked Nursing Services Card (100% Dynamic, Zero Defaults)
                  if (widget.bookedServices.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _buildBookedServicesCard(),
                  ],

                  const SizedBox(height: 20),

                  // 3. Cause / Reason Section
                  _buildCausesSection(isOtherSelected),

                  const SizedBox(height: 24),

                  // 4. Dynamic Vitals Section (Starts 0 Vitals - Zero Defaults)
                  _buildDynamicVitalsSection(),

                  const SizedBox(height: 24),

                  // 5. Clinical Observations / Notes
                  _buildNotesSection(),

                  const SizedBox(height: 24),

                  // 6. Wound / Swelling / Condition Photos
                  _buildConditionPhotosSection(),

                  const SizedBox(height: 24),

                  // 7. Old Medical Reports & Prescriptions
                  _buildOldReportsSection(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          _buildBottomSubmitBar(),
        ],
      ),
    );
  }

  // 1. Patient Profile Card
  Widget _buildPatientProfileCard(String demographics, String appointmentTimeText) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: ClipOval(
              child: _buildAvatar(widget.avatarUrl, widget.patientName, 52),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.orderId != null && widget.orderId!.isNotEmpty) ...[
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
                          'Order ID: ${widget.orderId}',
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
                const SizedBox(height: 3),
                Text(
                  demographics,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (appointmentTimeText.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF0052FF)),
                      const SizedBox(width: 4),
                      Text(
                        appointmentTimeText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
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
    );
  }

  // 2. Booked Nursing Services Card (Zero Defaults, 100% Dynamic)
  Widget _buildBookedServicesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0052FF), size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Booked Nursing Services',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.bookedServices.length} Service${widget.bookedServices.length > 1 ? "s" : ""}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0052FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.bookedServices.map((service) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  if (service.imageUrl != null && service.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: _buildSafeImage(service.imageUrl!),
                      ),
                    )
                  else
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medical_services_outlined, color: Color(0xFF0052FF), size: 22),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (service.description != null && service.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            service.description!,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (service.price != null && service.price! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        '₹${service.price!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 3. Causes / Reasons Section
  Widget _buildCausesSection(bool isOtherSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Cause / Reason',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Select multiple',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0052FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemCount: _causes.length,
          itemBuilder: (context, index) {
            final cause = _causes[index];
            final isSelected = _selectedCauseIndices.contains(index);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCauseIndices.remove(index);
                  } else {
                    _selectedCauseIndices.add(index);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0052FF) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cause['icon'] as IconData,
                            color: isSelected ? const Color(0xFF0052FF) : (cause['color'] as Color),
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cause['title'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF0052FF) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0052FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, size: 11, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (isOtherSelected) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0052FF), width: 1.2),
            ),
            child: TextField(
              controller: _otherCauseController,
              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
              decoration: const InputDecoration(
                hintText: 'Type cause / reason details...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                prefixIcon: Icon(Icons.edit_note_rounded, color: Color(0xFF0052FF)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 4. Dynamic Vitals Recording Section (Starts Empty, 0 Defaults)
  Widget _buildDynamicVitalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Record Vitals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (_vitalsList.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_vitalsList.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            TextButton.icon(
              onPressed: () => _addNewVital(),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF0052FF)),
              label: const Text(
                'Add Vital',
                style: TextStyle(
                  color: Color(0xFF0052FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),

        // Quick shortcut chips bar to easily add popular vitals with one tap
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickChips.map((chip) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: Text(chip['icon']!, style: const TextStyle(fontSize: 13)),
                  label: Text(
                    chip['short']!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _addNewVital(
                    name: chip['name']!,
                    unit: chip['unit']!,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // If list is empty: Show clean empty prompt (No static defaults!)
        if (_vitalsList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.monitor_heart_outlined,
                    color: Color(0xFF0052FF),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No Vitals Recorded Yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap "+ Add Vital" or a quick chip above to record BP, Pulse, Sugar, Temp, etc. with meter screen photos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _addNewVital(),
                  icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  label: const Text('Add Vital Card', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052FF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          )
        else
          // Dynamic Vital Cards List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vitalsList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return _buildDynamicVitalCard(_vitalsList[index], index);
            },
          ),

        if (_vitalsList.isNotEmpty) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _addNewVital(),
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0052FF), size: 18),
            label: const Text(
              'Add Another Vital',
              style: TextStyle(color: Color(0xFF0052FF), fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: Color(0xFF0052FF), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ],
    );
  }

  // Single Dynamic Vital Card
  Widget _buildDynamicVitalCard(DynamicVitalController vital, int index) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Vital Title & Trash Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0052FF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    vital.nameController.text.trim().isNotEmpty
                        ? vital.nameController.text.trim()
                        : 'Vital #${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                onPressed: () => _removeVital(index),
                tooltip: 'Remove Vital',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick selection chips to auto-fill this card's name & unit
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickChips.map((chip) {
                final isSelected = vital.nameController.text == chip['name'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        vital.nameController.text = chip['name']!;
                        vital.unitController.text = chip['unit']!;
                      });
                      _validateForm();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0052FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0052FF) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        '${chip['icon']} ${chip['short']}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Vital Name TextField
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: vital.nameController,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              decoration: const InputDecoration(
                labelText: 'Vital Name',
                labelStyle: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                hintText: 'e.g. Blood Pressure, SpO2, Random Glucose...',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Value and Unit Inputs Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: vital.valueController,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      labelText: 'Reading Value',
                      labelStyle: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      hintText: 'e.g. 120/80',
                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: vital.unitController,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      labelStyle: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      hintText: 'mmHg, bpm, etc.',
                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Meter Reading Photo Capture Section
          if (vital.meterPhoto == null) ...[
            InkWell(
              onTap: () => _pickMeterPhoto(vital),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE), style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt_outlined, color: Color(0xFF0052FF), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Capture Meter Screen Photo',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0052FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showImagePreviewDialog(
                      title: '${vital.nameController.text} Meter Photo',
                      imagePath: vital.meterPhoto!.path,
                      onDelete: () {
                        setState(() {
                          vital.meterPhoto = null;
                        });
                        _validateForm();
                      },
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: _buildSafeImage(vital.meterPhoto!.path),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Meter Photo Captured',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tap thumbnail to preview',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickMeterPhoto(vital),
                    child: const Text('Change', style: TextStyle(fontSize: 12, color: Color(0xFF0052FF))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                    onPressed: () {
                      setState(() {
                        vital.meterPhoto = null;
                      });
                      _validateForm();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 5. Clinical Notes Section
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Clinical Notes & Observations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Enter clinical observations, patient condition, or nurse notes...",
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  // 6. Physical Condition Photos Section Widget (Wound, Swelling, Rashes)
  Widget _buildConditionPhotosSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.healing_rounded, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wound / Condition Photos',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Capture photos of wounds, dressing, or skin observations.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action button
          OutlinedButton.icon(
            onPressed: _addConditionImage,
            icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFEF4444), size: 20),
            label: const Text(
              'Add Condition Photo',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          if (_conditionImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _conditionImages.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final xfile = _conditionImages[index];
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showImagePreviewDialog(
                            title: 'Condition Photo ${index + 1}',
                            imagePath: xfile.path,
                            onDelete: () {
                              setState(() {
                                _conditionImages.removeAt(index);
                              });
                              _validateForm();
                            },
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _buildSafeImage(xfile.path, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _conditionImages.removeAt(index);
                            });
                            _validateForm();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 7. Old Medical Reports & Prescriptions Section Widget
  Widget _buildOldReportsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_shared_rounded, color: Color(0xFF8B5CF6), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Past Medical Reports & Documents',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Upload past lab reports, prescriptions, or discharge summaries.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action button
          OutlinedButton.icon(
            onPressed: _addOldReport,
            icon: const Icon(Icons.upload_file_rounded, color: Color(0xFF8B5CF6), size: 20),
            label: const Text(
              'Upload Medical Document',
              style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          if (_oldReports.isNotEmpty) ...[
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _oldReports.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final report = _oldReports[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: report.isImage ? const Color(0xFFEFF6FF) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          report.isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                          color: report.isImage ? const Color(0xFF0052FF) : const Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              report.isImage ? 'Image Document' : 'PDF / Text File',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        onPressed: () {
                          setState(() {
                            _oldReports.removeAt(index);
                          });
                          _validateForm();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // Bottom Submission Button
  Widget _buildBottomSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: (_isFormValid && !_isSaving) ? _submitScreening : null,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Icon(
                    Icons.check_circle_outline_rounded,
                    size: 22,
                    color: _isFormValid ? Colors.white : Colors.white70,
                  ),
            label: Text(
              _isSaving ? 'Submitting Screening...' : 'Update Vitals & Complete Screening',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: _isFormValid ? Colors.white : Colors.white70,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052FF),
              disabledBackgroundColor: const Color(0xFF94A3B8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
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
