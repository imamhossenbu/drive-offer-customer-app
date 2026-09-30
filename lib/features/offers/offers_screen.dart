import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/sound_service.dart';
import '../../core/widgets/offer_card.dart';
import '../../core/widgets/operator_badge.dart';
import 'offer_detail_sheet.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    final Map<String, String> defaultAssets = {
      'GP': 'assets/operators/gp.png',
      'ROBI': 'assets/operators/robi.png',
      'BANGLALINK': 'assets/operators/banglalink.png',
      'BL': 'assets/operators/banglalink.png',
      'AIRTEL': 'assets/operators/airtel.png',
      'TELETALK': 'assets/operators/teletalk.png',
    };

    final List<Map<String, dynamic>> operators = [
      {'id': 'ALL', 'name': app.isBn ? 'সকল' : 'All', 'asset': null, 'logoUrl': null},
    ];

    if (app.operators.isNotEmpty) {
      for (final op in app.operators) {
        final code = (op['code'] ?? '').toString().toUpperCase();
        final name = (op['name'] ?? code).toString();
        final key = OperatorBadge.cleanKey(code.isNotEmpty ? code : name);
        operators.add({
          'id': code.isNotEmpty ? code : (op['id']?.toString() ?? name),
          'name': name,
          'asset': defaultAssets[code] ?? 'assets/operators/$key.png',
          'logoUrl': op['logoUrl']?.toString(),
        });
      }
    } else {
      operators.addAll([
        {'id': 'GP', 'name': 'GP', 'asset': 'assets/operators/gp.png', 'logoUrl': null},
        {'id': 'ROBI', 'name': 'Robi', 'asset': 'assets/operators/robi.png', 'logoUrl': null},
        {'id': 'BANGLALINK', 'name': 'BL', 'asset': 'assets/operators/banglalink.png', 'logoUrl': null},
        {'id': 'AIRTEL', 'name': 'Airtel', 'asset': 'assets/operators/airtel.png', 'logoUrl': null},
        {'id': 'TELETALK', 'name': 'Teletalk', 'asset': 'assets/operators/teletalk.png', 'logoUrl': null},
      ]);
    }

    // Dynamic Category Extraction based on actual offers data
    final Set<String> rawCatSet = {'ALL'};
    final allOffers = [...app.driveOffers, ...app.regularOffers];
    for (final o in allOffers) {
      if (app.selectedOperator == 'ALL' || o.operator.toUpperCase() == app.selectedOperator) {
        if (o.category.trim().isNotEmpty) {
          rawCatSet.add(o.category.trim().toUpperCase());
        }
      }
    }
    // Guarantee base categories are present
    rawCatSet.addAll(['INTERNET', 'MINUTE', 'COMBO']);

    final Map<String, String> catNameBn = {
      'ALL': 'সকল প্যাকেজ',
      'INTERNET': 'ইন্টারনেট',
      'MINUTE': 'মিনিট',
      'COMBO': 'কম্বো / বান্ডেল',
      'SPECIAL': 'স্পেশাল',
      'CASHBACK': 'ক্যাশব্যাক',
    };
    final Map<String, String> catNameEn = {
      'ALL': 'All Packages',
      'INTERNET': 'Internet',
      'MINUTE': 'Minutes',
      'COMBO': 'Combo / Bundle',
      'SPECIAL': 'Special',
      'CASHBACK': 'Cashback',
    };

    final categories = rawCatSet.map((catId) {
      final nameBn = catNameBn[catId] ?? catId;
      final nameEn = catNameEn[catId] ?? catId;
      return {
        'id': catId,
        'name': app.isBn ? nameBn : nameEn,
      };
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          app.isBn ? 'টেলিকম অফারসমূহ' : 'Telecom Offers',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: app.isBn ? '🔥 ড্রাইভ অফার' : '🔥 Drive Offers'),
            Tab(text: app.isBn ? '⚡ সাধারণ অফার' : '⚡ Regular Offers'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filters Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: app.isBn ? 'অফার বা প্যাকেজ খুঁজুন (যেমন 50GB, 1000 Min)...' : 'Search offers (e.g. 50GB, 800 Min)...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),

                // Operator Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: operators.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, index) {
                      final op = operators[index];
                      final isSelected = app.selectedOperator == op['id'];
                      final asset = op['asset'] as String?;
                      final logoUrl = op['logoUrl'] as String?;

                      return InkWell(
                        onTap: () {
                          SoundService.playTap();
                          app.setOperator(op['id']!);
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey.shade300,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (logoUrl != null && logoUrl.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Image.network(
                                    logoUrl,
                                    width: 18,
                                    height: 18,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => asset != null
                                        ? Image.asset(asset, width: 18, height: 18, fit: BoxFit.contain)
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ] else if (asset != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Image.asset(asset, width: 18, height: 18, fit: BoxFit.contain),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                op['name']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Category Filter Chips
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, index) {
                      final cat = categories[index];
                      final isSelected = app.selectedCategory == cat['id'];

                      return InkWell(
                        onTap: () {
                          SoundService.playTap();
                          app.setCategory(cat['id']!);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.secondary.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.secondary : Colors.grey.shade300,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat['name']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // TabBar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOfferList(app, app.driveOffers, isDrive: true),
                _buildOfferList(app, app.regularOffers, isDrive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferList(AppState app, List<DriveOffer> offers, {required bool isDrive}) {
    if (app.isLoadingOffers && offers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final filtered = offers.where((offer) {
      if (app.selectedOperator != 'ALL' && offer.operator.toUpperCase() != app.selectedOperator) {
        return false;
      }
      if (app.selectedCategory != 'ALL' && offer.category.toUpperCase() != app.selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery;
        final matchTitle = offer.title.toLowerCase().contains(query);
        final matchOp = offer.operator.toLowerCase().contains(query);
        final matchLoc = offer.location.toLowerCase().contains(query);
        if (!matchTitle && !matchOp && !matchLoc) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => app.refreshAll(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    app.isBn ? 'কোন অফার পাওয়া যায়নি' : 'No offers match your criteria',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    app.isBn ? 'অন্য ফিল্টার বা অপারেটর দিয়ে চেষ্টা করুন।' : 'Try selecting a different operator or filter.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => app.refreshAll(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: filtered.length,
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
      ),
    );
  }
}
