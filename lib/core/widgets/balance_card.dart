import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../constants.dart';
import '../../features/wallet/add_money_screen.dart';
import '../../features/wallet/transaction_history_screen.dart';

class BalanceCard extends StatelessWidget {
  final VoidCallback? onAddMoneyTap;
  final VoidCallback? onHistoryTap;

  const BalanceCard({
    super.key,
    this.onAddMoneyTap,
    this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isBn = state.isBn;
    final isVisible = state.balanceVisible;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient Circles
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag: Wallet Title & Refresh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.t('wallet_balance'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD1FAE5),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),

                    // Tap to reveal helper
                    InkWell(
                      onTap: () => state.toggleBalanceVisibility(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 14,
                              color: const Color(0xFFA7F3D0),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isVisible
                                  ? (isBn ? 'লুকান' : 'Hide')
                                  : (isBn ? 'দেখুন' : 'Show'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Interactive Balance Value
                InkWell(
                  onTap: () => state.toggleBalanceVisibility(),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                    child: isVisible
                        ? Text(
                            state.formatCurrency(state.balance),
                            key: const ValueKey('visible_balance'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          )
                        : Container(
                            key: const ValueKey('hidden_balance'),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF86EFAC)),
                                const SizedBox(width: 6),
                                Text(
                                  state.t('tap_to_view_balance'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),

                // Divider Line
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 14),

                // Bottom Action Buttons (Add Money & Transactions History)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAddMoneyTap ??
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddMoneyScreen()),
                              ).then((_) => state.fetchMe());
                            },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
                        label: Text(
                          state.t('add_money'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onHistoryTap ??
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                              );
                            },
                        icon: const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.white),
                        label: Text(
                          state.t('transactions'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

typedef CustomerBalanceCard = BalanceCard;
