import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/constants.dart';
import '../core/sound_service.dart';
import '../core/app_update_service.dart';
import 'home/home_screen.dart';
import 'offers/offers_screen.dart';
import 'wallet/add_money_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';
import 'auth/login_screen.dart';

class CustomerMain extends StatefulWidget {
  final int initialTab;
  const CustomerMain({super.key, this.initialTab = 0});

  @override
  State<CustomerMain> createState() => _CustomerMainState();
}

class _CustomerMainState extends State<CustomerMain> with WidgetsBindingObserver {
  late int _currentIndex;
  Timer? _statusTimer;

  /// Live sync interval. Was 4s (5 requests every 4s per open app), which burned
  /// through the hosting bandwidth quota. Responses are also ETag-cached now.
  static const Duration _pollInterval = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AppState>().isLoggedIn) {
        context.read<AppState>().syncFromStorage();
        context.read<AppState>().refreshAll();
      }
      _checkForUpdate();
    });
    _startPolling();
  }

  DateTime? _lastUpdateCheck;

  /// Shows the update screen when a newer version is published. Runs at start
  /// and when the app comes back to the foreground, at most every 6 hours.
  void _checkForUpdate() {
    final now = DateTime.now();
    if (_lastUpdateCheck != null && now.difference(_lastUpdateCheck!) < const Duration(hours: 6)) {
      return;
    }
    _lastUpdateCheck = now;
    if (mounted) AppUpdateService.instance.checkForUpdate(context);
  }

  void _startPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(_pollInterval, (_) => _syncNow());
  }

  void _syncNow() {
    if (mounted && context.read<AppState>().isLoggedIn) {
      final app = context.read<AppState>();
      app.fetchMe();
      app.fetchOrders(isSilent: true);
      app.fetchTopUps(isSilent: true);
      app.fetchServiceStatus();
      app.fetchNotifications();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Back in front: refresh immediately, then resume periodic sync.
      _syncNow();
      _startPolling();
      _checkForUpdate();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // App in background / screen off: stop polling entirely.
      _statusTimer?.cancel();
      _statusTimer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusTimer?.cancel();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      SoundService.playTap();
      setState(() => _currentIndex = index);
      final app = context.read<AppState>();
      if (index == 2) {
        app.fetchMe();
        app.fetchTopUps();
      } else if (index == 3) {
        app.fetchOrders();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (!app.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = [
      HomeScreen(onNavigateTab: _onTabSelected),
      const OffersScreen(),
      const AddMoneyScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey.shade500,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: app.isBn ? 'হোম' : 'Home',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.local_offer_outlined),
                  activeIcon: const Icon(Icons.local_offer),
                  label: app.isBn ? 'অফারসমূহ' : 'Offers',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _currentIndex == 2 ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_card,
                      color: _currentIndex == 2 ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  label: app.isBn ? 'এড মানি' : 'Add Money',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.receipt_long_outlined),
                      if (app.pendingOrdersCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${app.pendingOrdersCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: const Icon(Icons.receipt_long),
                  label: app.isBn ? 'অর্ডারস' : 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: app.isBn ? 'প্রোফাইল' : 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
