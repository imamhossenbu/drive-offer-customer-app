import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/constants.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          app.isBn ? 'লেনদেন বিবরণ (Ledger)' : 'Transaction History',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
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
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(tx.createdAt) ?? DateTime.now())
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
                        // Icon Badge
                        Container(
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
                        ),
                        const SizedBox(width: 14),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.description.isNotEmpty ? tx.description : (isCredit ? 'Wallet Top-Up' : 'Offer Purchase'),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              if (tx.balanceAfter > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Balance: ৳${tx.balanceAfter.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
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
                                    : (tx.status == 'PENDING' ? AppColors.secondary.withOpacity(0.12) : AppColors.error.withOpacity(0.12)),
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
    );
  }
}
