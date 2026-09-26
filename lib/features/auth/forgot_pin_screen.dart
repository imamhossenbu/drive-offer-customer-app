import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/sound_service.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  int _step = 1; // 1: Email, 2: Code, 3: New PIN
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  String _verificationId = '';
  String _resetToken = '';
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    SoundService.playTap();

    try {
      final res = await CustomerApiService.instance.forgotPin(email: email);
      final data = res['data'] ?? res;
      _verificationId = data['verificationId']?.toString() ?? '';

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = 2;
      });
      SoundService.playSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset OTP code sent to your email'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleVerifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 6-digit code'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    SoundService.playTap();

    try {
      final res = await CustomerApiService.instance.verifyForgotPin(
        verificationId: _verificationId,
        code: code,
      );
      final data = res['data'] ?? res;
      _resetToken = data['resetToken']?.toString() ?? '';

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = 3;
      });
      SoundService.playSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleResetPin() async {
    final newPin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (newPin.length < 4 || newPin.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be 4 to 6 digits'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    SoundService.playTap();

    try {
      await CustomerApiService.instance.resetPin(
        resetToken: _resetToken,
        newPin: newPin,
        confirmPin: confirmPin,
      );

      if (!mounted) return;
      SoundService.playSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN reset successfully! Please login with your new PIN.'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(app.isBn ? 'পিন রিসেট করুন' : 'Reset Security PIN'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              if (_step == 1) ...[
                Text(
                  app.isBn ? 'আপনার নিবন্ধিত ইমেইল লিখুন' : 'Enter Registered Email',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  app.isBn
                      ? 'আমরা আপনার ইমেইলে একটি ভেরিফিকেশন ওটিপি পাঠাব।'
                      : 'We will send a 6-digit OTP code to verify your identity.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(app.isBn ? 'ওটিপি পাঠান' : 'Send Reset Code', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else if (_step == 2) ...[
                Text(
                  app.isBn ? 'ভেরিফিকেশন কোড দিন' : 'Enter Verification Code',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_emailController.text} ঠিকানায় পাঠানো ৬-ডিজিটের কোডটি লিখুন।',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '6-Digit OTP Code',
                    prefixIcon: Icon(Icons.pin_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(app.isBn ? 'যাচাই করুন' : 'Verify Code', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                Text(
                  app.isBn ? 'নতুন পিন সেট করুন' : 'Set New Security PIN',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  app.isBn ? 'আপনার নতুন ৪-৬ সংখ্যার সিকিউরিটি পিন দিন।' : 'Enter your new 4-6 digit security PIN.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: _obscurePin,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  decoration: InputDecoration(
                    labelText: 'New PIN (৪-৬ সংখ্যা)',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: _obscureConfirmPin,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  decoration: InputDecoration(
                    labelText: 'Confirm New PIN',
                    prefixIcon: const Icon(Icons.lock_reset, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(app.isBn ? 'পিন পরিবর্তন সম্পূর্ণ করুন' : 'Confirm Reset PIN', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
