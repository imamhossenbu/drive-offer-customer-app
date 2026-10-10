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
  int _step = 1; // 1: Email, 2: OTP Code, 3: New PIN
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
    final input = _emailController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('দয়া করে আপনার নিবন্ধিত মোবাইল নম্বর অথবা ইমেইল লিখুন'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    SoundService.playTap();

    try {
      final res = await CustomerApiService.instance.forgotPin(emailOrPhone: input);
      final data = res['data'] ?? res;
      _verificationId = data['verificationId']?.toString() ?? '';

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = 2;
      });
      SoundService.playSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'রিসেট ওটিপি কোড পাঠানো হয়েছে।'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleVerifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('দয়া করে ৬-ডিজিটের ভেরিফিকেশন কোড লিখুন'),
          backgroundColor: AppColors.error,
        ),
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
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleResetPin() async {
    final newPin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (newPin.length < 4 || newPin.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('পিন অবশ্যই ৪ থেকে ৬ সংখ্যার হতে হবে'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('উভয় পিন এক হতে হবে, মিলছে না!'),
          backgroundColor: AppColors.error,
        ),
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
        const SnackBar(
          content: Text('সিকিউরিটি পিন সফলভাবে পরিবর্তন করা হয়েছে! নতুন পিন দিয়ে লগইন করুন।'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          app.isBn ? 'পিন রিসেট করুন' : 'Reset Security PIN',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 1) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Banner
              _buildHeaderBanner(app),

              // Form Body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    if (_step == 1) _buildStep1Email(app),
                    if (_step == 2) _buildStep2Otp(app),
                    if (_step == 3) _buildStep3NewPin(app),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(AppState app) {
    final steps = [
      app.isBn ? 'ইমেইল' : 'Email',
      app.isBn ? 'ওটিপি' : 'OTP Code',
      app.isBn ? 'নতুন পিন' : 'New PIN',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.isBn ? 'সিকিউরিটি পিন পুনরুদ্ধার' : 'PIN Recovery Assistance',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    app.isBn ? 'নিরাপদ পদ্ধতিতে পিন রিসেট করুন' : 'Secure instant verification',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stepper Indicator Pills
          Row(
            children: List.generate(3, (index) {
              final isCompleted = _step > (index + 1);
              final isActive = _step == (index + 1);

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : (isCompleted ? AppColors.accentGold : Colors.white.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle
                            : (isActive ? Icons.radio_button_checked : Icons.circle_outlined),
                        size: 14,
                        color: isActive
                            ? AppColors.primary
                            : (isCompleted ? Colors.black87 : Colors.white),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? AppColors.primary
                              : (isCompleted ? Colors.black87 : Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Email Input ────────────────────────────────────────────────────
  Widget _buildStep1Email(AppState app) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.contact_mail_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                app.isBn ? 'আপনার মোবাইল নম্বর বা ইমেইল' : 'Mobile Number or Email',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            app.isBn
                ? 'একাউন্ট খোলার সময় যে মোবাইল নম্বর অথবা ইমেইল দিয়েছিলেন তা লিখুন। সেখানে ওটিপি ভেরিফিকেশন কোড পাঠানো হবে।'
                : 'Enter your registered mobile number or email address to receive OTP code.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: app.isBn ? 'মোবাইল নম্বর অথবা ইমেইল' : 'Phone or Email',
              prefixIcon: const Icon(Icons.perm_identity, color: AppColors.primary),
              hintText: '017XXXXXXXX বা example@gmail.com',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 24),

          // Action Button with explicit White Text
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          app.isBn ? 'ভেরিফিকেশন কোড পাঠান' : 'Send Verification Code',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 19, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: OTP Verification ───────────────────────────────────────────────
  Widget _buildStep2Otp(AppState app) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                app.isBn ? 'ওটিপি কোড যাচাই' : 'OTP Code Verification',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_emailController.text} ${app.isBn ? 'ঠিকানায় পাঠানো ৬ সংখ্যার কোডটি লিখুন।' : 'has received a 6-digit verification code.'}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              labelText: app.isBn ? '৬ সংখ্যার ওটিপি কোড' : '6-Digit OTP Code',
              prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primary),
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleVerifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          app.isBn ? 'কোড যাচাই করুন' : 'Verify Code & Proceed',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 19, color: Colors.white),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          Center(
            child: TextButton.icon(
              onPressed: _isLoading ? null : _handleSendEmail,
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
              label: Text(
                app.isBn ? 'কোড পাননি? পুনরায় পাঠান' : 'Didn\'t get code? Resend',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: New PIN ────────────────────────────────────────────────────────
  Widget _buildStep3NewPin(AppState app) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                app.isBn ? 'নতুন পিন সেট করুন' : 'Set New Security PIN',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            app.isBn
                ? 'আপনার পছন্দের নতুন ৪-৬ সংখ্যার সিকিউরিটি পিন লিখুন।'
                : 'Enter your new 4-6 digit numeric security PIN.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),

          // New PIN Field
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: _obscurePin,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: InputDecoration(
              labelText: app.isBn ? 'নতুন পিন (৪-৬ সংখ্যা)' : 'New PIN (4-6 Digits)',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm PIN Field
          TextFormField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            obscureText: _obscureConfirmPin,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: InputDecoration(
              labelText: app.isBn ? 'পিন নিশ্চিত করুন' : 'Confirm New PIN',
              prefixIcon: const Icon(Icons.lock_reset, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPin ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 24),

          // Confirm Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          app.isBn ? 'পিন পরিবর্তন সম্পন্ন করুন' : 'Complete PIN Reset',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
