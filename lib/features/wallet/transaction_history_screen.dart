import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/sound_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final int initialTabIndex;

  const TransactionHistoryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchTransactions();
      context.read<AppState>().fetchTopUps();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyText(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    SoundService.playTap();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label কপি করা হয়েছে! ($text)'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          app.isBn ? 'লেনদেন ও ব্যালেন্স বিবরণ' : 'History & Ledger',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.receipt_long_rounded, size: 20),
              text: app.isBn ? 'মূল লেনদেন খতিয়ান' : 'Ledger Transactions',
            ),
            Tab(
              icon: const Icon(Icons.payments_rounded, size: 20),
              text: app.isBn ? 'টপ-আপ হিস্ট্রি' : 'Top-Up History',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Ledger Transactions
          RefreshIndicator(
            onRefresh: () => app.fetchTransactions(),
            color: AppColors.primary,
            child: app.transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          app.isBn ? 'কোন লেনদেন তথ্য নেই' : 'No transactions recorded yet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: app.transactions.length,
                    itemBuilder: (ctx, index) {
                      final tx = app.transactions[index];
                      final isCredit = tx.type == 'TOPUP' || tx.type == 'REFUND' || tx.type == 'BONUS';

                      final dateStr = tx.createdAt.isNotEmpty
                          ? DateFormat('dd MMM yyyy, hh:mm a')
                              .format(DateTime.tryParse(tx.createdAt) ?? DateTime.now())
                          : 'Just now';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon Badge / Real Payment Logo
                            () {
                              final desc = '${tx.description} ${tx.type}'.toUpperCase();
                              String? mfsAsset;
                              if (desc.contains('BKASH') || desc.contains('বিকাশ')) {
                                mfsAsset = 'assets/payments/bkash.png';
                              } else if (desc.contains('NAGAD') || desc.contains('নগদ')) {
                                mfsAsset = 'assets/payments/nagad.png';
                              } else if (desc.contains('ROCKET') || desc.contains('রকেট')) {
                                mfsAsset = 'assets/payments/rocket.png';
                              } else if (desc.contains('UPAY') || desc.contains('উপায়') || desc.contains('উপায়')) {
                                mfsAsset = 'assets/payments/upay.png';
                              }

                              if (mfsAsset != null) {
                                return Container(
                                  width: 44,
                                  height: 44,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade300),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(mfsAsset, fit: BoxFit.contain),
                                  ),
                                );
                              }

                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isCredit ? AppColors.success : AppColors.error,
                                  size: 20,
                                ),
                              );
                            }(),
                            const SizedBox(width: 14),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.description.isNotEmpty
                                        ? tx.description
                                        : (isCredit ? 'Wallet Top-Up' : 'Offer Purchase'),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),

                                  // Recipient Phone Display (CRITICAL REQUIREMENT)
                                  if (tx.recipientPhone != null && tx.recipientPhone!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () => _copyText(tx.recipientPhone!, 'প্রাপক নম্বর'),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.phone_android, size: 13, color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              'প্রাপক নম্বর: ${tx.recipientPhone}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.copy, size: 11, color: AppColors.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],

                                  if (tx.balanceAfter > 0) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Balance: ৳${tx.balanceAfter.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Amount & Status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isCredit ? '+' : '-'}৳${tx.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCredit ? AppColors.success : AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tx.status == 'COMPLETED'
                                        ? AppColors.success.withOpacity(0.12)
                                        : (tx.status == 'PENDING'
                                            ? AppColors.secondary.withOpacity(0.12)
                                            : AppColors.error.withOpacity(0.12)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tx.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: tx.status == 'COMPLETED'
                                          ? AppColors.success
                                          : (tx.status == 'PENDING' ? AppColors.secondary : AppColors.error),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // TAB 2: Top-Up (Add Balance) History
          RefreshIndicator(
            onRefresh: () => app.fetchTopUps(),
            color: AppColors.primary,
            child: app.topUps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payments_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          app.isBn ? 'কোন টপ-আপ রিকোয়েস্ট তথ্য নেই' : 'No top-up records yet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: app.topUps.length,
                    itemBuilder: (ctx, index) {
                      final topUp = app.topUps[index];

                      Color provColor = AppColors.primary;
                      String provAsset = 'assets/payments/bkash.png';
                      if (topUp.provider == 'BKASH') {
                        provColor = const Color(0xFFE2136E);
                        provAsset = 'assets/payments/bkash.png';
                      } else if (topUp.provider == 'NAGAD') {
                        provColor = const Color(0xFFF7941D);
                        provAsset = 'assets/payments/nagad.png';
                      } else if (topUp.provider == 'ROCKET') {
                        provColor = const Color(0xFF8C3494);
                        provAsset = 'assets/payments/rocket.png';
                      } else if (topUp.provider == 'UPAY') {
                        provColor = const Color(0xFF0047BA);
                        provAsset = 'assets/payments/upay.png';
                      }

                      final isVerified = topUp.status == 'VERIFIED';
                      final isVerifying = topUp.status == 'VERIFYING';
                      final isPending = topUp.status == 'PENDING';

                      final statusColor = isVerified
                          ? AppColors.success
                          : (isVerifying
                              ? const Color(0xFFD97706)
                              : (isPending ? const Color(0xFF2563EB) : AppColors.error));

                      final statusBg = isVerified
                          ? const Color(0xFFDCFCE7)
                          : (isVerifying
                              ? const Color(0xFFFEF3C7)
                              : (isPending ? const Color(0xFFDBEAFE) : const Color(0xFFFEE2E2)));

                      final statusLabel = isVerified
                          ? (app.isBn ? 'সফল (যুক্ত হয়েছে)' : 'Verified')
                          : (isVerifying
                              ? (app.isBn ? 'যাচাই চলছে...' : 'Verifying')
                              : (isPending
                                  ? (app.isBn ? 'অপেক্ষমাণ' : 'Pending')
                                  : (app.isBn ? 'বাতিল' : 'Failed')));

                      final IconData statusIcon = isVerified
                          ? Icons.check_circle_rounded
                          : (isVerifying
                              ? Icons.hourglass_top_rounded
                              : (isPending ? Icons.schedule_rounded : Icons.cancel_rounded));

                      final dateStr = topUp.createdAt.isNotEmpty
                          ? DateFormat('dd MMM yyyy, hh:mm a')
                              .format(DateTime.tryParse(topUp.createdAt) ?? DateTime.now())
                          : 'Just now';

                      final displayTxId = topUp.transactionId.isNotEmpty
                          ? topUp.transactionId
                          : (topUp.topUpNumber.isNotEmpty ? topUp.topUpNumber : 'N/A');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: provColor.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: provColor.withOpacity(0.25), width: 1.5),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        provAsset,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            Icon(Icons.payment, color: provColor, size: 22),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${topUp.provider} টপ-আপ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: provColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: statusBg,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: statusColor.withOpacity(0.3), width: 0.8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(statusIcon, size: 10, color: statusColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    statusLabel,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(
                                              dateStr,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '+৳${topUp.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 10),

                              // Bottom Details Box
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    // TrxID Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.tag_rounded, size: 14, color: AppColors.textSecondary),
                                            const SizedBox(width: 5),
                                            Text(
                                              'TrxID: ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            Text(
                                              displayTxId,
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: displayTxId != 'N/A' ? AppColors.textPrimary : Colors.grey.shade400,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (displayTxId != 'N/A')
                                          InkWell(
                                            onTap: () => _copyText(displayTxId, 'TrxID'),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    app.isBn ? 'কপি' : 'Copy',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    // Number Row (Payment Number & Sender Phone)
                                    if (topUp.paymentNumber.isNotEmpty || (topUp.senderPhone != null && topUp.senderPhone!.isNotEmpty)) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_android_rounded, size: 14, color: AppColors.textSecondary),
                                              const SizedBox(width: 5),
                                              Text(
                                                app.isBn ? 'নম্বর: ' : 'Number: ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              Text(
                                                topUp.paymentNumber.isNotEmpty ? topUp.paymentNumber : (topUp.senderPhone ?? ''),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (topUp.senderPhone != null && topUp.senderPhone!.isNotEmpty && topUp.paymentNumber.isNotEmpty)
                                            Text(
                                              'প্রেরক: ${topUp.senderPhone}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Admin Note / Failure Reason Banner
                              if (topUp.adminNote != null && topUp.adminNote!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.info_outline, size: 14, color: AppColors.error),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'মন্তব্য: ${topUp.adminNote}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
