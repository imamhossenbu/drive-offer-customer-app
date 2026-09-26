import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'auth_storage.dart';
import 'sound_service.dart';

// ── Typed Models ─────────────────────────────────────────────────────────────

class DriveOffer {
  final String id;
  final String title;
  final String operator;
  final String category;
  final double price;
  final double discountPrice;
  final double commission;
  final String validity;
  final String location;
  final String type; // "DRIVE" or "REGULAR"

  DriveOffer({
    required this.id,
    required this.title,
    required this.operator,
    required this.category,
    required this.price,
    required this.discountPrice,
    required this.commission,
    required this.validity,
    required this.location,
    required this.type,
  });

  factory DriveOffer.fromJson(Map<String, dynamic> json) {
    final regPriceNum = (json['regularPrice'] ?? json['price'] ?? json['originalPrice'] ?? 0) as num;
    final sellPriceNum = (json['sellingPrice'] ?? json['discountPrice'] ?? regPriceNum) as num;

    final regPrice = regPriceNum > 1000 ? regPriceNum / 100 : regPriceNum.toDouble();
    final sellPrice = sellPriceNum > 1000 ? sellPriceNum / 100 : sellPriceNum.toDouble();

    final op = (json['operator'] is Map
            ? (json['operator']['code'] ?? json['operator']['name'])
            : (json['operator'] ?? json['operatorName'] ?? 'GP'))
        .toString()
        .toUpperCase();

    return DriveOffer(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? json['offerName']?.toString() ?? 'Special Offer',
      operator: op,
      category: json['category']?.toString().toUpperCase() ?? 'INTERNET',
      price: regPrice,
      discountPrice: sellPrice,
      commission: ((json['cashback'] ?? json['commission'] ?? 0) as num).toDouble(),
      validity: json['validity']?.toString() ?? '30 Days',
      location: json['location']?.toString() ?? json['division']?.toString() ?? 'ALL',
      type: json['type']?.toString().toUpperCase() ?? 'DRIVE',
    );
  }
}

class OrderModel {
  final String id;
  final String offerTitle;
  final String operator;
  final String phone;
  final double price;
  final String status;
  final String createdAt;

  OrderModel({
    required this.id,
    required this.offerTitle,
    required this.operator,
    required this.phone,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final priceNum = (json['price'] ?? json['amount'] ?? 0) as num;
    final price = priceNum > 1000 ? priceNum / 100 : priceNum.toDouble();

    final offer = json['offer'] is Map ? json['offer'] : {};
    final title = json['offerTitle'] ?? offer['title'] ?? offer['name'] ?? 'Data Pack';
    final op = (json['operator'] ?? offer['operator'] ?? 'GP').toString();

    return OrderModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      offerTitle: title.toString(),
      operator: op,
      phone: json['phone']?.toString() ?? json['recipientPhone']?.toString() ?? '',
      price: price,
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class TransactionModel {
  final String id;
  final String type;
  final double amount;
  final double balanceAfter;
  final String status;
  final String description;
  final String createdAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final amtNum = (json['amount'] ?? 0) as num;
    final amt = amtNum > 1000 ? amtNum / 100 : amtNum.toDouble();

    final balNum = (json['balanceAfter'] ?? 0) as num;
    final bal = balNum > 1000 ? balNum / 100 : balNum.toDouble();

    return TransactionModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      type: json['type']?.toString().toUpperCase() ?? 'TOPUP',
      amount: amt,
      balanceAfter: bal,
      status: json['status']?.toString().toUpperCase() ?? 'COMPLETED',
      description: json['description']?.toString() ?? json['note']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? json['body']?.toString() ?? '',
      isRead: json['isRead'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

// ── AppState / CustomerAppState ──────────────────────────────────────────────

class AppState extends ChangeNotifier {
  // Session & User
  bool _isLoggedIn = false;
  Map<String, dynamic> _user = {};
  double _balance = 0.0;
  double _totalAdded = 0.0;
  double _totalSpent = 0.0;
  bool _balanceVisible = false;
  Timer? _balanceHideTimer;

  // Navigation
  int _selectedTabIndex = 0;

  // Localization
  String _lang = 'bn'; // 'bn' or 'en'

  // Filter States
  String _selectedOperator = 'ALL';
  String _selectedCategory = 'ALL';

  // Data Collections
  List<DriveOffer> _driveOffers = [];
  List<DriveOffer> _regularOffers = [];
  List<OrderModel> _orders = [];
  List<TransactionModel> _transactions = [];
  List<NotificationItem> _notifications = [];
  List<Map<String, dynamic>> _rawOperators = [];

  bool _isLoadingOffers = false;
  bool _isLoadingOrders = false;
  bool _isLoadingTransactions = false;

  // ── Getters ──────────────────────────────────────────────────────────────
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic> get user => _user;
  String get userName => _user['name']?.toString() ?? AuthStorage.getUserName();
  String get userEmail => _user['email']?.toString() ?? AuthStorage.getUserEmail();
  String get userPhone => _user['phone']?.toString() ?? AuthStorage.getUserPhone();
  String get kycStatus => _user['kycStatus']?.toString() ?? AuthStorage.getKycStatus();
  bool get isKycVerified => kycStatus.toUpperCase() == 'VERIFIED';
  bool get isKycPending => kycStatus.toUpperCase() == 'PENDING' || kycStatus.toUpperCase() == 'UNDER_REVIEW';

  double get balance => _balance;
  double get walletBalance => _balance;
  double get totalAdded => _totalAdded;
  double get totalSpent => _totalSpent;
  bool get balanceVisible => _balanceVisible;
  int get selectedTabIndex => _selectedTabIndex;
  String get lang => _lang;
  bool get isBn => _lang == 'bn';

  String get selectedOperator => _selectedOperator;
  String get selectedCategory => _selectedCategory;

  List<DriveOffer> get driveOffers => _driveOffers;
  List<DriveOffer> get regularOffers => _regularOffers;
  List<OrderModel> get orders => _orders;
  List<TransactionModel> get transactions => _transactions;
  List<NotificationItem> get notifications => _notifications;
  List<Map<String, dynamic>> get operators => _rawOperators;

  bool get isLoadingOffers => _isLoadingOffers;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingTransactions => _isLoadingTransactions;

  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;
  int get pendingOrdersCount => _orders.where((o) => o.status == 'PENDING' || o.status == 'PROCESSING').length;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    await AuthStorage.init();
    _lang = AuthStorage.getLanguage();
    _isLoggedIn = AuthStorage.isLoggedIn;
    if (_isLoggedIn) {
      await syncFromStorage();
      await refreshAll();
    } else {
      await fetchOffers();
    }
  }

  Future<void> syncFromStorage() async {
    _isLoggedIn = AuthStorage.isLoggedIn;
    _lang = AuthStorage.getLanguage();
    notifyListeners();
  }

  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setOperator(String op) {
    _selectedOperator = op;
    notifyListeners();
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  // ── Tap-to-reveal balance with auto-hide timer ───────────────────────────
  void toggleBalanceVisibility() {
    _balanceVisible = !_balanceVisible;
    _balanceHideTimer?.cancel();
    if (_balanceVisible) {
      SoundService.playTap();
      _balanceHideTimer = Timer(const Duration(seconds: 5), () {
        _balanceVisible = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  // ── Localization ─────────────────────────────────────────────────────────
  void toggleLanguage() {
    _lang = _lang == 'bn' ? 'en' : 'bn';
    AuthStorage.setLanguage(_lang);
    notifyListeners();
  }

  void setLanguage(String languageCode) {
    _lang = languageCode;
    AuthStorage.setLanguage(_lang);
    notifyListeners();
  }

  String formatCurrency(num amount) {
    final formatted = NumberFormat('#,##,##0.00', 'en_US').format(amount);
    if (_lang == 'bn') {
      return '৳ ${toBengaliNumerals(formatted)}';
    }
    return '৳ $formatted';
  }

  String formatNumber(dynamic value) {
    final numStr = value?.toString() ?? '0';
    if (_lang == 'bn') {
      return toBengaliNumerals(numStr);
    }
    return numStr;
  }

  String toBengaliNumerals(String input) {
    const englishToBengali = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
    };
    return input.split('').map((ch) => englishToBengali[ch] ?? ch).join('');
  }

  String t(String key) {
    return _translations[key]?[_lang] ?? key;
  }

  // ── Live Data Synchronization ────────────────────────────────────────────

  Future<void> refreshAll() async {
    await Future.wait([
      fetchMe(),
      fetchOffers(),
      fetchOrders(),
      fetchTransactions(),
      fetchNotifications(),
    ]);
  }

  Future<void> fetchMe() async {
    try {
      final res = await CustomerApiService.instance.getMe();
      if (res['data'] != null) {
        final d = res['data'];
        _user = (d['user'] is Map) ? Map<String, dynamic>.from(d['user']) : (d is Map ? Map<String, dynamic>.from(d) : {});
        final w = d['wallet'] as Map<String, dynamic>?;
        if (w != null) {
          final balPoisha = (w['balance'] as num?)?.toDouble() ?? 0.0;
          _balance = balPoisha > 1000 ? balPoisha / 100 : balPoisha;
          _totalAdded = ((w['totalAdded'] as num?)?.toDouble() ?? 0.0) / 100;
          _totalSpent = ((w['totalSpent'] as num?)?.toDouble() ?? 0.0) / 100;
        }
        await AuthStorage.saveUser(
          id: _user['id'] ?? _user['_id'] ?? '',
          name: _user['name'] ?? 'Customer',
          email: _user['email'] ?? '',
          phone: _user['phone'] ?? '',
          kycStatus: _user['kycStatus'] ?? 'VERIFIED',
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchOffers() async {
    _isLoadingOffers = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        CustomerApiService.instance.getDriveOffers(),
        CustomerApiService.instance.getRegularOffers(),
        CustomerApiService.instance.getOperators(),
      ]);

      final dData = results[0]['data'];
      final rData = results[1]['data'];
      final opData = results[2]['data'];

      final List dList = (dData is List ? dData : (dData?['docs'] is List ? dData['docs'] : []));
      final List rList = (rData is List ? rData : (rData?['docs'] is List ? rData['docs'] : []));

      _driveOffers = dList.map((e) => DriveOffer.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      _regularOffers = rList.map((e) => DriveOffer.fromJson(Map<String, dynamic>.from(e as Map))).toList();

      if (opData is List) {
        _rawOperators = opData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}

    _isLoadingOffers = false;
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    _isLoadingOrders = true;
    try {
      final res = await CustomerApiService.instance.getOrders();
      final data = res['data'];
      final List list = (data is List ? data : (data?['orders'] is List ? data['orders'] : (data?['docs'] is List ? data['docs'] : [])));
      _orders = list.map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {}
    _isLoadingOrders = false;
    notifyListeners();
  }

  Future<void> fetchTransactions() async {
    _isLoadingTransactions = true;
    try {
      final res = await CustomerApiService.instance.getWalletTransactions();
      final data = res['data'];
      final List list = (data is List ? data : (data?['transactions'] is List ? data['transactions'] : (data?['docs'] is List ? data['docs'] : [])));
      _transactions = list.map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {}
    _isLoadingTransactions = false;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    try {
      final res = await CustomerApiService.instance.getNotifications();
      final data = res['data'];
      final List list = (data is List ? data : (data?['notifications'] is List ? data['notifications'] : []));
      _notifications = list.map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markNotificationAsRead(String id) async {
    try {
      await CustomerApiService.instance.markNotificationRead(id);
      await fetchNotifications();
    } catch (_) {}
  }

  void onLoginSuccess(Map<String, dynamic> userPayload) {
    _isLoggedIn = true;
    _user = userPayload;
    fetchMe();
    fetchOffers();
    fetchOrders();
    fetchTransactions();
    fetchNotifications();
    SoundService.playSuccess();
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthStorage.clearAuth();
    _isLoggedIn = false;
    _user = {};
    _balance = 0.0;
    _orders.clear();
    _transactions.clear();
    notifyListeners();
  }

  // ── Translation Dictionary ───────────────────────────────────────────────
  static final Map<String, Map<String, String>> _translations = {
    'brand_name': {'bn': 'আলোকিত টেলিকম', 'en': 'Alokito Telecom'},
    'home': {'bn': 'হোম', 'en': 'Home'},
    'drive_offers': {'bn': 'ড্রাইভ অফার', 'en': 'Drive Offers'},
    'regular_offers': {'bn': 'সাধারণ অফার', 'en': 'Regular Packs'},
    'add_money': {'bn': 'ব্যালেন্স যোগ', 'en': 'Add Money'},
    'orders': {'bn': 'অর্ডারসমূহ', 'en': 'Orders'},
    'profile': {'bn': 'প্রোফাইল', 'en': 'Profile'},
    'wallet_balance': {'bn': 'বর্তমান ব্যালেন্স', 'en': 'Current Balance'},
    'tap_to_view_balance': {'bn': 'ব্যালেন্স দেখতে ট্যাপ করুন', 'en': 'Tap to view balance'},
    'transactions': {'bn': 'লেনদেন হিস্ট্রি', 'en': 'Transactions'},
    'kyc_verified': {'bn': 'KYC ভেরিফাইড', 'en': 'KYC Verified'},
    'kyc_pending': {'bn': 'KYC প্রক্রিয়াধীন', 'en': 'KYC In Review'},
    'kyc_unverified': {'bn': 'KYC আবশ্যক', 'en': 'KYC Required'},
    'buy_now': {'bn': 'অফার কিনুন', 'en': 'Buy Now'},
  };
}

typedef CustomerAppState = AppState;
