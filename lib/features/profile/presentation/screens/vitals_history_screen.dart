import 'dart:io';
import 'package:flutter/material.dart';
import '../../../vitals/data/models/vitals_details_model.dart';
import '../../../vitals/presentation/widgets/view_vitals_bottom_sheet.dart';
import '../../../visits/data/repositories/visits_repository.dart';

class VitalsHistoryScreen extends StatefulWidget {
  const VitalsHistoryScreen({super.key});

  @override
  State<VitalsHistoryScreen> createState() => _VitalsHistoryScreenState();
}

class _VitalsHistoryScreenState extends State<VitalsHistoryScreen> {
  final _visitsRepo = VisitsRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();
  
  List<PatientVitalsSummary> _allSummaries = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _filterChips = [
    'All',
    'Blood Pressure',
    'Blood Sugar',
    'SpO2',
    'With Photos',
    'With Reports',
  ];

  @override
  void initState() {
    super.initState();
    _loadVitalsHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVitalsHistory() async {
    setState(() => _isLoading = true);
    try {
      final items = await _visitsRepo.getVitalsHistorySummaries();
      if (mounted) {
        setState(() {
          _allSummaries = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSafeAvatar(String url) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.center,
        child: const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 24),
      );
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F5F9),
          alignment: Alignment.center,
          child: const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 24),
        ),
      );
    }
    try {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    } catch (_) {}
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 24),
    );
  }

  List<PatientVitalsSummary> get _filteredList {
    final query = _searchController.text.trim().toLowerCase();
    return _allSummaries.where((item) {
      // 1. Text Search Filter
      final matchesQuery = query.isEmpty ||
          item.patientName.toLowerCase().contains(query) ||
          item.patientAddress.toLowerCase().contains(query) ||
          item.notes.toLowerCase().contains(query) ||
          item.vitals.any((v) =>
              v.name.toLowerCase().contains(query) ||
              v.value.toLowerCase().contains(query));

      if (!matchesQuery) return false;

      // 2. Chip Filter
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Blood Pressure') {
        return item.vitals.any((v) => v.name.toLowerCase().contains('pressure') || v.name.toLowerCase().contains('bp'));
      }
      if (_selectedFilter == 'Blood Sugar') {
        return item.vitals.any((v) => v.name.toLowerCase().contains('sugar') || v.name.toLowerCase().contains('glucose'));
      }
      if (_selectedFilter == 'SpO2') {
        return item.vitals.any((v) => v.name.toLowerCase().contains('spo2') || v.name.toLowerCase().contains('oxygen'));
      }
      if (_selectedFilter == 'With Photos') {
        return item.conditionPhotos.isNotEmpty || item.vitals.any((v) => v.fileUrl.isNotEmpty);
      }
      if (_selectedFilter == 'With Reports') {
        return item.oldReports.isNotEmpty;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;

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
          'Vitals History',
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
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by patient name, vitals or notes...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0052FF), size: 22),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Horizontal Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterChips.map((chip) {
                      final isSelected = _selectedFilter == chip;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(chip),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              _selectedFilter = chip;
                            });
                          },
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          selectedColor: const Color(0xFF0052FF),
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF0052FF) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // List Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0052FF)))
                : RefreshIndicator(
                    onRefresh: _loadVitalsHistory,
                    color: const Color(0xFF0052FF),
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Icon(Icons.monitor_heart_outlined, size: 64, color: Color(0xFFCBD5E1)),
                              ),
                              SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'No vitals records found',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                              ),
                              SizedBox(height: 4),
                              Center(
                                child: Text(
                                  'Completed vitals will appear here automatically.',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final summary = filtered[index];
                              return _buildVitalsHistoryCard(summary);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsHistoryCard(PatientVitalsSummary summary) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Patient info + Recorded time
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: _buildSafeAvatar(summary.patientAvatar),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.patientName,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary.patientAddress.isNotEmpty ? summary.patientAddress : 'Patient Address',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    summary.recordedAt.isNotEmpty ? summary.recordedAt : 'Recorded',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Vitals Summary Pills
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.vitals.map((v) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_rounded, color: Color(0xFF0052FF), size: 13),
                      const SizedBox(width: 5),
                      Text(
                        '${v.name}: ',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${v.value} ${v.unit}'.trim(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Attachment badges (Photos / Reports / Notes)
          if (summary.conditionPhotos.isNotEmpty || summary.oldReports.isNotEmpty || summary.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
              child: Row(
                children: [
                  if (summary.conditionPhotos.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_camera_rounded, size: 12, color: Color(0xFF0052FF)),
                          const SizedBox(width: 4),
                          Text(
                            '${summary.conditionPhotos.length} Photo${summary.conditionPhotos.length > 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0052FF)),
                          ),
                        ],
                      ),
                    ),
                  if (summary.oldReports.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, size: 12, color: Color(0xFF8B5CF6)),
                          const SizedBox(width: 4),
                          Text(
                            '${summary.oldReports.length} Report${summary.oldReports.length > 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8B5CF6)),
                          ),
                        ],
                      ),
                    ),
                  if (summary.notes.isNotEmpty)
                    Expanded(
                      child: Text(
                        'Note: ${summary.notes}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

          // Bottom Action: View Vitals & Records
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () => ViewVitalsBottomSheet.show(context, summary),
                icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.white),
                label: const Text(
                  'View Full Vitals & Records',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
