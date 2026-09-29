import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:howpa_nurse/core/network/api_exceptions.dart';
import 'package:howpa_nurse/features/visits/data/models/visit_models.dart';
import 'package:howpa_nurse/features/visits/data/repositories/visits_repository.dart';

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

class UpdateVitalsScreen extends StatefulWidget {
  final String appointmentId;
  final String patientName;
  final String avatarUrl;

  const UpdateVitalsScreen({
    super.key,
    this.appointmentId = '',
    required this.patientName,
    required this.avatarUrl,
  });

  @override
  State<UpdateVitalsScreen> createState() => _UpdateVitalsScreenState();
}

class _UpdateVitalsScreenState extends State<UpdateVitalsScreen> {
  final ImagePicker _picker = ImagePicker();

  // Selected cause indices (Set allows selecting multiple causes like Fever, Vomiting, Cold & Cough, etc.)
  final Set<int> _selectedCauseIndices = {};
  bool _isSaving = false;

  // Controllers for Other cause details and vitals inputs (empty by default)
  final TextEditingController _otherCauseController = TextEditingController();
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _hrController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _sugarController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Map to store proof images for each vital field
  final Map<String, XFile> _vitalImages = {};

  // List of uploaded condition images (wounds, swelling, rashes, etc.)
  final List<XFile> _conditionImages = [];

  // List of uploaded old reports / documents
  final List<ReportFileItem> _oldReports = [];

  // Custom vitals added by the nurse (type, value, unit)
  final List<Map<String, String>> _customVitals = [];

  // Available vital type suggestions for the dropdown
  static const List<Map<String, String>> _vitalSuggestions = [
    {'label': 'Respiratory Rate', 'unit': 'bpm', 'icon': '🫁'},
    {'label': 'Pain Scale', 'unit': '/10', 'icon': '😣'},
    {'label': 'Waist Circumference', 'unit': 'cm', 'icon': '📏'},
    {'label': 'BMI', 'unit': 'kg/m²', 'icon': '⚖️'},
    {'label': 'Blood Oxygen', 'unit': '%', 'icon': '🩸'},
    {'label': 'Pulse Pressure', 'unit': 'mmHg', 'icon': '💓'},
    {'label': 'Urine Output', 'unit': 'ml', 'icon': '🧪'},
    {'label': 'GRBS', 'unit': 'mg/dL', 'icon': '💉'},
    {'label': 'Custom', 'unit': '', 'icon': '➕'},
  ];

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

  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _bpController.addListener(_validateForm);
    _hrController.addListener(_validateForm);
    _tempController.addListener(_validateForm);
  }

  void _validateForm() {
    final isValid = _bpController.text.trim().isNotEmpty &&
        _hrController.text.trim().isNotEmpty &&
        _tempController.text.trim().isNotEmpty;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _otherCauseController.dispose();
    _bpController.dispose();
    _hrController.dispose();
    _tempController.dispose();
    _sugarController.dispose();
    _spo2Controller.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddVitalDialog() {
    String selectedType = '';
    final typeController = TextEditingController();
    final valueController = TextEditingController();
    final unitController = TextEditingController();
    XFile? pickedImage;

    Future<void> pickImage(
        ImageSource source, void Function(void Function()) setModalState) async {
      try {
        final image = await _picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        if (image != null) {
          setModalState(() => pickedImage = image);
        }
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Text(
                        'Add a Vital',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose a vital type, enter value & optionally upload an image',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      // Quick-select chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _vitalSuggestions.map((s) {
                          final isSelected = selectedType == s['label'];
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedType = s['label']!;
                                if (s['label'] != 'Custom') {
                                  typeController.text = s['label']!;
                                  unitController.text = s['unit']!;
                                } else {
                                  typeController.clear();
                                  unitController.clear();
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0052FF)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0052FF)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                '${s['icon']} ${s['label']}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Type field
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: typeController,
                          style: const TextStyle(fontSize: 14),
                          onChanged: (v) => setModalState(() => selectedType = v),
                          decoration: const InputDecoration(
                            hintText: 'Vital type (e.g. Respiratory Rate)',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                            prefixIcon: Icon(Icons.medical_services_outlined,
                                color: Color(0xFF0052FF), size: 20),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: TextField(
                                controller: valueController,
                                keyboardType:
                                    TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Value',
                                  hintStyle:
                                      TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                                  prefixIcon: Icon(Icons.edit_outlined,
                                      color: Color(0xFF0052FF), size: 18),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 13),
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
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: TextField(
                                controller: unitController,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Unit',
                                  hintStyle:
                                      TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 13),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Photo Proof Section ──
                      const Text(
                        'Photo Proof (optional)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (pickedImage == null)
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    pickImage(ImageSource.camera, setModalState),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.camera_alt_rounded,
                                          color: Color(0xFF0052FF), size: 26),
                                      SizedBox(height: 5),
                                      Text(
                                        'Camera',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0052FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    pickImage(ImageSource.gallery, setModalState),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.photo_library_rounded,
                                          color: Color(0xFF10B981), size: 26),
                                      SizedBox(height: 5),
                                      Text(
                                        'Gallery',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: double.infinity,
                                height: 150,
                                child: _buildSafeImage(pickedImage!.path,
                                    fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => setModalState(() => pickedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    pickImage(ImageSource.gallery, setModalState),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_rounded,
                                          color: Colors.white, size: 13),
                                      SizedBox(width: 4),
                                      Text('Change',
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final type = typeController.text.trim();
                            final value = valueController.text.trim();
                            final unit = unitController.text.trim();
                            if (type.isNotEmpty && value.isNotEmpty) {
                              setState(() {
                                _customVitals.add({
                                  'type': type,
                                  'value': value,
                                  'unit': unit,
                                  'imagePath': pickedImage?.path ?? '',
                                });
                              });
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text(
                            'Add Vital',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
      final file = File(path);
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

  // Pick Image Helper for Vital Proofs
  Future<void> _pickVitalImage(String vitalTitle) async {
    try {
      final source = await _showSourceSelectionModal(
        title: 'Upload Proof for $vitalTitle',
      );
      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (image != null && mounted) {
        final file = File(image.path);
        if (file.existsSync()) {
          setState(() {
            _vitalImages[vitalTitle] = image;
          });
        }
      }
    } catch (e) {
      debugPrint('Vital image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  // Pick Image Helper for Condition (Wounds / Swelling)
  Future<void> _addConditionImage() async {
    try {
      final source = await _showSourceSelectionModal(
        title: 'Upload Patient Condition Image',
        subtitle: 'Capture or select photos of wounds, swelling, or physical observations.',
      );
      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (image != null && mounted) {
        final file = File(image.path);
        if (file.existsSync()) {
          setState(() {
            _conditionImages.add(image);
          });
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

  // Pick Old Medical Reports (Images or Files)
  Future<void> _addOldReport() async {
    showModalBottomSheet(
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
                const Text(
                  'Upload Old Report / Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Upload past medical records, lab reports, or prescriptions.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0052FF)),
                  ),
                  title: const Text('Take Photo of Report', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Use camera to capture document'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    try {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 70,
                      );
                      if (image != null && mounted) {
                        setState(() {
                          _oldReports.add(ReportFileItem(
                            name: 'Report Photo (${_oldReports.length + 1}).jpg',
                            path: image.path,
                            isImage: true,
                          ));
                        });
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
                  subtitle: const Text('Select image file from device'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    try {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
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
                  subtitle: const Text('Select file from device storage'),
                  onTap: () async {
                    Navigator.pop(context);
                    final messenger = ScaffoldMessenger.of(context);
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

  // Source selection bottom sheet (Camera vs Gallery) returning ImageSource safely
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
                          child: Column(
                            children: const [
                              Icon(Icons.camera_alt_rounded, color: Color(0xFF0052FF), size: 32),
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
                          child: Column(
                            children: const [
                              Icon(Icons.photo_library_rounded, color: Color(0xFF10B981), size: 32),
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
                                'Select existing',
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

  @override
  Widget build(BuildContext context) {
    final bool isOtherSelected = _selectedCauseIndices.any(
      (idx) => idx < _causes.length && _causes[idx]['title'] == 'Other',
    );

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
          'Update Vitals',
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
                  // Patient Info Card
                  Container(
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
                        // Avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              widget.avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_rounded, color: Color(0xFF64748B)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Details
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
                              const SizedBox(height: 3),
                              const Text(
                                'Age: 68 Years  •  Female',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: const [
                                  Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF0052FF)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Today, 10:42 AM',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
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

                  const SizedBox(height: 20),

                  // Cause / Reason Section Header
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

                  // Grid of Causes (Supports Multi-Selection)
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

                  const SizedBox(height: 24),

                  // Update Vitals List Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Update Vitals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '📷 Add photo proof per field',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildVitalRow(
                    title: 'Blood Pressure',
                    icon: Icons.favorite_border_rounded,
                    iconColor: const Color(0xFFEF4444),
                    iconBgColor: const Color(0xFFFEE2E2),
                    isRequired: true,
                    controller: _bpController,
                    hintText: '120/80',
                    unit: 'mmHg',
                  ),
                  _buildVitalRow(
                    title: 'Heart Rate',
                    icon: Icons.monitor_heart_outlined,
                    iconColor: const Color(0xFFEC4899),
                    iconBgColor: const Color(0xFFFCE7F3),
                    isRequired: true,
                    controller: _hrController,
                    hintText: '78',
                    unit: 'bpm',
                  ),
                  _buildVitalRow(
                    title: 'Temperature',
                    icon: Icons.thermostat_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    iconBgColor: const Color(0xFFDBEAFE),
                    isRequired: true,
                    controller: _tempController,
                    hintText: '98.6',
                    unit: '°F',
                  ),
                  _buildVitalRow(
                    title: 'Blood Sugar',
                    icon: Icons.water_drop_outlined,
                    iconColor: const Color(0xFFEF4444),
                    iconBgColor: const Color(0xFFFEE2E2),
                    isRequired: false,
                    controller: _sugarController,
                    hintText: '110',
                    unit: 'mg/dL',
                  ),
                  _buildVitalRow(
                    title: 'SpO2',
                    icon: Icons.bloodtype_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    iconBgColor: const Color(0xFFDBEAFE),
                    isRequired: false,
                    controller: _spo2Controller,
                    hintText: '98',
                    unit: '%',
                  ),
                  _buildVitalRow(
                    title: 'Weight',
                    icon: Icons.scale_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBgColor: const Color(0xFFEDE9FE),
                    isRequired: false,
                    controller: _weightController,
                    hintText: '65',
                    unit: 'kg',
                  ),

                  const SizedBox(height: 16),

                  // Custom Vitals list
                  if (_customVitals.isNotEmpty) ..._customVitals.asMap().entries.map((entry) {
                    final i = entry.key;
                    final v = entry.value;
                    final hasImage = (v['imagePath'] ?? '').isNotEmpty;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFD7FF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row: icon + label + value + delete
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0052FF).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.add_chart_rounded,
                                      color: Color(0xFF0052FF), size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v['type'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF475569),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${v['value']} ${v['unit']}'.trim(),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      size: 18, color: Color(0xFF94A3B8)),
                                  onPressed: () =>
                                      setState(() => _customVitals.removeAt(i)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          // Image thumbnail (if available)
                          if (hasImage)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(11)),
                              child: SizedBox(
                                width: double.infinity,
                                height: 120,
                                child: _buildSafeImage(v['imagePath']!,
                                    fit: BoxFit.cover),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),


                  // Add a Vital Button
                  GestureDetector(
                    onTap: _showAddVitalDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0052FF).withValues(alpha: 0.35),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0052FF), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add a Vital',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0052FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Notes Section
                  const Text(
                    'Notes',
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
                    child: Stack(
                      children: [
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: "Enter notes about the patient's condition...",
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 1. Physical Condition Photos (Wound, Swelling, Rashes, etc.) Section
                  _buildConditionPhotosSection(),

                  const SizedBox(height: 24),

                  // 2. Old Reports & Medical Records Section
                  _buildOldReportsSection(),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Container(
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
                  onPressed: (_isFormValid && !_isSaving)
                      ? () async {
                          setState(() {
                            _isSaving = true;
                          });

                          try {
                            final vitalImagesMap = _vitalImages.map((key, xfile) => MapEntry(key, xfile.path));
                            final conditionImagePaths = _conditionImages.map((xfile) => xfile.path).toList();
                            final reportFilePaths = _oldReports.map((r) => r.path).toList();

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
                                : 'Clinical Vitals Record';

                            final cleanBp = _bpController.text.trim().replaceAll('mmHg', '').trim();

                            final success = await VisitsRepositoryImpl().recordPatientVitals(
                              RecordVitalsRequest(
                                appointmentId: widget.appointmentId.isNotEmpty
                                    ? widget.appointmentId
                                    : '6730c451b2a3c4d5e6f70819',
                                bloodPressure: cleanBp.isNotEmpty ? cleanBp : '120/80',
                                heartRate: int.tryParse(_hrController.text.trim()) ?? 74,
                                temperature: double.tryParse(_tempController.text.trim()) ?? 98.4,
                                bloodSugar: int.tryParse(_sugarController.text.trim()) ?? 110,
                                spo2: int.tryParse(_spo2Controller.text.trim()) ?? 99,
                                weight: double.tryParse(_weightController.text.trim()) ?? 68.0,
                                reason: reasonString,
                                notes: _notesController.text.trim().isNotEmpty
                                    ? _notesController.text.trim()
                                    : 'Patient is stable.',
                                vitalImages: vitalImagesMap,
                                conditionImages: conditionImagePaths,
                                oldReportFiles: reportFilePaths,
                                customVitals: _customVitals.isNotEmpty ? _customVitals : null,
                              ),
                            );

                            if (!context.mounted) return;

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vitals, photos & reports updated successfully!'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to record vitals. Please try again.'),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                            }
                          } on ApiException catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.message),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: const Color(0xFFEF4444),
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
                      : null,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(Icons.note_add_outlined, size: 22, color: _isFormValid ? Colors.white : Colors.white70),
                  label: Text(
                    _isSaving ? 'Updating...' : 'Update Vitals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isFormValid ? Colors.white : Colors.white70,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052FF),
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vital Field Row Widget with Integrated Image Upload Button / Proof Badge
  Widget _buildVitalRow({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool isRequired,
    required TextEditingController controller,
    required String hintText,
    required String unit,
  }) {
    final XFile? proofImage = _vitalImages[title];
    final bool hasImage = proofImage != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon Box
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              // Title & Required Asterisk
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isRequired)
                      const Text(
                        ' *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // TextField
              Container(
                width: 78,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Unit Label
              SizedBox(
                width: 44,
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Image Upload Button or Thumbnail Badge
              if (!hasImage)
                Tooltip(
                  message: 'Upload proof photo for $title',
                  child: InkWell(
                    onTap: () => _pickVitalImage(title),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: Color(0xFF0052FF),
                        size: 19,
                      ),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    _showImagePreviewDialog(
                      title: '$title Proof Image',
                      imagePath: proofImage.path,
                      onDelete: () {
                        setState(() {
                          _vitalImages.remove(title);
                        });
                      },
                    );
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _buildSafeImage(proofImage.path, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Physical Condition Photos Section Widget (Wound, Swelling, Rashes)
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Wound / Swelling / Condition Photos',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Upload photos if patient has wounds, swelling, rashes, etc.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Upload Button & Image Grid
          if (_conditionImages.isEmpty)
            OutlinedButton.icon(
              onPressed: _addConditionImage,
              icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0052FF), size: 20),
              label: const Text(
                'Upload Condition Photo',
                style: TextStyle(color: Color(0xFF0052FF), fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: const BorderSide(color: Color(0xFF0052FF), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          else ...[
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _conditionImages.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == _conditionImages.length) {
                    // Add more button
                    return InkWell(
                      onTap: _addConditionImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_outlined, color: Color(0xFF0052FF), size: 24),
                            SizedBox(height: 4),
                            Text('Add More', style: TextStyle(fontSize: 11, color: Color(0xFF0052FF), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }

                  final xfile = _conditionImages[index];
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showImagePreviewDialog(
                            title: 'Condition Photo #${index + 1}',
                            imagePath: xfile.path,
                            onDelete: () {
                              setState(() {
                                _conditionImages.removeAt(index);
                              });
                            },
                          );
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
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
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
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

  // Patient Old Reports & Medical Documents Section Widget
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Patient Old Reports & Records',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Upload past lab reports, prescriptions, or medical documents.',
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
              'Upload Old Report',
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
}
