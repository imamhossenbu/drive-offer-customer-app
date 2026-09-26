import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/sound_service.dart';
import 'otp_verification_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Personal Info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _step1FormKey = GlobalKey<FormState>();

  // Step 2: KYC NID Images
  XFile? _nidFrontFile;
  XFile? _nidBackFile;
  Uint8List? _nidFrontBytes;
  Uint8List? _nidBackBytes;
  final ImagePicker _picker = ImagePicker();

  // Step 3: Security PIN
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _step3FormKey = GlobalKey<FormState>();
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _agreedToTerms = true;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront, ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          if (isFront) {
            _nidFrontFile = file;
            _nidFrontBytes = bytes;
          } else {
            _nidBackFile = file;
            _nidBackBytes = bytes;
          }
        });
        SoundService.playTap();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog(bool isFront) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFront ? 'NID Front Image (সামনের ছবি)' : 'NID Back Image (পেছনের ছবি)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Take Photo with Camera (ক্যামেরা দিয়ে তুলুন)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(isFront, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.secondary),
                ),
                title: const Text('Choose from Gallery (গ্যালারি থেকে বেছে নিন)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(isFront, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (_nidFrontBytes == null || _nidBackBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload both NID front and back photos (এনআইডির উভয় পিঠের ছবি দিন)'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      SoundService.playTap();
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      SoundService.playTap();
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_step3FormKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms and Conditions to proceed'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    SoundService.playTap();

    try {
      final res = await CustomerApiService.instance.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        pin: _pinController.text.trim(),
        nidFrontBytes: _nidFrontBytes,
        nidFrontPath: kIsWeb ? null : _nidFrontFile?.path,
        nidBackBytes: _nidBackBytes,
        nidBackPath: kIsWeb ? null : _nidBackFile?.path,
      );

      final data = res['data'] ?? res;
      final registrationId = data['registrationId']?.toString() ?? '';
      final email = _emailController.text.trim();

      if (!mounted) return;
      setState(() => _isLoading = false);
      SoundService.playSuccess();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            registrationId: registrationId,
            email: email,
            pin: _pinController.text.trim(),
          ),
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          app.isBn ? 'নতুন একাউন্ট খুলুন' : 'Create Customer Account',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepperHeader(app),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(app),
                  _buildStep2(app),
                  _buildStep3(app),
                ],
              ),
            ),
            _buildBottomNav(app),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader(AppState app) {
    final steps = [
      app.isBn ? 'ব্যক্তিগত তথ্য' : 'Personal Info',
      app.isBn ? 'এনআইডি কেওয়াইসি' : 'NID KYC',
      app.isBn ? 'পিন সেটআপ' : 'Security PIN',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = _currentStep > index;
          final isActive = _currentStep == index;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.accentGold
                              : (isActive ? Colors.white : Colors.white.withOpacity(0.3)),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 18, color: Colors.black87)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? AppColors.primary : Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Colors.white : Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 24,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: _currentStep > index ? AppColors.accentGold : Colors.white.withOpacity(0.3),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1: Personal Info ──────────────────────────────────────────────────
  Widget _buildStep1(AppState app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.isBn ? 'আপনার মৌলিক তথ্য দিন' : 'Enter Your Personal Details',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              app.isBn
                  ? 'সঠিক তথ্য দিন যা আপনার জাতীয় পরিচয়পত্রের (NID) সাথে মিলে যায়।'
                  : 'Please provide exact details matching your National ID Card.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Full Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: app.isBn ? 'পূর্ণ নাম (NID অনুযায়ী)' : 'Full Name (as in NID)',
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                hintText: 'e.g. Md. Ashraful Islam',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return app.isBn ? 'দয়া করে নাম লিখুন' : 'Please enter your full name';
                }
                if (v.trim().length < 3) {
                  return app.isBn ? 'নাম কমপক্ষে ৩ অক্ষরের হতে হবে' : 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: InputDecoration(
                labelText: app.isBn ? 'মোবাইল নম্বর' : 'Mobile Phone Number',
                prefixIcon: const Icon(Icons.phone_android, color: AppColors.primary),
                hintText: '01XXXXXXXXX',
                helperText: app.isBn ? '১১ ডিজিটের বিডি মোবাইল নম্বর' : '11-digit BD mobile number',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return app.isBn ? 'মোবাইল নম্বর দিন' : 'Please enter mobile number';
                }
                final cleaned = v.trim();
                if (cleaned.length != 11 || !cleaned.startsWith('01')) {
                  return app.isBn ? 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (০১...)' : 'Invalid 11-digit BD number (01...)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: app.isBn ? 'ইমেইল এড্রেস' : 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                hintText: 'you@example.com',
                helperText: app.isBn ? 'ভেরিফিকেশন কোড এই ইমেইলে যাবে' : 'OTP verification code will be sent here',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return app.isBn ? 'ইমেইল এড্রেস দিন' : 'Please enter email address';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                  return app.isBn ? 'সঠিক ইমেইল এড্রেস দিন' : 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: NID KYC Upload ─────────────────────────────────────────────────
  Widget _buildStep2(AppState app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
                child: const Icon(Icons.verified_user_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.isBn ? 'এনআইডি কেওয়াইসি যাচাই' : 'NID KYC Verification',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      app.isBn
                          ? 'জাতীয় পরিচয়পত্রের উভয় পাশের পরিষ্কার ছবি তুলুন'
                          : 'Upload clear front & back photos of your National ID Card',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Front Image Picker
          _buildNidCard(
            title: app.isBn ? 'এনআইডি কার্ডের সামনের অংশ (Front)' : 'NID Front Side',
            subtitle: app.isBn ? 'ছবি ও নাম স্পষ্ট দেখা যেতে হবে' : 'Ensure photo and name are clearly legible',
            bytes: _nidFrontBytes,
            isFront: true,
          ),
          const SizedBox(height: 18),

          // Back Image Picker
          _buildNidCard(
            title: app.isBn ? 'এনআইডি কার্ডের পেছনের অংশ (Back)' : 'NID Back Side',
            subtitle: app.isBn ? 'ঠিকানা ও বারকোড স্পষ্ট দেখা যেতে হবে' : 'Ensure address & barcode are clearly legible',
            bytes: _nidBackBytes,
            isFront: false,
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    app.isBn
                        ? 'আপনার তথ্যের গোপনীয়তা শতভাগ সুরক্ষিত। সরকারি নিয়ম অনুযায়ী টেলিকম ড্রাইভ অফার ক্রয়ের জন্য এটি আবশ্যক।'
                        : 'Your data is strictly encrypted. NID verification is legally mandated for telecom offer transactions.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNidCard({
    required String title,
    required String subtitle,
    required Uint8List? bytes,
    required bool isFront,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bytes != null ? AppColors.primary : Colors.grey.shade300,
          width: bytes != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showImageSourceDialog(isFront),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (bytes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: AppColors.success),
                            SizedBox(width: 4),
                            Text('Uploaded', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                if (bytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      bytes,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
                        label: const Text('Retake Photo', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                        onPressed: () => _showImageSourceDialog(isFront),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        label: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 13)),
                        onPressed: () {
                          setState(() {
                            if (isFront) {
                              _nidFrontFile = null;
                              _nidFrontBytes = null;
                            } else {
                              _nidBackFile = null;
                              _nidBackBytes = null;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey.shade500),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to take photo or upload file',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 3: Security PIN Setup ─────────────────────────────────────────────
  Widget _buildStep3(AppState app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.isBn ? 'সিকিউরিটি পিন সেট করুন' : 'Setup Security PIN',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              app.isBn
                  ? 'লগইন এবং অফার কেনার সময় ৪-৬ সংখ্যার এই পিন ব্যবহার করতে হবে।'
                  : 'You will use this 4-6 digit numeric PIN to login and confirm orders.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // PIN
            TextFormField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: _obscurePin,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                labelText: app.isBn ? 'নতুন পিন (৪-৬ সংখ্যা)' : 'New PIN (4-6 Digits)',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
                hintText: '••••',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return app.isBn ? 'পিন লিখুন' : 'Please enter security PIN';
                }
                if (v.trim().length < 4 || v.trim().length > 6) {
                  return app.isBn ? 'পিন ৪ থেকে ৬ সংখ্যার হতে হবে' : 'PIN must be 4 to 6 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm PIN
            TextFormField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: _obscureConfirmPin,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                labelText: app.isBn ? 'পিন নিশ্চিত করুন' : 'Confirm PIN',
                prefixIcon: const Icon(Icons.lock_reset, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPin ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                ),
                hintText: '••••',
              ),
              validator: (v) {
                if (v != _pinController.text) {
                  return app.isBn ? 'পিন দুটি মিলছে না' : 'PINs do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Terms Checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _agreedToTerms,
              activeColor: AppColors.primary,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                app.isBn
                    ? 'আমি ড্রাইভ অফার প্ল্যাটফর্মের সকল নিয়ম ও শর্তাবলী মেনে নিচ্ছি।'
                    : 'I agree to the Terms & Conditions and Privacy Policy.',
                style: const TextStyle(fontSize: 13),
              ),
              onChanged: (v) => setState(() => _agreedToTerms = v ?? true),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Navigation Action Bar ──────────────────────────────────────────
  Widget _buildBottomNav(AppState app) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            OutlinedButton(
              onPressed: _isLoading ? null : _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(app.isBn ? 'পূর্ববর্তী' : 'Back'),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_currentStep == 2) {
                        _handleRegister();
                      } else {
                        _nextStep();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          _currentStep == 2
                              ? (app.isBn ? 'একাউন্ট তৈরি করুন' : 'Complete Registration')
                              : (app.isBn ? 'পরবর্তী ধাপ' : 'Continue'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == 2 ? Icons.check_circle_outline : Icons.arrow_forward,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
