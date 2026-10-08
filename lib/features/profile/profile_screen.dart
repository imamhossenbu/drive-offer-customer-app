import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/app_state.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/sound_service.dart';
import '../auth/login_screen.dart';
import '../wallet/transaction_history_screen.dart';
import '../../core/app_update_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  Timer? _progressTimer;

  Future<void> _handlePickProfileImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.15;
    });

    // Simulate smooth progress ticks for visual percentage feedback
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) return;
      setState(() {
        if (_uploadProgress < 0.88) {
          _uploadProgress += 0.08;
        }
      });
    });

    try {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await CustomerApiService.instance.uploadProfileImage(bytes: bytes);
      } else {
        await CustomerApiService.instance.uploadProfileImage(path: picked.path);
      }

      _progressTimer?.cancel();
      if (!mounted) return;

      setState(() {
        _uploadProgress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      await context.read<AppState>().fetchMe();
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      SoundService.playSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('প্রোফাইল ছবি সফলভাবে আপডেট হয়েছে!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      _progressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _showEditProfileDialog(BuildContext context, AppState app) {
    final nameCtrl = TextEditingController(text: app.userName);
    final phoneCtrl = TextEditingController(text: app.userPhone);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.edit, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(app.isBn ? 'প্রোফাইল পরিবর্তন করুন' : 'Edit Profile', style: const TextStyle(fontSize: 18)),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: app.isBn ? 'আপনার নাম' : 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? (app.isBn ? 'নাম লিখুন' : 'Enter name') : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: app.isBn ? 'মোবাইল নম্বর' : 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        hintText: '01XXXXXXXXX',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return app.isBn ? 'মোবাইল নম্বর লিখুন' : 'Enter phone number';
                        }
                        final clean = v.trim().replaceAll(RegExp(r'[^0-9]'), '');
                        if (clean.length < 11) {
                          return app.isBn ? 'সঠিক ১১ ডিজিটের নম্বর দিন' : 'Enter valid 11-digit phone';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(app.isBn ? 'বাতিল' : 'Cancel')),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isLoading = true);
                        try {
                          await CustomerApiService.instance.updateMe(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                          );
                          if (!ctx.mounted) return;
                          await context.read<AppState>().fetchMe();
                          Navigator.pop(ctx);
                          SoundService.playSuccess();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(app.isBn ? 'প্রোফাইল সফলভাবে আপডেট হয়েছে!' : 'Profile updated successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          SoundService.playError();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(app.isBn ? 'সেভ করুন' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

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
              await context.read<AppState>().logout();
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

    final rawAvatarUrl = app.user['profileImageUrl']?.toString() ??
        app.user['avatar']?.toString() ??
        app.user['profilePic']?.toString();

    final avatarUrl = (rawAvatarUrl != null && rawAvatarUrl.isNotEmpty) ? rawAvatarUrl : null;

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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Text(
                                app.userName.isNotEmpty ? app.userName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                              )
                            : null,
                      ),
                      if (_isUploading)
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  value: _uploadProgress,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!_isUploading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _handlePickProfileImage(context),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        app.userName.isNotEmpty ? app.userName : 'Customer Name',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showEditProfileDialog(context, app),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _showEditProfileDialog(context, app),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_android, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            app.userPhone.isNotEmpty ? app.userPhone : (app.isBn ? 'ফোন নম্বর যোগ করুন' : 'Add phone number'),
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 12, color: AppColors.primary),
                        ],
                      ),
                    ),
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
                        MaterialPageRoute(builder: (_) => const TransactionHistoryScreen(initialTabIndex: 0)),
                      );
                    },
                  ),
                  const Divider(height: 1),

                  // Top-Up History (টপ-আপ হিস্ট্রি)
                  ListTile(
                    leading: const Icon(Icons.payments_outlined, color: Color(0xFF10B981)),
                    title: Text(app.isBn ? 'টপ-আপ হিস্ট্রি (Add Balance Records)' : 'Top-Up History'),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionHistoryScreen(initialTabIndex: 1)),
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

                  // Check for App Updates (১-ক্লিক আপডেট)
                  ListTile(
                    leading: const Icon(Icons.system_update_rounded, color: AppColors.primary),
                    title: Text(app.isBn ? 'অ্যাপ আপডেট চেক করুন' : 'Check for Updates'),
                    subtitle: Text(app.isBn ? 'নতুন ভার্সন ও ফিচার ইনস্টল করুন' : 'Check & install latest APK version'),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () {
                      SoundService.playTap();
                      AppUpdateService.instance.checkForUpdate(context, isManualCheck: true);
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
