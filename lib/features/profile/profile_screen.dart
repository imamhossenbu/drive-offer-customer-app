import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/app_state.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/sound_service.dart';
import '../auth/login_screen.dart';
import '../wallet/transaction_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showChangePinDialog(BuildContext context) {
    final currentPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final app = ctx.watch<AppState>();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.lock_reset, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(app.isBn ? 'সিকিউরিটি পিন পরিবর্তন' : 'Change Security PIN', style: const TextStyle(fontSize: 18)),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPinCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: obscure,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    decoration: InputDecoration(
                      labelText: app.isBn ? 'বর্তমান পিন' : 'Current PIN',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'বর্তমান পিন দিন' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPinCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: obscure,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    decoration: InputDecoration(
                      labelText: app.isBn ? 'নতুন পিন (৪-৬ সংখ্যা)' : 'New PIN (4-6 Digits)',
                      prefixIcon: const Icon(Icons.key, size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'নতুন পিন দিন';
                      if (v.length < 4 || v.length > 6) return 'পিন ৪-৬ সংখ্যার হতে হবে';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPinCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: obscure,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    decoration: InputDecoration(
                      labelText: app.isBn ? 'নতুন পিন নিশ্চিত করুন' : 'Confirm New PIN',
                      prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                    ),
                    validator: (v) {
                      if (v != newPinCtrl.text) return 'পিন দুটি মিলছে না';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: !obscure,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setDialogState(() => obscure = !(val ?? false)),
                      ),
                      Text(app.isBn ? 'পিন দেখুন' : 'Show PIN', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(app.isBn ? 'বাতিল' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isLoading = true);

                        try {
                          await CustomerApiService.instance.changePin(
                            currentPin: currentPinCtrl.text.trim(),
                            newPin: newPinCtrl.text.trim(),
                            confirmPin: confirmPinCtrl.text.trim(),
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          SoundService.playSuccess();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PIN changed successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          SoundService.playError();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(app.isBn ? 'সংরক্ষণ করুন' : 'Save PIN'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('লগআউট নিশ্চিতকরণ'),
        content: const Text('আপনি কি নিশ্চিত যে একাউন্ট থেকে লগআউট করতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('না')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthStorage.clearAuth();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('লগআউট', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          app.isBn ? 'প্রোফাইল ও সেটিংস' : 'Profile & Settings',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      app.userName.isNotEmpty ? app.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    app.userName.isNotEmpty ? app.userName : 'Customer Name',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app.userPhone.isNotEmpty ? app.userPhone : 'No phone',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  if (app.userEmail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      app.userEmail,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // KYC Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: app.kycStatus == 'VERIFIED'
                          ? const Color(0xFFDCFCE7)
                          : (app.kycStatus == 'PENDING' ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: app.kycStatus == 'VERIFIED'
                            ? const Color(0xFF86EFAC)
                            : (app.kycStatus == 'PENDING' ? const Color(0xFFFDE68A) : const Color(0xFFFECACA)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          app.kycStatus == 'VERIFIED' ? Icons.verified : Icons.hourglass_top,
                          size: 16,
                          color: app.kycStatus == 'VERIFIED'
                              ? AppColors.success
                              : (app.kycStatus == 'PENDING' ? const Color(0xFFD97706) : AppColors.error),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'KYC Status: ${app.kycStatus}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: app.kycStatus == 'VERIFIED'
                                ? AppColors.success
                                : (app.kycStatus == 'PENDING' ? const Color(0xFFD97706) : AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Change PIN
                  ListTile(
                    leading: const Icon(Icons.lock_reset, color: AppColors.primary),
                    title: Text(app.isBn ? 'সিকিউরিটি পিন পরিবর্তন' : 'Change Security PIN'),
                    subtitle: Text(app.isBn ? 'লগইন ও অর্ডারের পিন বদলান' : 'Update login & transaction PIN'),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () => _showChangePinDialog(context),
                  ),
                  const Divider(height: 1),

                  // Ledger / Transactions
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                    title: Text(app.isBn ? 'লেনদেন হিস্ট্রি' : 'Transaction History'),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),

                  // Language
                  ListTile(
                    leading: const Icon(Icons.language, color: AppColors.primary),
                    title: Text(app.isBn ? 'ভাষা (Language)' : 'App Language'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        app.isBn ? 'বাংলা' : 'English',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                      ),
                    ),
                    onTap: () => app.toggleLanguage(),
                  ),
                  const Divider(height: 1),

                  // Support / Helpline
                  ListTile(
                    leading: const Icon(Icons.headset_mic_outlined, color: AppColors.primary),
                    title: Text(app.isBn ? 'কাস্টমার সাপোর্ট ও হেল্পলাইন' : 'Support Helpline'),
                    subtitle: const Text('WhatsApp: +880 1890 000000'),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Helpline WhatsApp: +8801890000000')),
                      );
                    },
                  ),
                  const Divider(height: 1),

                  // Logout
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: Text(
                      app.isBn ? 'লগআউট করুন' : 'Logout',
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Version
            Text(
              'Drive Offer Customer App v1.0.0 (Build 1)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
