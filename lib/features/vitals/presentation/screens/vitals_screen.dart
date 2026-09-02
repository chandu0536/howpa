import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:howpa_nurse/features/visits/presentation/screens/visits_screen.dart';
import 'package:howpa_nurse/features/vitals/presentation/screens/update_vitals_screen.dart';
import 'package:howpa_nurse/features/profile/presentation/screens/profile_screen.dart';
import '../cubit/vitals_cubit.dart';
import '../cubit/vitals_state.dart';
import '../../data/models/vitals_model.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  int _currentBottomNavIndex = 2; // Vitals selected
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VitalsCubit>().fetchVitalsList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Patient Vitals',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Monitor & record vital signs',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      context.read<VitalsCubit>().fetchVitalsList();
                    },
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0052FF), size: 24),
                    tooltip: 'Refresh Vitals',
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    context.read<VitalsCubit>().fetchVitalsList(search: val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by patient name, phone or address...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchController.clear();
                              context.read<VitalsCubit>().fetchVitalsList();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Main List of Patients & Vitals
            Expanded(
              child: BlocBuilder<VitalsCubit, VitalsState>(
                builder: (context, state) {
                  if (state is VitalsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF0052FF)),
                    );
                  }

                  if (state is VitalsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 42),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.read<VitalsCubit>().fetchVitalsList(),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0052FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final vitalsList = state is VitalsLoaded ? state.vitalsList : <VitalsModel>[];

                  if (vitalsList.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        await context.read<VitalsCubit>().fetchVitalsList();
                      },
                      color: const Color(0xFF0052FF),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.monitor_heart_outlined, color: Color(0xFFCBD5E1), size: 54),
                                SizedBox(height: 14),
                                Text(
                                  'No vitals records found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Patient vitals recorded during visits will appear here.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await context.read<VitalsCubit>().fetchVitalsList();
                    },
                    color: const Color(0xFF0052FF),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: vitalsList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = vitalsList[index];
                        return _buildVitalsCard(item);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildVitalsCard(VitalsModel item) {
    final String appointmentId = item.appointmentId.isNotEmpty ? item.appointmentId : item.id;
    final bool hasVitals = item.hasVitals && item.bloodPressure != 'Pending' && item.bloodPressure.isNotEmpty;

    // Build demographics string: e.g. "HOWPAHV000001 • 25 yrs • Male • 03:00 PM"
    final List<String> demoParts = [];
    if (item.appointmentNumber.isNotEmpty) {
      demoParts.add(item.appointmentNumber);
    }
    if (item.patientAge.isNotEmpty && item.patientAge != '0') {
      demoParts.add('${item.patientAge} yrs');
    }
    if (item.patientGender.isNotEmpty) {
      demoParts.add(item.patientGender[0].toUpperCase() + item.patientGender.substring(1));
    }
    if (item.appointmentTime.isNotEmpty) {
      demoParts.add(item.appointmentTime);
    }
    final String demographics = demoParts.join(' • ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
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
              // Left status accent bar (Green if recorded, Orange if pending)
              Container(
                width: 4,
                color: hasVitals ? const Color(0xFF10B981) : const Color(0xFFFF5C00),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar + Name & Demographics + Status Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF1F5F9),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                            ),
                            child: ClipOval(
                              child: item.avatarUrl.isNotEmpty
                                  ? Image.network(
                                      item.avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 28);
                                      },
                                    )
                                  : const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 28),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    // Status Pill (Recorded vs Pending)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: hasVitals ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: hasVitals ? const Color(0xFFA7F3D0) : const Color(0xFFFFEDD5),
                                        ),
                                      ),
                                      child: Text(
                                        hasVitals ? 'Recorded' : 'Pending',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: hasVitals ? const Color(0xFF059669) : const Color(0xFFEA580C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (demographics.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    demographics,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Patient Phone & Address Line
                      if (item.patientPhone.isNotEmpty || item.patientAddress.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (item.patientPhone.isNotEmpty) ...[
                              const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                item.patientPhone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item.patientAddress.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                                const SizedBox(width: 6),
                              ],
                            ],
                            if (item.patientAddress.isNotEmpty) ...[
                              const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.patientAddress,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.25),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],

                      // Vitals Metrics Chips (BP, Heart Rate, SpO2, Temp, Sugar, Weight)
                      if (hasVitals) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (item.bloodPressure.isNotEmpty && item.bloodPressure != 'Pending')
                              _buildMetricChip(
                                icon: Icons.favorite_rounded,
                                label: 'BP: ${item.bloodPressure}',
                                color: const Color(0xFFEF4444),
                                bgColor: const Color(0xFFFEF2F2),
                              ),
                            if (item.heartRate.isNotEmpty && item.heartRate != 'Pending')
                              _buildMetricChip(
                                icon: Icons.monitor_heart_rounded,
                                label: item.heartRate,
                                color: const Color(0xFF8B5CF6),
                                bgColor: const Color(0xFFF5F3FF),
                              ),
                            if (item.spo2.isNotEmpty && item.spo2 != 'Pending')
                              _buildMetricChip(
                                icon: Icons.air_rounded,
                                label: 'SpO2: ${item.spo2}',
                                color: const Color(0xFF0052FF),
                                bgColor: const Color(0xFFEFF6FF),
                              ),
                            if (item.temperature.isNotEmpty && item.temperature != 'Pending')
                              _buildMetricChip(
                                icon: Icons.thermostat_rounded,
                                label: item.temperature,
                                color: const Color(0xFFF97316),
                                bgColor: const Color(0xFFFFF7ED),
                              ),
                            if (item.bloodSugar.isNotEmpty && item.bloodSugar != 'Pending')
                              _buildMetricChip(
                                icon: Icons.water_drop_rounded,
                                label: 'Sugar: ${item.bloodSugar}',
                                color: const Color(0xFF10B981),
                                bgColor: const Color(0xFFECFDF5),
                              ),
                            if (item.weight.isNotEmpty && item.weight != 'Pending')
                              _buildMetricChip(
                                icon: Icons.scale_rounded,
                                label: item.weight,
                                color: const Color(0xFF475569),
                                bgColor: const Color(0xFFF1F5F9),
                              ),
                          ],
                        ),
                      ],

                      // Notes / Reason Container
                      if (item.notes.isNotEmpty || item.reason.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            item.notes.isNotEmpty ? item.notes : 'Condition: ${item.reason}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Action Button (Edit Vitals vs Record Vitals)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpdateVitalsScreen(
                                  appointmentId: appointmentId,
                                  patientName: item.patientName,
                                  avatarUrl: item.avatarUrl,
                                  initialVitals: hasVitals ? item : null,
                                ),
                              ),
                            );
                            if (result == true && mounted) {
                              context.read<VitalsCubit>().fetchVitalsList();
                            }
                          },
                          icon: Icon(
                            hasVitals ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                            size: 20,
                            color: hasVitals ? const Color(0xFF0052FF) : const Color(0xFFFF5C00),
                          ),
                          label: Text(
                            hasVitals ? 'Edit Vitals' : 'Record Vitals',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: hasVitals ? const Color(0xFF0052FF) : const Color(0xFFFF5C00),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: hasVitals ? const Color(0xFFEFF6FF) : const Color(0xFFFFF7ED),
                            side: BorderSide(
                              color: hasVitals ? const Color(0xFFBFDBFE) : const Color(0xFFFFEDD5),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFFE0E7FF),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0052FF));
            }
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Color(0xFF94A3B8));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF0052FF), size: 24);
            }
            return const IconThemeData(color: Color(0xFF94A3B8), size: 24);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentBottomNavIndex,
          onDestinationSelected: (index) {
            if (index == _currentBottomNavIndex) return;
            if (index == 0) {
              Navigator.popUntil(context, (route) => route.isFirst);
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VisitsScreen()),
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
          backgroundColor: Colors.white,
          elevation: 0,
          height: 65,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Visits',
            ),
            NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined),
              selectedIcon: Icon(Icons.monitor_heart_rounded),
              label: 'Vitals',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
