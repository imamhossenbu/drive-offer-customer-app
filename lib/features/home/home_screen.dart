import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/sound_service.dart';
import '../../core/widgets/balance_card.dart';
import '../../core/widgets/offer_card.dart';
import '../notifications/notifications_screen.dart';
import '../offers/offer_detail_sheet.dart';
import '../wallet/transaction_history_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await app.refreshAll();
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context, app),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Balance Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: BalanceCard(
                      onAddMoneyTap: () => onNavigateTab(2),
                      onHistoryTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                        );
                      },
                    ),
                  ),

                  // Notice Ticker if any
                  _buildNoticeTicker(app),

                  const SizedBox(height: 16),
                  // Quick Operator Selector
                  _buildOperatorSection(context, app),

                  const SizedBox(height: 20),
                  // Quick Actions Grid
                  _buildQuickActionGrid(context, app),

                  const SizedBox(height: 24),
                  // Trending Drive Offers Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              app.isBn ? 'জনপ্রিয় ড্রাইভ অফারসমূহ' : 'Trending Drive Offers',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => onNavigateTab(1),
                          child: Row(
                            children: [
                              Text(
                                app.isBn ? 'সব দেখুন' : 'See All',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Offers List
                  _buildTrendingOffers(context, app),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppState app) {
    return SliverAppBar(
      backgroundColor: AppColors.primary,
      expandedHeight: 80,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      app.userName.isNotEmpty ? app.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.isBn ? 'স্বাগতম!' : 'Welcome,',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                      Text(
                        app.userName.isNotEmpty ? app.userName : 'Customer',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),

              // Actions (Language switcher + Notifications)
              Row(
                children: [
                  // Language Switcher
                  InkWell(
                    onTap: () {
                      SoundService.playTap();
                      app.toggleLanguage();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            app.isBn ? 'ENG' : 'বাংলা',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Notification Bell
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                        if (app.unreadNotificationsCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                              child: Text(
                                '${app.unreadNotificationsCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      SoundService.playTap();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeTicker(AppState app) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              app.isBn
                  ? '⚡ সকল ড্রাইভ অফার দ্রুত ডেলিভারি চালু আছে! ৫-১০ মিনিটের মধ্যে এক্টিভ হবে।'
                  : '⚡ Instant Drive Offers processing is active! Delivered within 5-10 minutes.',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorSection(BuildContext context, AppState app) {
    final operators = [
      {'id': 'ALL', 'name': app.isBn ? 'সকল' : 'All', 'icon': null},
      {'id': 'GP', 'name': 'Grameenphone', 'color': const Color(0xFF0091DA)},
      {'id': 'ROBI', 'name': 'Robi', 'color': const Color(0xFFED1C24)},
      {'id': 'BANGLALINK', 'name': 'Banglalink', 'color': const Color(0xFFFF6600)},
      {'id': 'AIRTEL', 'name': 'Airtel', 'color': const Color(0xFFE60000)},
      {'id': 'TELETALK', 'name': 'Teletalk', 'color': const Color(0xFF00A651)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            app.isBn ? 'অপারেটর নির্বাচন করুন' : 'Select Operator',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: operators.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, index) {
              final op = operators[index];
              final isSelected = app.selectedOperator == op['id'];

              return InkWell(
                onTap: () {
                  SoundService.playTap();
                  app.setOperator(op['id'] as String);
                },
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      op['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionGrid(BuildContext context, AppState app) {
    final actions = [
      {
        'title': app.isBn ? 'ড্রাইভ অফার' : 'Drive Offers',
        'icon': Icons.flash_on,
        'color': const Color(0xFF107C41),
        'tab': 1,
      },
      {
        'title': app.isBn ? 'টপ-আপ / ব্যালেন্স' : 'Add Balance',
        'icon': Icons.account_balance_wallet,
        'color': const Color(0xFFD97706),
        'tab': 2,
      },
      {
        'title': app.isBn ? 'অর্ডার হিস্ট্রি' : 'My Orders',
        'icon': Icons.inventory_2_outlined,
        'color': const Color(0xFF2563EB),
        'tab': 3,
      },
      {
        'title': app.isBn ? 'লেনদেন বিবরণ' : 'Transactions',
        'icon': Icons.receipt_long,
        'color': const Color(0xFF7C3AED),
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
          );
        },
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: actions.map((item) {
          return Expanded(
            child: InkWell(
              onTap: () {
                SoundService.playTap();
                if (item.containsKey('tab')) {
                  onNavigateTab(item['tab'] as int);
                } else if (item.containsKey('action')) {
                  (item['action'] as VoidCallback)();
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendingOffers(BuildContext context, AppState app) {
    if (app.isLoadingOffers && app.driveOffers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final filtered = app.driveOffers.where((offer) {
      if (app.selectedOperator != 'ALL' && offer.operator.toUpperCase() != app.selectedOperator) {
        return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              app.isBn ? 'কোন অফার পাওয়া যায়নি' : 'No offers currently available',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filtered.length > 5 ? 5 : filtered.length,
      itemBuilder: (ctx, index) {
        final offer = filtered[index];
        return OfferCard(
          offer: offer,
          onTap: () {
            SoundService.playTap();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => OfferDetailSheet(offer: offer),
            );
          },
        );
      },
    );
  }
}
