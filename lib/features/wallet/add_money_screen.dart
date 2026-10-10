import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/sound_service.dart';
import 'transaction_history_screen.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  String _selectedProvider = 'BKASH';
  final _amountController = TextEditingController();
  final _trxIdController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isLoadingGateways = true;

  Timer? _autoRefreshTimer;

  final Map<String, Map<String, dynamic>> _gateways = {
    'BKASH': {
      'name': 'bKash (বিকাশ)',
      'color': const Color(0xFFE2136E),
      'number': '',
      'type': 'Send Money (Personal)',
      'fee': '0%',
      'icon': 'assets/payments/bkash.png',
    },
    'NAGAD': {
      'name': 'Nagad (নগদ)',
      'color': const Color(0xFFF7941D),
      'number': '',
      'type': 'Send Money (Personal)',
      'fee': '0%',
      'icon': 'assets/payments/nagad.png',
    },
    'ROCKET': {
      'name': 'Rocket (রকেট)',
      'color': const Color(0xFF8C3494),
      'number': '',
      'type': 'Send Money (Personal)',
      'fee': '0%',
      'icon': 'assets/payments/rocket.png',
    },
    'UPAY': {
      'name': 'Upay (উপায়)',
      'color': const Color(0xFF0047BA),
      'number': '',
      'type': 'Send Money (Personal)',
      'fee': '0%',
      'icon': 'assets/payments/upay.png',
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().fetchTopUps();
      }
    });
    _loadDynamicPaymentGateways();
    // Real-time polling: auto-check every 3 seconds so changes from listener app reflect immediately
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _loadDynamicPaymentGateways(isSilent: true);
        context.read<AppState>().fetchTopUps();
        context.read<AppState>().fetchMe();
      }
    });
  }

  Future<void> _loadDynamicPaymentGateways({bool isSilent = false}) async {
    try {
      final results = await Future.wait([
        CustomerApiService.instance.getPaymentMethods().catchError((e) {
          debugPrint('getPaymentMethods error: $e');
          return <String, dynamic>{};
        }),
        CustomerApiService.instance.getSettings().catchError((e) {
          debugPrint('getSettings error: $e');
          return <String, dynamic>{};
        }),
      ]);

      final pmRes = results[0];
      final setRes = results[1];

      bool changed = false;

      // 1. Check active payment methods from payment-devices (highest priority: connected phone)
      final pmData = pmRes['data'] ?? pmRes;
      final List pmList = pmData is List
          ? pmData
          : (pmData?['methods'] is List ? pmData['methods'] : (pmData?['data'] is List ? pmData['data'] : []));

      final Set<String> updatedProviders = {};

      for (final item in pmList) {
        if (item is Map) {
          final prov = (item['provider'] ?? item['paymentProvider'] ?? '').toString().toUpperCase().trim();
          final phone = (item['paymentNumber'] ?? item['phoneNumber'] ?? '').toString().trim();
          if (prov.isNotEmpty && phone.isNotEmpty && _gateways.containsKey(prov)) {
            if (_gateways[prov]!['number'] != phone) {
              _gateways[prov]!['number'] = phone;
              changed = true;
            }
            updatedProviders.add(prov);
          }
        }
      }

      // 2. Check fallbackPaymentNumbers in systemSettings
      final setData = setRes['data'] ?? setRes;
      if (setData is Map && setData['fallbackPaymentNumbers'] is Map) {
        final fallbacks = setData['fallbackPaymentNumbers'] as Map;
        fallbacks.forEach((k, v) {
          final prov = k.toString().toUpperCase().trim();
          final phone = v?.toString().trim() ?? '';
          if (_gateways.containsKey(prov) && phone.isNotEmpty) {
            // Update if pmList didn't provide a number or if currently empty
            if (!updatedProviders.contains(prov) || (_gateways[prov]!['number'] as String).isEmpty) {
              if (_gateways[prov]!['number'] != phone) {
                _gateways[prov]!['number'] = phone;
                changed = true;
              }
            }
          }
        });
      }

      if (changed && mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading dynamic payment gateways: $e');
    }

    if (mounted && _isLoadingGateways) {
      setState(() => _isLoadingGateways = false);
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _amountController.dispose();
    _trxIdController.dispose();
    _senderPhoneController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('পেমেন্ট নম্বর এখনও সংযুক্ত করা হয়নি'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    SoundService.playTap();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('নম্বর কপি করা হয়েছে: $text'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সর্বনিম্ন ব্যালেন্স যোগ ২০ টাকা'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    SoundService.playTap();

    try {
      final app = context.read<AppState>();
      final senderPhone = _senderPhoneController.text.trim().isNotEmpty
          ? _senderPhoneController.text.trim()
          : app.userPhone;

      // 1-step atomic TopUp submission: sends provider, amount, trxId, senderPhone together
      final topUpRes = await CustomerApiService.instance.createTopUp(
        provider: _selectedProvider,
        amount: amount,
        transactionId: _trxIdController.text.trim(),
        senderPhone: senderPhone,
      );

      final data = topUpRes['data'] ?? topUpRes;
      final status = (data['status'] ?? '').toString().toUpperCase();
      final bool isImmediatelyVerified = data['isImmediatelyVerified'] == true || status == 'VERIFIED';

      await app.fetchMe();
      await app.fetchTransactions();
      await app.fetchTopUps();
      SoundService.playSuccess();

      if (!mounted) return;
      _amountController.clear();
      _trxIdController.clear();
      _senderPhoneController.clear();
      setState(() => _isLoading = false);

      _showTopUpSuccessDialog(amount, isImmediatelyVerified: isImmediatelyVerified);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showTopUpSuccessDialog(double amount, {bool isImmediatelyVerified = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isImmediatelyVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isImmediatelyVerified ? Icons.check_circle : Icons.hourglass_top_rounded,
                size: 54,
                color: isImmediatelyVerified ? AppColors.success : const Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isImmediatelyVerified ? 'ব্যালেন্স সফলভাবে যোগ হয়েছে!' : 'টপ-আপ রিকোয়েস্ট জমা হয়েছে!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isImmediatelyVerified
                  ? '৳${amount.toStringAsFixed(0)} আপনার মূল ওয়ালেটে সফলভাবে যোগ করা হয়েছে।'
                  : '৳${amount.toStringAsFixed(0)} টাকার রিকোয়েস্টটি দ্রুত ভেরিফাই হচ্ছে। এসএমএস পাওয়া মাত্র স্বয়ংক্রিয়ভাবে ব্যালেন্স যোগ হবে।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('ঠিক আছে', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final currentGateway = _gateways[_selectedProvider]!;

    final quickAmounts = [100, 200, 500, 1000, 2000];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          app.isBn ? 'ব্যালেন্স অ্যাড (টপ-আপ)' : 'Add Balance / Top-Up',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'রিফ্রেশ',
            onPressed: () {
              SoundService.playTap();
              _loadDynamicPaymentGateways();
              context.read<AppState>().fetchTopUps();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('তথ্য রিফ্রেশ করা হচ্ছে...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'টপ-আপ হিস্ট্রি',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransactionHistoryScreen(initialTabIndex: 1)),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadDynamicPaymentGateways(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.isBn ? 'বর্তমান ওয়ালেট ব্যালেন্স' : 'Current Wallet Balance',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '৳${app.walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Step 1: Select MFS Gateway
              Text(
                app.isBn ? '১. পেমেন্ট মেথড নির্বাচন করুন' : '1. Select Payment Method',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                children: _gateways.entries.map((entry) {
                  final key = entry.key;
                  final gw = entry.value;
                  final isSelected = _selectedProvider == key;

                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        SoundService.playTap();
                        setState(() => _selectedProvider = key);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? (gw['color'] as Color).withOpacity(0.12) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? (gw['color'] as Color) : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              gw['icon'] as String,
                              width: 36,
                              height: 36,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: gw['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    key[0],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              key,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? (gw['color'] as Color) : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Step 2: Payment Instructions & Copy Number
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: currentGateway['color'] as Color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          app.isBn ? 'টাকা পাঠানোর নিয়ম:' : 'Payment Instructions:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: currentGateway['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      app.isBn
                          ? 'আপনার ${currentGateway['name']} অ্যাপ থেকে নিচে দেওয়া নম্বরে ${currentGateway['type']} করুন।'
                          : 'Send Money to the number below from your ${currentGateway['name']} account.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _copyToClipboard(currentGateway['number'] as String),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${currentGateway['name']} Number',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                Text(
                                  (currentGateway['number'] as String).isNotEmpty
                                      ? (currentGateway['number'] as String)
                                      : (_isLoadingGateways
                                          ? (app.isBn ? 'লোড হচ্ছে...' : 'Loading...')
                                          : (app.isBn ? 'নম্বর উপলব্ধ নেই' : 'Not Available')),
                                  style: TextStyle(
                                    fontSize: (currentGateway['number'] as String).isNotEmpty ? 18 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: (currentGateway['number'] as String).isNotEmpty ? AppColors.textPrimary : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _copyToClipboard(currentGateway['number'] as String),
                              icon: const Icon(Icons.copy, size: 16),
                              label: Text(app.isBn ? 'কপি' : 'Copy'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentGateway['color'] as Color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Step 3: Enter Amount, TrxID & Sender Number
              Text(
                app.isBn ? '২. টাকার পরিমাণ ও TrxID দিন' : '2. Enter Amount & TrxID',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Amount (টাকার পরিমাণ ৳)',
                  prefixIcon: Icon(Icons.payments_outlined, color: AppColors.primary),
                  hintText: 'e.g. 500',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'টাকার পরিমাণ লিখুন';
                  final val = double.tryParse(v) ?? 0;
                  if (val < 20) return app.isBn ? 'সর্বনিম্ন ব্যালেন্স যোগ ২০ টাকা' : 'Minimum amount is ৳20';
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Quick Amount Chips
              Wrap(
                spacing: 8,
                children: quickAmounts.map((amt) {
                  return ActionChip(
                    label: Text('৳$amt'),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                    onPressed: () {
                      SoundService.playTap();
                      setState(() {
                        _amountController.text = amt.toString();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // TrxID Field
              TextFormField(
                controller: _trxIdController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Transaction ID (TrxID)',
                  prefixIcon: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
                  hintText: 'e.g. 9J83KA9281',
                  helperText: app.isBn ? 'এসএমএস থেকে TrxID কপি করে এখানে পেস্ট করুন' : 'Paste the TrxID received in SMS',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'TrxID লিখুন';
                  if (v.trim().length < 6) return 'সঠিক Transaction ID দিন';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sender Phone Number Field (Optional)
              TextFormField(
                controller: _senderPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: app.isBn ? 'যে নম্বর থেকে টাকা পাঠিয়েছেন (ঐচ্ছিক)' : 'Sender Phone Number (Optional)',
                  prefixIcon: const Icon(Icons.phone_android_outlined, color: AppColors.primary),
                  hintText: app.userPhone.isNotEmpty ? app.userPhone : 'e.g. 017xxxxxxxx',
                  helperText: app.isBn ? 'ফাঁকা রাখলে আপনার প্রোফাইল নম্বর ব্যবহার হবে' : 'Defaults to your registered phone number',
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          app.isBn ? 'ব্যালেন্স রিকোয়েস্ট সাবমিট করুন' : 'Submit Balance Request',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Recent Top-Up History Header
              Row(
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
                        app.isBn ? 'সাম্প্রতিক টপ-আপ হিস্ট্রি' : 'Recent Top-Up History',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  if (app.topUps.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        SoundService.playTap();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionHistoryScreen(initialTabIndex: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                      label: Text(
                        app.isBn ? 'সবগুলো দেখুন' : 'View All',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (app.topUps.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.history_rounded, size: 36, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        app.isBn ? 'এখনও কোনো টপ-আপ রিকোয়েস্ট নেই' : 'No top-up requests yet',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.isBn ? 'টাকা পাঠিয়ে ব্যালেন্স রিকোয়েস্ট সাবমিট করুন' : 'Submit a request to add balance',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              else
                ...app.topUps.take(5).map((topUp) {
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

                  final dateStr = TimeUtils.formatBst(topUp.createdAt);

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
                          // Top Row: Logo, Provider, Status Badge, Amount
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
                                    errorBuilder: (_, __, ___) => Icon(Icons.payment, color: provColor, size: 22),
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
                                          topUp.provider,
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

                          // Bottom Box: TrxID & Number Details
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                // TrxID Row with Copy Action
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
                                        onTap: () => _copyToClipboard(displayTxId),
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
                                // Number Row (Payment / Receiver & Sender)
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
                                children: [
                                  const Icon(Icons.info_outline, size: 14, color: AppColors.error),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      topUp.adminNote!,
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
                }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
