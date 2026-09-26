import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../constants.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';

class CustomerHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;

  const CustomerHeader({
    super.key,
    this.showBack = false,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CustomerAppState>();
    final isBn = state.lang == 'bn';
    final name = state.userName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              if (showBack)
                InkWell(
                  onTap: onBack ?? () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textDark),
                  ),
                )
              else
                Row(
                  children: [
                    // Brand Avatar / Initial Circle
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // KYC Badge Pill
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: state.isKycVerified
                                      ? AppColors.successBg
                                      : (state.isKycPending ? AppColors.warningBg : AppColors.dangerBg),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: state.isKycVerified
                                        ? const Color(0xFF86EFAC)
                                        : (state.isKycPending ? const Color(0xFFFDE68A) : const Color(0xFFFECACA)),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      state.isKycVerified
                                          ? Icons.verified_rounded
                                          : (state.isKycPending ? Icons.hourglass_top_rounded : Icons.warning_rounded),
                                      size: 11,
                                      color: state.isKycVerified
                                          ? AppColors.success
                                          : (state.isKycPending ? AppColors.warning : AppColors.danger),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      state.isKycVerified
                                          ? (isBn ? 'ভেরিফাইড' : 'Verified')
                                          : (state.isKycPending ? (isBn ? 'প্রক্রিয়াধীন' : 'Pending') : (isBn ? 'KYC নেই' : 'Unverified')),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: state.isKycVerified
                                            ? AppColors.success
                                            : (state.isKycPending ? AppColors.warning : AppColors.danger),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.userPhone.isNotEmpty ? state.userPhone : AppConstants.appName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              const Spacer(),

              // Language Toggle Pill
              InkWell(
                onTap: () => state.toggleLanguage(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.translate_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        isBn ? 'বাং' : 'EN',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Notification Bell
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined, size: 20, color: AppColors.textDark),
                      if (state.unreadNotificationsCount > 0)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              state.unreadNotificationsCount.toString(),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1,
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
}
