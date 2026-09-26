import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/sound_service.dart';
import '../../core/widgets/operator_badge.dart';
import '../wallet/add_money_screen.dart';

class OfferDetailSheet extends StatefulWidget {
  final DriveOffer offer;

  const OfferDetailSheet({super.key, required this.offer});

  @override
  State<OfferDetailSheet> createState() => _OfferDetailSheetState();
}

class _OfferDetailSheetState extends State<OfferDetailSheet> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePin = true;
  String? _detectedOperator;

  @override
  void initState() {
    super.initState();
    // Default to customer's own phone if available
    final myPhone = context.read<AppState>().userPhone;
    if (myPhone.isNotEmpty) {
      _phoneController.text = myPhone;
      _detectOperator(myPhone);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _detectOperator(String number) {
    if (number.length >= 3) {
      final prefix = number.substring(0, 3);
      String? op;
      if (prefix == '017' || prefix == '013') op = 'GP';
      if (prefix == '018') op = 'ROBI';
      if (prefix == '019' || prefix == '014') op = 'BANGLALINK';
      if (prefix == '016') op = 'AIRTEL';
      if (prefix == '015') op = 'TELETALK';

      setState(() {
        _detectedOperator = op;
      });
    } else {
      setState(() {
        _detectedOperator = null;
      });
    }
  }

  Future<void> _handleConfirmOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final app = context.read<AppState>();
    final offerPrice = widget.offer.discountPrice > 0 ? widget.offer.discountPrice : widget.offer.price;

    if (app.walletBalance < offerPrice) {
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance! Please Add Money first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    SoundService.playTap();

    try {
      final res = await CustomerApiService.instance.createOrder(
        offerId: widget.offer.id,
        offerType: widget.offer.type,
        recipientPhone: _phoneController.text.trim(),
      );

      final data = res['data'] ?? res;
      final orderId = data['id']?.toString() ?? data['orderId']?.toString() ?? 'SUCCESS';

      if (!mounted) return;
      await app.fetchMe();
      await app.fetchOrders();
      SoundService.playSuccess();

      Navigator.pop(context); // Close bottom sheet

      // Show Order Placed Dialog
      _showSuccessDialog(orderId);
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

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
              'অর্ডার সফল হয়েছে!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'আপনার অফারটি দ্রুত প্রসেসিং করা হচ্ছে। ৫-১০ মিনিটের মধ্যে পেয়ে যাবেন।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Order ID: $orderId',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
              ),
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
    final offer = widget.offer;
    final finalPrice = offer.discountPrice > 0 ? offer.discountPrice : offer.price;
    final hasEnoughBalance = app.walletBalance >= finalPrice;
    final isOperatorMismatch = _detectedOperator != null && _detectedOperator != offer.operator.toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Handle Bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OperatorBadge(codeOrName: offer.operator, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                offer.validity,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            if (offer.location.isNotEmpty && offer.location != 'ALL') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  offer.location,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Price Tag
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '৳${finalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      if (offer.discountPrice > 0 && offer.discountPrice < offer.price)
                        Text(
                          '৳${offer.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 28),

              // Balance Status Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: hasEnoughBalance ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasEnoughBalance ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasEnoughBalance ? Icons.account_balance_wallet : Icons.warning_amber_rounded,
                          size: 20,
                          color: hasEnoughBalance ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          app.isBn ? 'বর্তমান ব্যালেন্স:' : 'Your Balance:',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '৳${app.walletBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: hasEnoughBalance ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    if (!hasEnoughBalance)
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddMoneyScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            app.isBn ? '+ রিচার্জ করুন' : '+ Add Money',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Recipient Number Input
              Text(
                app.isBn ? 'গ্রহীতার মোবাইল নম্বর দিন' : 'Recipient Mobile Number',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: _detectOperator,
                decoration: InputDecoration(
                  hintText: '01XXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_android, color: AppColors.primary),
                  suffixIcon: _detectedOperator != null
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: OperatorBadge(codeOrName: _detectedOperator!, size: 28),
                        )
                      : null,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'মোবাইল নম্বর লিখুন';
                  }
                  if (v.trim().length != 11 || !v.trim().startsWith('01')) {
                    return '১১ ডিজিটের সঠিক মোবাইল নম্বর দিন';
                  }
                  return null;
                },
              ),

              // Operator mismatch alert
              if (isOperatorMismatch) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'সতর্কতা: অফারটি ${offer.operator} অপারেটরের, কিন্তু নম্বরটি $_detectedOperator এর!',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Security PIN input
              Text(
                app.isBn ? 'আপনার সিকিউরিটি পিন দিন' : 'Enter Security PIN',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: _obscurePin,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  hintText: '••••',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'সিকিউরিটি পিন লিখুন';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Confirm Order Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading || !hasEnoughBalance ? null : _handleConfirmOrder,
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
                          app.isBn ? 'অফারটি কিনুন (৳${finalPrice.toStringAsFixed(0)})' : 'Confirm Purchase (৳${finalPrice.toStringAsFixed(0)})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
