import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_service.dart';
import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/sound_service.dart';
import '../customer_main.dart';

class KycReviewScreen extends StatefulWidget {
  final String? name;
  final String? phone;
  final String? email;
  final bool isFromRegistration;

  const KycReviewScreen({
    super.key,
    this.name,
    this.phone,
    this.email,
    this.isFromRegistration = false,
  });

  @override
  State<KycReviewScreen> createState() => _KycReviewScreenState();
}

class _KycReviewScreenState extends State<KycReviewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    setState(() => _isCheckingStatus = true);
    SoundService.playTap();

    try {
      final res = await CustomerApiService.instance.getProfile();
      final user = res['data'] ?? res;
      final kycStatus = (user['kycStatus'] ?? user['accountStatus'] ?? 'PENDING').toString().toUpperCase();

      if (!mounted) return;
      await context.read<AppState>().syncFromStorage();
      await context.read<AppState>().refreshAll();

      setState(() => _isCheckingStatus = false);

      if (kycStatus == 'VERIFIED' || kycStatus == 'CONFIRMED' || kycStatus == 'ACTIVE') {
        SoundService.playSuccess();
        _showApprovedDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('আপনার কেওয়াইসি এখনো পর্যালোচনায় আছে। দ্রুত অ্যাপ্রুভালের জন্য হেল্পলাইনে যোগাযোগ করতে পারেন।'),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('স্ট্যাটাস চেক ব্যর্থ হয়েছে: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showApprovedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.verified, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Text('অভিনন্দন!', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        content: const Text(
          'আপনার কেওয়াইসি (NID KYC) সফলভাবে যাচাই ও অনুমোদিত হয়েছে। এখন আপনি সব ধরনের ড্রাইভ অফার ক্রয় এবং ওয়ালেট রিচার্জ করতে পারবেন।',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const CustomerMain()),
                (route) => false,
              );
            },
            child: const Text('হোম পেজে যান', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isBn = app.isBn;
    final userName = widget.name ?? app.userName;
    final userPhone = widget.phone ?? app.userPhone;
    final userEmail = widget.email ?? app.userEmail;
    final nowFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isBn ? 'কেওয়াইসি ভেরিফিকেশন' : 'KYC Verification',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: widget.isFromRegistration
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Animated Pulsing Status Badge
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.hourglass_top_rounded, size: 48, color: Color(0xFFD97706)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title & Subtitle
              Text(
                isBn ? 'কেওয়াইসি তথ্য পর্যালোচনায় আছে' : 'KYC Under Review',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isBn ? 'স্ট্যাটাস: রিভিউ প্রক্রিয়াধীন' : 'Status: Verification Pending',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isBn
                    ? 'আপনার এনআইডি (NID) কার্ড এবং পরিচয়পত্র আমাদের অ্যাডমিন টিম দ্বারা যাচাই করা হচ্ছে। সাধারণত ৫-১৫ মিনিটের মধ্যে একাউন্ট সক্রিয় হয়ে যায়।'
                    : 'Your submitted NID documents are currently being verified by our compliance team. Accounts are usually activated within 5-15 minutes.',
                style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Application Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
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
                        const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isBn ? 'আবেদন ও নথিপত্রের বিবরণ' : 'Submitted Information',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(isBn ? 'আবেদনকারীর নাম' : 'Applicant Name', userName.isNotEmpty ? userName : '—'),
                    _buildInfoRow(isBn ? 'মোবাইল নম্বর' : 'Phone Number', userPhone.isNotEmpty ? userPhone : '—'),
                    _buildInfoRow(isBn ? 'ইমেইল এড্রেস' : 'Email Address', userEmail.isNotEmpty ? userEmail : '—'),
                    _buildInfoRow(
                      isBn ? 'এনআইডি ফ্রন্ট সাইড' : 'NID Front Photo',
                      isBn ? 'আপলোড সম্পন্ন (স্বীকৃত)' : 'Uploaded (Verified)',
                      isSuccess: true,
                    ),
                    _buildInfoRow(
                      isBn ? 'এনআইডি ব্যাক সাইড' : 'NID Back Photo',
                      isBn ? 'আপলোড সম্পন্ন (স্বীকৃত)' : 'Uploaded (Verified)',
                      isSuccess: true,
                    ),
                    _buildInfoRow(isBn ? 'সাবমিশন সময়' : 'Submitted At', nowFormatted),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Progress Stepper Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'ভেরিফিকেশন প্রক্রিয়া' : 'Verification Steps',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 14),
                    _buildStepRow(
                      stepNumber: '১',
                      title: isBn ? 'এনআইডি ও ব্যক্তিগত তথ্য আপলোড' : 'NID & Details Uploaded',
                      subtitle: isBn ? 'সফলভাবে সম্পন্ন হয়েছে' : 'Completed successfully',
                      isCompleted: true,
                    ),
                    _buildStepRow(
                      stepNumber: '২',
                      title: isBn ? 'অ্যাডমিন সিকিউরিটি রিভিউ' : 'Admin Security Review',
                      subtitle: isBn ? 'বর্তমানে প্রক্রিয়াধীন রয়েছে' : 'Currently in progress',
                      isInProgress: true,
                    ),
                    _buildStepRow(
                      stepNumber: '৩',
                      title: isBn ? 'অফার ক্রয় ও আনলিমিটেড লেনদেন' : 'Drive Purchase & Topup Access',
                      subtitle: isBn ? 'অনুমোদনের পর স্বয়ংক্রিয়ভাবে চালু হবে' : 'Unlocks after review approval',
                      isPending: true,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Fast-Track Helpline Support Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F5132), Color(0xFF15803D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.headset_mic, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'জরুরি দ্রুত ভেরিফিকেশন চান?',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'জরুরি অফার কিনতে দ্রুত কেওয়াইসি অ্যাপ্রুভ করাতে আমাদের হেল্পলাইনে মেসেজ দিন:',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchUrl('https://wa.me/8801700000000?text=Hello+Admin+Please+verify+my+KYC'),
                            icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                            label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchUrl('https://t.me/alokitotelecom'),
                            icon: const Icon(Icons.send, size: 18, color: Colors.white),
                            label: const Text('Telegram', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0088CC),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Check Status Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isCheckingStatus ? null : _checkStatus,
                  icon: _isCheckingStatus
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    isBn ? 'স্ট্যাটাস চেক করুন' : 'Check Approval Status',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Go to Dashboard Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    SoundService.playTap();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerMain()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isBn ? 'হোম পেজে প্রবেশ করুন' : 'Go to Home Dashboard',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
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

  Widget _buildInfoRow(String label, String value, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Row(
            children: [
              if (isSuccess) ...[
                const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSuccess ? AppColors.success : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String stepNumber,
    required String title,
    required String subtitle,
    bool isCompleted = false,
    bool isInProgress = false,
    bool isPending = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success
                    : (isInProgress ? const Color(0xFFF59E0B) : Colors.grey.shade300),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        stepNumber,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isInProgress ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isCompleted ? AppColors.success : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isPending ? Colors.grey.shade600 : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isInProgress ? const Color(0xFFB45309) : AppColors.textSecondary,
                ),
              ),
              if (!isLast) const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}
