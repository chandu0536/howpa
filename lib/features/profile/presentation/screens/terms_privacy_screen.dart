import 'package:flutter/material.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/profile_repository.dart';

class TermsPrivacyScreen extends StatefulWidget {
  final int initialTabIndex; // 0 for Terms, 1 for Privacy
  const TermsPrivacyScreen({super.key, this.initialTabIndex = 0});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _profileRepo = ProfileRepositoryImpl();
  bool _isLoading = true;
  LegalDocumentsData _legalData = const LegalDocumentsData();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _loadLegalDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLegalDocuments() async {
    try {
      final data = await _profileRepo.getLegalDocuments();
      if (mounted) {
        setState(() {
          _legalData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms & Policies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFFFF5C00),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Terms of Service'),
                Tab(text: 'Privacy Policy'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5C00)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTermsTab(),
                _buildPrivacyTab(),
              ],
            ),
    );
  }

  Widget _buildTermsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetaHeader(
            title: 'Terms of Service',
            subtitle: 'Nurse Partner Agreement & Service Standards',
          ),
          const SizedBox(height: 16),
          if (_legalData.termsContent.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Text(
                _legalData.termsContent,
                style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF334155)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ..._legalData.termsSections.map((sec) => _buildSectionCard(sec.title, sec.content)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetaHeader(
            title: 'Privacy Policy',
            subtitle: 'How Howpa protects your data and patient health records',
          ),
          const SizedBox(height: 16),
          if (_legalData.privacyContent.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Text(
                _legalData.privacyContent,
                style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF334155)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ..._legalData.privacySections.map((sec) => _buildSectionCard(sec.title, sec.content)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetaHeader({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4ED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'v${_legalData.version}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF5C00)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                'Last Updated: ${_legalData.lastUpdated}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
