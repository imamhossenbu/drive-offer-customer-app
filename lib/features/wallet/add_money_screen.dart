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
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _gateways = {
    'BKASH': {
      'name': 'bKash (বিকাশ)',
      'color': const Color(0xFFE2136E),
      'number': '01890000001',
      'type': 'Send Money (Personal)',
      'fee': '0%',
      'icon': 'assets/images/bkash.png',
    },
    'NAGAD': {
      'name': 'Nagad (নগদ)',
      'color': const Color(0xFFF7941D),
      'number': '01890000002',
      'type': 'Send Money (Personal)',
      'fee': '0%',
      'icon': 'assets/images/nagad.png',
    },
    'ROCKET': {
      'name': 'Rocket (রকেট)',
      'color': const Color(0xFF8C3494),
      'number': '01890000003',
      'type': 'Send Money (Personal)',
      'fee': '0%',
      'icon': 'assets/images/rocket.png',
    },
    'UPAY': {
      'name': 'Upay (উপায়)',
      'color': const Color(0xFF0047BA),
      'number': '01890000004',
      'type': 'Send Money (Personal)',
      'fee': '0%',
      'icon': 'assets/images/upay.png',
    },
  };

  @override
  void dispose() {
    _amountController.dispose();
    _trxIdController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    SoundService.playTap();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('নম্বর কপি করা হয়েছে! (Copied to clipboard)'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum add money amount is ৳20'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    SoundService.playTap();

    try {
      // 1. Create TopUp record
      final topUpRes = await CustomerApiService.instance.createTopUp(
        provider: _selectedProvider,
        amount: amount,
      );

      final data = topUpRes['data'] ?? topUpRes;
      final topUpId = data['id']?.toString() ?? data['topUpId']?.toString() ?? '';

      // 2. Submit Transaction ID for verification
      if (topUpId.isNotEmpty) {
        await CustomerApiService.instance.verifyTopUp(
          topUpId: topUpId,
          transactionId: _trxIdController.text.trim(),
        );
      }

      if (!mounted) return;
      await context.read<AppState>().fetchMe();
      await context.read<AppState>().fetchTransactions();
      SoundService.playSuccess();

      _amountController.clear();
      _trxIdController.clear();
      setState(() => _isLoading = false);

      _showTopUpSuccessDialog(amount);
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

  void _showTopUpSuccessDialog(double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 54, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text(
              'টপ-আপ রিকোয়েস্ট গৃহীত হয়েছে!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              '৳${amount.toStringAsFixed(0)} টাকার রিকোয়েস্টটি দ্রুত যাচাই করে ব্যালেন্সে যোগ হবে।',
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
          app.isBn ? 'এড মানি (রিচার্জ)' : 'Add Money / Top-Up',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'লেনদেন বিবরণ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    Container(
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
                                currentGateway['number'] as String,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Step 3: Enter Amount & TrxID
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
                  if (val < 20) return 'সর্বনিম্ন রিচার্জ ২০ টাকা';
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
