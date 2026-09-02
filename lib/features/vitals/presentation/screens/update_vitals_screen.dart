import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/vitals_cubit.dart';
import '../../data/models/vitals_model.dart';

class UpdateVitalsScreen extends StatefulWidget {
  final String appointmentId;
  final String patientName;
  final String avatarUrl;
  final VitalsModel? initialVitals;

  const UpdateVitalsScreen({
    super.key,
    this.appointmentId = '',
    required this.patientName,
    required this.avatarUrl,
    this.initialVitals,
  });

  @override
  State<UpdateVitalsScreen> createState() => _UpdateVitalsScreenState();
}

class _UpdateVitalsScreenState extends State<UpdateVitalsScreen> {
  // Selected cause indices
  final Set<int> _selectedCauseIndices = {};

  // Controllers for Other cause details and vitals inputs
  final TextEditingController _otherCauseController = TextEditingController();
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _hrController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _sugarController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Pre-populate if initialVitals are provided (Editing Mode)
    if (widget.initialVitals != null) {
      _populateFromVitals(widget.initialVitals!);
    } else if (widget.appointmentId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final vitals = await context.read<VitalsCubit>().fetchVitalsByAppointment(widget.appointmentId);
        if (vitals != null && mounted) {
          _populateFromVitals(vitals);
        }
      });
    }

    _bpController.addListener(_validateForm);
    _hrController.addListener(_validateForm);
    _tempController.addListener(_validateForm);
    _sugarController.addListener(_validateForm);
    _spo2Controller.addListener(_validateForm);
    _weightController.addListener(_validateForm);
    _notesController.addListener(_validateForm);
  }

  void _populateFromVitals(VitalsModel v) {
    if (v.bloodPressure.isNotEmpty && v.bloodPressure != 'Pending') {
      _bpController.text = v.bloodPressure.replaceAll('mmHg', '').trim();
    }
    if (v.heartRate.isNotEmpty && v.heartRate != 'Pending') {
      _hrController.text = v.heartRate.replaceAll('bpm', '').trim();
    }
    if (v.temperature.isNotEmpty && v.temperature != 'Pending') {
      _tempController.text = v.temperature.replaceAll('°F', '').trim();
    }
    if (v.bloodSugar.isNotEmpty && v.bloodSugar != 'Pending') {
      _sugarController.text = v.bloodSugar.replaceAll('mg/dL', '').trim();
    }
    if (v.spo2.isNotEmpty && v.spo2 != 'Pending') {
      _spo2Controller.text = v.spo2.replaceAll('%', '').trim();
    }
    if (v.weight.isNotEmpty && v.weight != 'Pending') {
      _weightController.text = v.weight.replaceAll('kg', '').trim();
    }
    if (v.notes.isNotEmpty) {
      _notesController.text = v.notes;
    }
    if (v.reason.isNotEmpty) {
      for (int i = 0; i < _causes.length; i++) {
        final title = _causes[i]['title'] as String;
        if (v.reason.toLowerCase().contains(title.toLowerCase())) {
          _selectedCauseIndices.add(i);
        }
      }
    }
    _isFormValid = true;
    setState(() {});
  }

  void _validateForm() {
    final isValid = _bpController.text.trim().isNotEmpty ||
        _hrController.text.trim().isNotEmpty ||
        _tempController.text.trim().isNotEmpty ||
        _sugarController.text.trim().isNotEmpty ||
        _spo2Controller.text.trim().isNotEmpty ||
        _weightController.text.trim().isNotEmpty ||
        _selectedCauseIndices.isNotEmpty;
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

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialVitals != null && widget.initialVitals!.hasVitals;

    // Check if 'Other' cause is selected among multi-selected options
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
        title: Text(
          isEditing ? 'Edit Vitals' : 'Record Vitals',
          style: const TextStyle(
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
                            child: widget.avatarUrl.isNotEmpty
                                ? Image.network(
                                    widget.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.person_rounded, color: Color(0xFF64748B)),
                                  )
                                : const Icon(Icons.person_rounded, color: Color(0xFF64748B)),
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
                              Text(
                                (widget.initialVitals != null &&
                                        (widget.initialVitals!.patientAge.isNotEmpty ||
                                            widget.initialVitals!.patientGender.isNotEmpty))
                                    ? '${widget.initialVitals!.patientAge.isNotEmpty ? 'Age: ${widget.initialVitals!.patientAge} Years  •  ' : ''}${widget.initialVitals!.patientGender.isNotEmpty ? widget.initialVitals!.patientGender : ''}'
                                    : 'Home Care Patient',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Title: Cause / Reason
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Flexible(
                        child: Text(
                          'Observed Condition',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Select multiple',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0052FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Grid of Causes (Multi-Select)
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
                          _validateForm();
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

                  // If "Other" cause is selected, show input field
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
                        onChanged: (_) => _validateForm(),
                        decoration: const InputDecoration(
                          hintText: 'Please specify other condition / symptoms...',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Section Title: Vitals
                  const Text(
                    'Vital Signs',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Vitals List
                  _buildVitalInputRow(
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFEF4444),
                    iconBgColor: const Color(0xFFFEF2F2),
                    title: 'Blood Pressure',
                    controller: _bpController,
                    hintText: '120/80',
                    unit: 'mmHg',
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 10),
                  _buildVitalInputRow(
                    icon: Icons.monitor_heart_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBgColor: const Color(0xFFF5F3FF),
                    title: 'Heart Rate',
                    controller: _hrController,
                    hintText: '72',
                    unit: 'bpm',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  _buildVitalInputRow(
                    icon: Icons.thermostat_rounded,
                    iconColor: const Color(0xFFF97316),
                    iconBgColor: const Color(0xFFFFF7ED),
                    title: 'Temperature',
                    controller: _tempController,
                    hintText: '98.6',
                    unit: '°F',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  _buildVitalInputRow(
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBgColor: const Color(0xFFECFDF5),
                    title: 'Blood Sugar',
                    controller: _sugarController,
                    hintText: '95',
                    unit: 'mg/dL',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  _buildVitalInputRow(
                    icon: Icons.air_rounded,
                    iconColor: const Color(0xFF0052FF),
                    iconBgColor: const Color(0xFFEFF6FF),
                    title: 'Oxygen Level (SpO2)',
                    controller: _spo2Controller,
                    hintText: '99',
                    unit: '%',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  _buildVitalInputRow(
                    icon: Icons.scale_rounded,
                    iconColor: const Color(0xFF64748B),
                    iconBgColor: const Color(0xFFF1F5F9),
                    title: 'Weight',
                    controller: _weightController,
                    hintText: '68.5',
                    unit: 'kg',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),

                  const SizedBox(height: 20),

                  // Section Title: Observations / Notes
                  const Text(
                    'Clinical Observations & Notes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Notes TextField
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      onChanged: (_) => _validateForm(),
                      decoration: const InputDecoration(
                        hintText: 'Add clinical notes, medication instructions or patient response...',
                        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
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
                  onPressed: (_isFormValid && !_isSubmitting)
                      ? () async {
                          setState(() {
                            _isSubmitting = true;
                          });

                          final selectedCauses =
                              _selectedCauseIndices.map((i) => _causes[i]['title'] as String).join(', ');
                          final reason = isOtherSelected && _otherCauseController.text.trim().isNotEmpty
                              ? (selectedCauses.isNotEmpty
                                  ? '$selectedCauses (${_otherCauseController.text.trim()})'
                                  : _otherCauseController.text.trim())
                              : (selectedCauses.isNotEmpty ? selectedCauses : 'General Checkup');

                          final bp = _bpController.text.trim().isNotEmpty ? _bpController.text.trim() : '120/80';

                          final appointmentId = widget.appointmentId.isNotEmpty
                              ? widget.appointmentId
                              : (widget.initialVitals?.appointmentId.isNotEmpty == true
                                  ? widget.initialVitals!.appointmentId
                                  : (widget.initialVitals?.id ?? '6a9677047d61f0bb7ee9e499'));

                          final vitalsCubit = context.read<VitalsCubit>();
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);

                          final success = await vitalsCubit.recordVitals(
                                request: VitalsRecordRequest(
                                  appointmentId: appointmentId,
                                  patientId: widget.initialVitals?.patientId,
                                  bloodPressure: bp,
                                  heartRate: num.tryParse(_hrController.text.trim()),
                                  pulseRate: num.tryParse(_hrController.text.trim()),
                                  temperature: num.tryParse(_tempController.text.trim()),
                                  bloodSugar: num.tryParse(_sugarController.text.trim()),
                                  spo2: num.tryParse(_spo2Controller.text.trim()),
                                  weight: num.tryParse(_weightController.text.trim()),
                                  reason: reason,
                                  notes: _notesController.text.trim(),
                                ),
                                patientName: widget.patientName,
                                avatarUrl: widget.avatarUrl,
                              );

                          if (!mounted) return;

                          setState(() {
                            _isSubmitting = false;
                          });

                          if (success) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    isEditing ? 'Vitals updated successfully!' : 'Vitals recorded successfully!'),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            navigator.pop(true);
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to save vitals. Please check your connection and retry.'),
                                backgroundColor: Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          isEditing ? Icons.save_rounded : Icons.note_add_outlined,
                          size: 22,
                          color: _isFormValid ? Colors.white : Colors.white70,
                        ),
                  label: Text(
                    _isSubmitting
                        ? 'Saving...'
                        : (isEditing ? 'Save Changes' : 'Record Vitals'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isFormValid ? Colors.white : Colors.white70,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052FF),
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                    foregroundColor: Colors.white,
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

  Widget _buildVitalInputRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required TextEditingController controller,
    required String hintText,
    required String unit,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),
          // Title & Required Asterisk
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
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
          const SizedBox(width: 8),
          // TextField
          Container(
            width: 90,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Unit Label
          SizedBox(
            width: 48,
            child: Text(
              unit,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

