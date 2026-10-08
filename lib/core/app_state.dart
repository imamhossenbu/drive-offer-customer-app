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

    // Prices >= 10000 are in poisha (100 poisha = 1 BDT, e.g. 500 BDT = 50000 poisha)
    final regPrice = regPriceNum >= 10000 ? regPriceNum / 100 : regPriceNum.toDouble();
    final sellPrice = sellPriceNum >= 10000 ? sellPriceNum / 100 : sellPriceNum.toDouble();

    final opRaw = json['operator'] ?? json['operatorId'];
    final op = (opRaw is Map
            ? (opRaw['code'] ?? opRaw['name'] ?? 'GP')
            : (opRaw ?? json['operatorName'] ?? 'GP'))
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
  final String? recipientPhone;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.status,
    required this.description,
    required this.createdAt,
    this.recipientPhone,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final amtNum = (json['amount'] ?? 0) as num;
    final amt = amtNum > 1000 ? amtNum / 100 : amtNum.toDouble();

    final balNum = (json['balanceAfter'] ?? 0) as num;
    final bal = balNum > 1000 ? balNum / 100 : balNum.toDouble();

    final desc = json['description']?.toString() ?? json['note']?.toString() ?? '';
    String? phone = json['recipientPhone']?.toString();
    if ((phone == null || phone.isEmpty) && json['metadata'] is Map) {
      phone = json['metadata']['recipientPhone']?.toString();
    }
    if (phone == null || phone.isEmpty) {
      final match = RegExp(r'(01[3-9]\d{8})').firstMatch(desc);
      if (match != null) {
        phone = match.group(1);
      }
    }

    return TransactionModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      type: json['type']?.toString().toUpperCase() ?? 'TOPUP',
      amount: amt,
      balanceAfter: bal,
      status: json['status']?.toString().toUpperCase() ?? 'COMPLETED',
      description: desc,
      createdAt: json['createdAt']?.toString() ?? '',
      recipientPhone: phone,
    );
  }
}

class TopUpItem {
  final String id;
  final String topUpNumber;
  final String provider;
  final double amount;
  final String status;
  final String transactionId;
  final String paymentNumber;
  final String? senderPhone;
  final String createdAt;
  final String? adminNote;

  TopUpItem({
    required this.id,
    required this.topUpNumber,
    required this.provider,
    required this.amount,
    required this.status,
    required this.transactionId,
    required this.paymentNumber,
    this.senderPhone,
    required this.createdAt,
    this.adminNote,
  });

  factory TopUpItem.fromJson(Map<String, dynamic> json) {
    final amtBdt = json['amountBdt'];
    final amtNum = (json['amount'] ?? 0) as num;
    final double amt = amtBdt != null
        ? (amtBdt as num).toDouble()
        : (amtNum > 1000 ? amtNum / 100.0 : amtNum.toDouble());

    final prov = (json['paymentProvider'] ?? json['provider'] ?? 'BKASH').toString().toUpperCase();
    final txId = (json['customerTransactionId'] ?? json['transactionId'] ?? '').toString().trim();
    final pNum = (json['paymentNumber'] ?? '').toString().trim();
    final sPhone = json['senderPhone']?.toString().trim();

    return TopUpItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      topUpNumber: json['topUpNumber']?.toString() ?? '',
      provider: prov,
      amount: amt,
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      transactionId: txId,
      paymentNumber: pNum,
      senderPhone: (sPhone != null && sPhone.isNotEmpty) ? sPhone : null,
      createdAt: json['createdAt']?.toString() ?? '',
      adminNote: json['adminNote']?.toString() ?? json['failureReason']?.toString(),
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
  List<TopUpItem> _topUps = [];
  List<NotificationItem> _notifications = [];
  List<Map<String, dynamic>> _rawOperators = [];
  Map<String, dynamic> _serviceStatus = {};

  bool _isLoadingOffers = false;
  bool _isLoadingOrders = false;
  bool _isLoadingTransactions = false;
  bool _isLoadingTopUps = false;

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
  List<TopUpItem> get topUps => _topUps;
  List<NotificationItem> get notifications => _notifications;
  List<Map<String, dynamic>> get operators => _rawOperators;
  Map<String, dynamic> get serviceStatus => _serviceStatus;

  bool get isLoadingOffers => _isLoadingOffers;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isLoadingTopUps => _isLoadingTopUps;

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
      _driveOffers = [];
      _regularOffers = [];
      _orders = [];
      _transactions = [];
      notifyListeners();
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
      fetchTopUps(),
      fetchNotifications(),
      fetchServiceStatus(),
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
          if (w['balanceBdt'] != null) {
            _balance = (w['balanceBdt'] as num).toDouble();
          } else {
            final balPoisha = (w['balance'] as num?)?.toDouble() ?? 0.0;
            _balance = balPoisha / 100.0;
          }
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
    if (!_isLoggedIn) {
      _driveOffers = [];
      _regularOffers = [];
      _isLoadingOffers = false;
      notifyListeners();
      return;
    }
    _isLoadingOffers = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        CustomerApiService.instance.getDriveOffers(),
        CustomerApiService.instance.getRegularOffers(),
        CustomerApiService.instance.getOperators(),
      ]);

      List extractList(dynamic data) {
        if (data == null) return [];
        if (data is List) return data;
        if (data is Map) {
          if (data['docs'] is List) return data['docs'] as List;
          if (data['data'] is List) return data['data'] as List;
          if (data['items'] is List) return data['items'] as List;
          if (data['offers'] is List) return data['offers'] as List;
        }
        return [];
      }

      final dData = results[0]['data'] ?? results[0];
      final rData = results[1]['data'] ?? results[1];
      final opData = results[2]['data'] ?? results[2];

      final List dList = extractList(dData);
      final List rList = extractList(rData);
      final List opList = extractList(opData);

      _driveOffers = dList.map((e) => DriveOffer.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      _regularOffers = rList.map((e) => DriveOffer.fromJson(Map<String, dynamic>.from(e as Map))).toList();

      if (opList.isNotEmpty) {
        _rawOperators = opList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}

    _isLoadingOffers = false;
    notifyListeners();
  }

  Future<void> fetchOrders({bool isSilent = false}) async {
    if (!isSilent) {
      _isLoadingOrders = true;
      notifyListeners();
    }
    try {
      final res = await CustomerApiService.instance.getOrders();
      final data = res['data'];
      final List list = (data is List ? data : (data?['orders'] is List ? data['orders'] : (data?['docs'] is List ? data['docs'] : [])));
      _orders = list.map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {}
    if (!isSilent) _isLoadingOrders = false;
    notifyListeners();
  }

  Future<void> fetchTransactions({bool isSilent = false}) async {
    if (!isSilent) {
      _isLoadingTransactions = true;
      notifyListeners();
    }
    try {
      final res = await CustomerApiService.instance.getWalletTransactions();
      final data = res['data'];
      final List list = (data is List ? data : (data?['transactions'] is List ? data['transactions'] : (data?['docs'] is List ? data['docs'] : [])));
      _transactions = list.map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {}
    if (!isSilent) _isLoadingTransactions = false;
    notifyListeners();
  }

  Future<void> fetchTopUps({bool isSilent = false}) async {
    if (!isSilent) {
      _isLoadingTopUps = true;
      notifyListeners();
    }
    try {
      final res = await CustomerApiService.instance.getTopUps();
      final data = res['data'];
      final List list = (data is List ? data : (data?['topUps'] is List ? data['topUps'] : (data?['docs'] is List ? data['docs'] : [])));
      final seenIds = <String>{};
      final seenTxKeys = <String>{};
      _topUps = list
          .map((e) => TopUpItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((item) {
            if (item.id.isEmpty) return false;
            // Prevent duplicate MongoDB IDs
            if (!seenIds.add(item.id)) return false;
            // Prevent duplicate transaction IDs for same provider
            if (item.transactionId.isNotEmpty) {
              final key = '${item.provider}_${item.transactionId.toUpperCase()}';
              if (!seenTxKeys.add(key)) return false;
            }
            return true;
          })
          .toList();
    } catch (_) {}
    if (!isSilent) _isLoadingTopUps = false;
    notifyListeners();
  }

  Future<void> fetchServiceStatus() async {
    try {
      final res = await CustomerApiService.instance.getSettings();
      final data = res['data'] ?? res;
      if (data is Map && data['serviceStatus'] is Map) {
        _serviceStatus = Map<String, dynamic>.from(data['serviceStatus'] as Map);
        notifyListeners();
      }
    } catch (_) {}
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
    _totalAdded = 0.0;
    _totalSpent = 0.0;
    _driveOffers.clear();
    _regularOffers.clear();
    _orders.clear();
    _transactions.clear();
    _notifications.clear();
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
