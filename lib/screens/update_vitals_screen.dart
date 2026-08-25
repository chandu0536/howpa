import 'package:flutter/material.dart';

class UpdateVitalsScreen extends StatefulWidget {
  final String patientName;
  final String avatarUrl;

  const UpdateVitalsScreen({
    super.key,
    required this.patientName,
    required this.avatarUrl,
  });

  @override
  State<UpdateVitalsScreen> createState() => _UpdateVitalsScreenState();
}

class _UpdateVitalsScreenState extends State<UpdateVitalsScreen> {
  // Selected cause indices (Set allows selecting multiple causes like Fever, Vomiting, Cold & Cough, etc.)
  final Set<int> _selectedCauseIndices = {};

  // Controllers for Other cause details and vitals inputs (empty by default)
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

  @override
  Widget build(BuildContext context) {
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

                  // If "Other" cause is selected among choices, show text input field for typing matter
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
                  const Text(
                    'Update Vitals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
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
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: "Enter notes about the patient's condition...",
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 14,
                          child: Text(
                            '0/200',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
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
                  onPressed: _isFormValid ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vitals updated successfully!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    Navigator.pop(context, true);
                  } : null,
                  icon: Icon(Icons.note_add_outlined, size: 22, color: _isFormValid ? Colors.white : Colors.white70),
                  label: Text(
                    'Update Vitals',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
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
            width: 100,
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
          const SizedBox(width: 10),
          // Unit Label
          SizedBox(
            width: 55,
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
