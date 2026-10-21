import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:howpa_nurse/core/network/token_storage.dart';
import 'package:howpa_nurse/core/services/user_profile_manager.dart';
import 'package:howpa_nurse/features/profile/data/models/wallet_models.dart';
import 'package:howpa_nurse/features/profile/data/repositories/wallet_repository.dart';
import 'package:howpa_nurse/features/visits/data/repositories/visits_repository.dart';

class PaymentEarningsScreen extends StatefulWidget {
  const PaymentEarningsScreen({super.key});

  @override
  State<PaymentEarningsScreen> createState() => _PaymentEarningsScreenState();
}

class _PaymentEarningsScreenState extends State<PaymentEarningsScreen> {
  final _walletRepo = WalletRepositoryImpl();
  WalletSummary _walletSummary = const WalletSummary();
  Map<String, String> _savedBank = {};
  String _savedUpi = '';

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    final summary = await _walletRepo.getWalletSummary();
    final savedBank = await TokenStorage.getSavedBankDetails();
    final savedUpi = await TokenStorage.getSavedUpiId() ?? '';

    if (mounted) {
      if (summary.totalBalance == 0 && summary.thisWeekEarnings == 0) {
        final completed = VisitsRepositoryImpl.getCachedCompletedVisits();
        if (completed.isNotEmpty) {
          final computed = completed.fold<double>(0.0, (sum, item) => sum + (item.earnings ?? item.price ?? 100.0));
          setState(() {
            _savedBank = savedBank;
            _savedUpi = savedUpi;
            _walletSummary = WalletSummary(
              totalBalance: computed,
              thisWeekEarnings: computed,
              totalWithdrawn: summary.totalWithdrawn,
              pendingWithdrawals: summary.pendingWithdrawals,
              bankDetails: summary.bankDetails,
            );
          });
          return;
        }
      }
      setState(() {
        _savedBank = savedBank;
        _savedUpi = savedUpi;
        _walletSummary = summary;
      });
    }
  }

  void _openAddOrEditBankBottomSheet({bool isEditing = false}) {
    final nurseName = UserProfileManager.instance.fullName.isNotEmpty && UserProfileManager.instance.fullName != 'Nurse'
        ? UserProfileManager.instance.fullName
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddBankModalSheet(
        savedBank: _savedBank,
        savedUpi: _savedUpi,
        defaultHolderName: nurseName,
        onSave: (bank, upi) async {
          final messenger = ScaffoldMessenger.of(context);
          final ok = await _walletRepo.saveBankDetails(bank, upiId: upi);
          if (mounted) {
            await _loadWalletData();
            messenger.showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('Bank account saved and linked successfully!')),
                  ],
                ),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return ok;
        },
      ),
    );
  }

  void _openWithdrawalBottomSheet() async {
    if (_walletSummary.totalBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Insufficient balance. You need available earnings to withdraw.')),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final savedBank = await TokenStorage.getSavedBankDetails();
    final savedUpi = await TokenStorage.getSavedUpiId();
    final nurseName = UserProfileManager.instance.fullName.isNotEmpty && UserProfileManager.instance.fullName != 'Nurse'
        ? UserProfileManager.instance.fullName
        : '';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WithdrawalModalSheet(
        availableBalance: _walletSummary.totalBalance,
        savedBank: savedBank,
        savedUpi: savedUpi ?? '',
        defaultHolderName: nurseName,
        onManageBank: () {
          Navigator.pop(context);
          _openAddOrEditBankBottomSheet(isEditing: true);
        },
        onSubmit: (request) async {
          return await _submitWithdrawal(request);
        },
      ),
    );
  }

  Future<bool> _submitWithdrawal(PayoutWithdrawalRequest request) async {
    final success = await _walletRepo.requestPayout(request);
    if (!mounted) return success;

    if (success) {
      setState(() {
        _walletSummary = WalletSummary(
          totalBalance: math.max(0.0, _walletSummary.totalBalance - request.amount),
          thisWeekEarnings: _walletSummary.thisWeekEarnings,
          totalWithdrawn: _walletSummary.totalWithdrawn,
          pendingWithdrawals: _walletSummary.pendingWithdrawals + request.amount,
          bankDetails: _walletSummary.bankDetails,
        );
      });

      _loadWalletData();
      _showSuccessDialog(request.amount, request.paymentMethod);
      return true;
    } else {
      final msg = _walletRepo.lastPayoutMessage ?? 'Withdrawal request failed. Please check your details and try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return false;
    }
  }

  void _showSuccessDialog(double amount, String method) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Withdrawal Requested!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0052FF)),
            ),
            const SizedBox(height: 10),
            Text(
              'Your request via ${method == 'UPI' ? 'UPI' : 'Bank Transfer'} has been registered. Funds will be credited within 24-48 business hours.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment & Earnings',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWalletData,
        color: const Color(0xFF0052FF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Gradient Wallet Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0052FF), Color(0xFFFF5C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5C00).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'WALLET BALANCE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '₹${_walletSummary.totalBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                "This Week",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '₹${_walletSummary.thisWeekEarnings.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white30),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Total Withdrawn',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '₹${_walletSummary.totalWithdrawn.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _openWithdrawalBottomSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0052FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Send Withdraw Request',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Statistics Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.bar_chart_rounded,
                      iconColor: const Color(0xFF0052FF),
                      title: 'This Week',
                      amount: '₹${_walletSummary.thisWeekEarnings.toStringAsFixed(0)}',
                      subtitleWidget: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 13),
                          SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              'Active',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: const Color(0xFFC2410C),
                      title: 'Total Earned',
                      amount: '₹${(_walletSummary.totalBalance + _walletSummary.totalWithdrawn).toStringAsFixed(0)}',
                      subtitleWidget: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF10B981),
                            size: 13,
                          ),
                          SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              'Lifetime',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.assignment_outlined,
                      iconColor: const Color(0xFF0F766E),
                      title: 'Pending',
                      amount: '₹${_walletSummary.pendingWithdrawals.toStringAsFixed(0)}',
                      subtitleWidget: Text(
                        _walletSummary.pendingWithdrawals > 0 ? 'Settling...' : 'None',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payout Method / Bank Account Section
            _buildPayoutAccountSection(),

            const SizedBox(height: 24),

            // Recent Earnings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Flexible(
                    child: Text(
                      'Recent Earnings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Live Ledger',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0052FF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            if (_walletSummary.totalBalance == 0 && _walletSummary.thisWeekEarnings == 0 && _walletSummary.totalWithdrawn == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 48, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 12),
                      Text(
                        'No earnings transactions recorded yet.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Wallet Balance',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Available for instant bank withdrawal',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '₹${_walletSummary.totalBalance.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF10B981)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    Widget? subtitleWidget,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          if (subtitleWidget != null) ...[
            const SizedBox(height: 6),
            subtitleWidget,
          ],
        ],
      ),
    );
  }

  String _maskAccountNumber(String acc) {
    final clean = acc.replaceAll(' ', '');
    if (clean.length <= 4) return clean;
    final last4 = clean.substring(clean.length - 4);
    return '•••• •••• •••• $last4';
  }

  Widget _buildPayoutAccountSection() {
    final hasBank = _savedBank['accountNumber']?.isNotEmpty == true;
    final hasUpi = _savedUpi.isNotEmpty;
    final isLinked = hasBank || hasUpi;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Payout Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLinked)
                InkWell(
                  onTap: () => _openAddOrEditBankBottomSheet(isEditing: true),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 14, color: Color(0xFF0052FF)),
                        SizedBox(width: 4),
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0052FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isLinked)
            // Empty State: Add Bank Account
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0052FF), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No Bank Account Linked',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Add your bank account or UPI ID for direct payouts.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _openAddOrEditBankBottomSheet(isEditing: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            )
          else
            // Linked State: Shows Bank Account Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0052FF), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _savedBank['bankName']?.isNotEmpty == true
                                        ? _savedBank['bankName']!
                                        : (hasBank ? 'Bank Account' : 'UPI Account'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF16A34A)),
                                      SizedBox(width: 3),
                                      Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            if (hasBank)
                              Text(
                                _maskAccountNumber(_savedBank['accountNumber'] ?? ''),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569), letterSpacing: 0.8),
                              )
                            else if (hasUpi)
                              Text(
                                _savedUpi,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hasBank) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Holder: ${_savedBank['accountHolderName'] ?? ""}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'IFSC: ${_savedBank['ifscCode'] ?? ""}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (hasUpi && hasBank) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, size: 13, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          'UPI: $_savedUpi',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
}

class _WithdrawalModalSheet extends StatefulWidget {
  final double availableBalance;
  final Map<String, String> savedBank;
  final String savedUpi;
  final String defaultHolderName;
  final VoidCallback? onManageBank;
  final Future<bool> Function(PayoutWithdrawalRequest) onSubmit;

  const _WithdrawalModalSheet({
    required this.availableBalance,
    required this.savedBank,
    required this.savedUpi,
    required this.defaultHolderName,
    this.onManageBank,
    required this.onSubmit,
  });

  @override
  State<_WithdrawalModalSheet> createState() => _WithdrawalModalSheetState();
}

class _WithdrawalModalSheetState extends State<_WithdrawalModalSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _holderController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountController;
  late final TextEditingController _confirmAccountController;
  late final TextEditingController _ifscController;
  late final TextEditingController _upiController;

  String _selectedMethod = 'BANK'; // 'BANK' or 'UPI'
  bool _isSubmitting = false;
  bool _showEditFields = false;
  String? _amountError;
  String? _accountError;
  String? _ifscError;
  String? _holderError;
  String? _upiError;

  @override
  void initState() {
    super.initState();
    final hasBank = widget.savedBank['accountNumber']?.isNotEmpty == true;
    final hasUpi = widget.savedUpi.isNotEmpty;
    _selectedMethod = hasBank ? 'BANK' : (hasUpi ? 'UPI' : 'BANK');

    final initialAmount = widget.availableBalance > 0
        ? (widget.availableBalance >= 100
            ? widget.availableBalance.toInt().toString()
            : widget.availableBalance.toStringAsFixed(0))
        : '';
    _amountController = TextEditingController(text: initialAmount);
    _holderController = TextEditingController(
      text: widget.savedBank['accountHolderName']?.isNotEmpty == true
          ? widget.savedBank['accountHolderName']
          : widget.defaultHolderName,
    );
    _bankNameController = TextEditingController(text: widget.savedBank['bankName'] ?? '');
    _accountController = TextEditingController(text: widget.savedBank['accountNumber'] ?? '');
    _confirmAccountController = TextEditingController(text: widget.savedBank['accountNumber'] ?? '');
    _ifscController = TextEditingController(text: widget.savedBank['ifscCode'] ?? '');
    _upiController = TextEditingController(text: widget.savedUpi);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _holderController.dispose();
    _bankNameController.dispose();
    _accountController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  String _maskAcc(String acc) {
    final clean = acc.replaceAll(' ', '');
    if (clean.length <= 4) return clean;
    return '•••• •••• •••• ${clean.substring(clean.length - 4)}';
  }

  void _validateAndSubmit() async {
    setState(() {
      _amountError = null;
      _accountError = null;
      _ifscError = null;
      _holderError = null;
      _upiError = null;
    });

    final amountText = _amountController.text.trim();
    final double? amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter a valid withdrawal amount.');
      return;
    }

    if (amount > widget.availableBalance) {
      setState(() => _amountError =
          'Amount exceeds available balance (₹${widget.availableBalance.toStringAsFixed(0)}).');
      return;
    }

    if (_selectedMethod == 'BANK') {
      final hasSaved = widget.savedBank['accountNumber']?.isNotEmpty == true;
      final holder = !_showEditFields && hasSaved
          ? widget.savedBank['accountHolderName']!
          : _holderController.text.trim();
      final acc = !_showEditFields && hasSaved
          ? widget.savedBank['accountNumber']!
          : _accountController.text.trim();
      final confirmAcc = !_showEditFields && hasSaved
          ? widget.savedBank['accountNumber']!
          : _confirmAccountController.text.trim();
      final ifsc = (!_showEditFields && hasSaved
              ? widget.savedBank['ifscCode']!
              : _ifscController.text.trim())
          .toUpperCase();
      final bank = !_showEditFields && hasSaved
          ? (widget.savedBank['bankName'] ?? 'Bank')
          : _bankNameController.text.trim();

      bool hasError = false;
      if (holder.isEmpty) {
        _holderError = 'Account holder name is required.';
        hasError = true;
      }
      if (acc.isEmpty || acc.length < 8) {
        _accountError = 'Enter a valid account number (min 8 digits).';
        hasError = true;
      } else if (acc != confirmAcc) {
        _accountError = 'Account numbers do not match.';
        hasError = true;
      }
      if (ifsc.isEmpty || ifsc.length < 11) {
        _ifscError = 'Enter a valid 11-character IFSC code (e.g. HDFC0001234).';
        hasError = true;
      }

      if (hasError) {
        setState(() {});
        return;
      }

      TokenStorage.saveBankDetails(
        accountNumber: acc,
        ifscCode: ifsc,
        accountHolderName: holder,
        bankName: bank.isNotEmpty ? bank : 'Bank',
      );

      setState(() => _isSubmitting = true);

      final req = PayoutWithdrawalRequest(
        amount: amount,
        paymentMethod: 'BANK',
        bankDetails: BankDetails(
          accountNumber: acc,
          ifscCode: ifsc,
          bankName: bank.isNotEmpty ? bank : 'Bank',
          accountHolderName: holder,
        ),
      );

      final ok = await widget.onSubmit(req);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (ok) {
          Navigator.pop(context);
        }
      }
    } else {
      final hasSavedUpi = widget.savedUpi.isNotEmpty;
      final upi = !_showEditFields && hasSavedUpi
          ? widget.savedUpi
          : _upiController.text.trim();

      if (upi.isEmpty || !upi.contains('@')) {
        setState(() => _upiError = 'Enter a valid UPI ID (e.g. mobile@upi or name@bank).');
        return;
      }

      TokenStorage.saveUpiId(upi);

      setState(() => _isSubmitting = true);

      final req = PayoutWithdrawalRequest(
        amount: amount,
        paymentMethod: 'UPI',
        upiId: upi,
      );

      final ok = await widget.onSubmit(req);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (ok) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasSavedBank = widget.savedBank['accountNumber']?.isNotEmpty == true;
    final hasSavedUpi = widget.savedUpi.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, math.max(20.0, bottomInset + 16)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Withdraw Earnings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Available: ₹${widget.availableBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter Amount',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '₹',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0052FF)),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '0',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                errorText: _amountError,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0052FF), width: 1.5)),
              ),
              onChanged: (_) {
                if (_amountError != null) setState(() => _amountError = null);
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (widget.availableBalance >= 100) _buildQuickChip('₹100', 100),
                if (widget.availableBalance >= 200) _buildQuickChip('₹200', 200),
                if (widget.availableBalance >= 500) _buildQuickChip('₹500', 500),
                _buildQuickChip('All (₹${widget.availableBalance.toInt()})', widget.availableBalance),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payout Destination',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                if ((hasSavedBank || hasSavedUpi) && !_showEditFields)
                  InkWell(
                    onTap: () => setState(() => _showEditFields = true),
                    child: const Text(
                      'Edit / Change',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0052FF)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedMethod = 'BANK'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMethod == 'BANK' ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedMethod == 'BANK' ? const Color(0xFF0052FF) : const Color(0xFFE2E8F0),
                          width: _selectedMethod == 'BANK' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_rounded,
                              size: 18,
                              color: _selectedMethod == 'BANK' ? const Color(0xFF0052FF) : const Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(
                            'Bank Transfer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedMethod == 'BANK' ? const Color(0xFF0052FF) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedMethod = 'UPI'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMethod == 'UPI' ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedMethod == 'UPI' ? const Color(0xFF0052FF) : const Color(0xFFE2E8F0),
                          width: _selectedMethod == 'UPI' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flash_on_rounded,
                              size: 18,
                              color: _selectedMethod == 'UPI' ? const Color(0xFF0052FF) : const Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(
                            'UPI Transfer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedMethod == 'UPI' ? const Color(0xFF0052FF) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_selectedMethod == 'BANK') ...[
              if (hasSavedBank && !_showEditFields)
                // Display linked bank account preview
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0052FF), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.savedBank['bankName']?.isNotEmpty == true
                                      ? widget.savedBank['bankName']!
                                      : 'Bank Account',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _maskAcc(widget.savedBank['accountNumber'] ?? ''),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155), letterSpacing: 0.6),
                            ),
                            Text(
                              '${widget.savedBank['accountHolderName'] ?? ""} • ${widget.savedBank['ifscCode'] ?? ""}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _showEditFields = true),
                        child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0052FF))),
                      ),
                    ],
                  ),
                )
              else ...[
                _buildTextField(
                  label: 'Account Holder Name',
                  controller: _holderController,
                  hint: 'Name as per bank passbook',
                  error: _holderError,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Bank Account Number',
                  controller: _accountController,
                  hint: 'Enter bank account number',
                  keyboardType: TextInputType.number,
                  error: _accountError,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Confirm Account Number',
                  controller: _confirmAccountController,
                  hint: 'Re-enter account number',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildTextField(
                        label: 'IFSC Code',
                        controller: _ifscController,
                        hint: 'HDFC0001234',
                        textCapitalization: TextCapitalization.characters,
                        error: _ifscError,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: _buildTextField(
                        label: 'Bank Name (Optional)',
                        controller: _bankNameController,
                        hint: 'e.g. HDFC Bank, SBI',
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              if (hasSavedUpi && !_showEditFields)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: Color(0xFF0052FF), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('UPI ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                                SizedBox(width: 6),
                                Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(widget.savedUpi, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _showEditFields = true),
                        child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0052FF))),
                      ),
                    ],
                  ),
                )
              else ...[
                _buildTextField(
                  label: 'UPI ID (VPA)',
                  controller: _upiController,
                  hint: 'e.g. 9876543210@upi or name@okaxis',
                  error: _upiError,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Instant payout to Google Pay, PhonePe, Paytm, BHIM, or any UPI app.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _validateAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Submit Withdrawal Request',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, num val) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0052FF))),
      backgroundColor: const Color(0xFFEEF2FF),
      side: const BorderSide(color: Color(0xFFC7D2FE)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: () {
        setState(() {
          _amountController.text = val.toInt().toString();
          _amountError = null;
        });
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? error,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            errorText: error,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0052FF), width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _AddBankModalSheet extends StatefulWidget {
  final Map<String, String> savedBank;
  final String savedUpi;
  final String defaultHolderName;
  final Future<bool> Function(BankDetails, String?) onSave;

  const _AddBankModalSheet({
    required this.savedBank,
    required this.savedUpi,
    required this.defaultHolderName,
    required this.onSave,
  });

  @override
  State<_AddBankModalSheet> createState() => _AddBankModalSheetState();
}

class _AddBankModalSheetState extends State<_AddBankModalSheet> {
  late final TextEditingController _holderController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountController;
  late final TextEditingController _confirmAccountController;
  late final TextEditingController _ifscController;
  late final TextEditingController _upiController;

  String _selectedMethod = 'BANK'; // 'BANK' or 'UPI'
  bool _isSaving = false;
  String? _holderError;
  String? _accountError;
  String? _ifscError;
  String? _upiError;

  @override
  void initState() {
    super.initState();
    _holderController = TextEditingController(
      text: widget.savedBank['accountHolderName']?.isNotEmpty == true
          ? widget.savedBank['accountHolderName']
          : widget.defaultHolderName,
    );
    _bankNameController = TextEditingController(text: widget.savedBank['bankName'] ?? '');
    _accountController = TextEditingController(text: widget.savedBank['accountNumber'] ?? '');
    _confirmAccountController = TextEditingController(text: widget.savedBank['accountNumber'] ?? '');
    _ifscController = TextEditingController(text: widget.savedBank['ifscCode'] ?? '');
    _upiController = TextEditingController(text: widget.savedUpi);
    if (widget.savedBank['accountNumber']?.isEmpty == true && widget.savedUpi.isNotEmpty) {
      _selectedMethod = 'UPI';
    }
  }

  @override
  void dispose() {
    _holderController.dispose();
    _bankNameController.dispose();
    _accountController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _validateAndSave() async {
    setState(() {
      _holderError = null;
      _accountError = null;
      _ifscError = null;
      _upiError = null;
    });

    final holder = _holderController.text.trim();
    final acc = _accountController.text.trim();
    final confirmAcc = _confirmAccountController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();
    final bank = _bankNameController.text.trim();
    final upi = _upiController.text.trim();

    if (_selectedMethod == 'BANK') {
      bool hasError = false;
      if (holder.isEmpty) {
        _holderError = 'Account holder name is required.';
        hasError = true;
      }
      if (acc.isEmpty || acc.length < 8) {
        _accountError = 'Enter a valid account number (min 8 digits).';
        hasError = true;
      } else if (acc != confirmAcc) {
        _accountError = 'Account numbers do not match.';
        hasError = true;
      }
      if (ifsc.isEmpty || ifsc.length < 11) {
        _ifscError = 'Enter a valid 11-character IFSC code (e.g. HDFC0001234).';
        hasError = true;
      }

      if (hasError) {
        setState(() {});
        return;
      }

      setState(() => _isSaving = true);

      final bankDetails = BankDetails(
        accountNumber: acc,
        ifscCode: ifsc,
        bankName: bank.isNotEmpty ? bank : 'Bank',
        accountHolderName: holder,
        upiId: upi.isNotEmpty ? upi : null,
      );

      final ok = await widget.onSave(bankDetails, upi.isNotEmpty ? upi : null);
      if (mounted) {
        setState(() => _isSaving = false);
        if (ok) Navigator.pop(context);
      }
    } else {
      if (upi.isEmpty || !upi.contains('@')) {
        setState(() => _upiError = 'Enter a valid UPI ID (e.g. mobile@upi or name@bank).');
        return;
      }

      setState(() => _isSaving = true);

      final bankDetails = BankDetails(
        accountNumber: acc,
        ifscCode: ifsc,
        bankName: bank.isNotEmpty ? bank : 'Bank',
        accountHolderName: holder.isNotEmpty ? holder : widget.defaultHolderName,
        upiId: upi,
      );

      final ok = await widget.onSave(bankDetails, upi);
      if (mounted) {
        setState(() => _isSaving = false);
        if (ok) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, math.max(20.0, bottomInset + 16)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Payout Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  splashRadius: 20,
                ),
              ],
            ),
            const Text(
              'Link your bank account or UPI ID to receive earnings directly.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedMethod = 'BANK'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMethod == 'BANK' ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedMethod == 'BANK' ? const Color(0xFF0052FF) : const Color(0xFFE2E8F0),
                          width: _selectedMethod == 'BANK' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_rounded,
                              size: 18,
                              color: _selectedMethod == 'BANK' ? const Color(0xFF0052FF) : const Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(
                            'Bank Account',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedMethod == 'BANK' ? const Color(0xFF0052FF) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedMethod = 'UPI'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMethod == 'UPI' ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedMethod == 'UPI' ? const Color(0xFF0052FF) : const Color(0xFFE2E8F0),
                          width: _selectedMethod == 'UPI' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flash_on_rounded,
                              size: 18,
                              color: _selectedMethod == 'UPI' ? const Color(0xFF0052FF) : const Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(
                            'UPI ID',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedMethod == 'UPI' ? const Color(0xFF0052FF) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedMethod == 'BANK') ...[
              _buildTextField(
                label: 'Account Holder Name',
                controller: _holderController,
                hint: 'Name as per bank passbook',
                error: _holderError,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Bank Account Number',
                controller: _accountController,
                hint: 'Enter bank account number',
                keyboardType: TextInputType.number,
                error: _accountError,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Confirm Account Number',
                controller: _confirmAccountController,
                hint: 'Re-enter account number',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildTextField(
                      label: 'IFSC Code',
                      controller: _ifscController,
                      hint: 'HDFC0001234',
                      textCapitalization: TextCapitalization.characters,
                      error: _ifscError,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: _buildTextField(
                      label: 'Bank Name (Optional)',
                      controller: _bankNameController,
                      hint: 'e.g. HDFC Bank, SBI',
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildTextField(
                label: 'UPI ID (VPA)',
                controller: _upiController,
                hint: 'e.g. 9876543210@upi or name@okaxis',
                error: _upiError,
              ),
              const SizedBox(height: 6),
              const Text(
                'Instant payout to Google Pay, PhonePe, Paytm, BHIM, or any UPI app.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _validateAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _selectedMethod == 'BANK' ? 'Save & Link Bank Account' : 'Save & Link UPI ID',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? error,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            errorText: error,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0052FF), width: 1.5)),
          ),
        ),
      ],
    );
  }
}
