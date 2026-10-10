import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_state.dart';
import 'constants.dart';
import 'sound_service.dart';

class SupportLauncher {
  static Future<void> launchCall(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('হেল্পলাইন নম্বর সেট করা নেই')),
      );
      return;
    }
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('কল করা যাচ্ছে না: $e')),
        );
      }
    }
  }

  static Future<void> launchWhatsApp(BuildContext context, String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('হোয়াটসঅ্যাপ সাপোর্ট লিংক বা নম্বর সেট করা নেই')),
      );
      return;
    }

    Uri uri;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      uri = Uri.parse(trimmed);
    } else {
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      final formatted = digits.startsWith('88') ? digits : '88$digits';
      uri = Uri.parse('https://wa.me/$formatted');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('হোয়াটসঅ্যাপ খোলা যাচ্ছে না: $e')),
        );
      }
    }
  }

  static Future<void> launchUrlString(BuildContext context, String rawUrl, String label) async {
    String url = rawUrl.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label লিংক সেট করা নেই')),
      );
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label খোলা যাচ্ছে না: $e')),
        );
      }
    }
  }

  static void showSupportModal(BuildContext context, AppState app) {
    SoundService.playTap();
    final isBn = app.isBn;
    final wa = app.whatsappSupport;
    final fb = app.facebookSupport;
    final yt = app.youtubeSupport;
    final phone = app.helplinePhone;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Color(0xFF15803D), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'কাস্টমার সাপোর্ট ও হেল্পলাইন' : 'Customer Support & Helpline',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        isBn ? 'যেকোনো প্রয়োজনে সরাসরি যোগাযোগ করুন' : 'Connect with our support team 24/7',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // WhatsApp Support
            _buildSupportTile(
              context: ctx,
              title: 'WhatsApp Support',
              subtitle: wa.isNotEmpty ? wa : (isBn ? 'সরাসরি চ্যাট করতে ট্যাপ করুন' : 'Tap to chat with admin'),
              icon: Icons.chat_bubble_rounded,
              color: const Color(0xFF25D366),
              bgColor: const Color(0xFFE8F5E9),
              onTap: () {
                Navigator.pop(ctx);
                launchWhatsApp(context, wa.isNotEmpty ? wa : '01890000000');
              },
            ),
            const SizedBox(height: 10),

            // Helpline Phone Call
            _buildSupportTile(
              context: ctx,
              title: isBn ? 'সরাসরি হেল্পলাইন কল' : 'Helpline Direct Call',
              subtitle: phone.isNotEmpty ? phone : (isBn ? 'অফলাইন ফোন সাপোর্ট' : 'Offline phone support'),
              icon: Icons.phone_in_talk_rounded,
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFE0F2FE),
              onTap: () {
                Navigator.pop(ctx);
                launchCall(context, phone.isNotEmpty ? phone : '01890000000');
              },
            ),
            const SizedBox(height: 10),

            // Facebook
            _buildSupportTile(
              context: ctx,
              title: 'Facebook Page & Group',
              subtitle: fb.isNotEmpty ? fb : (isBn ? 'অফিসিয়াল ফেসবুক পেজ' : 'Official Facebook page'),
              icon: Icons.facebook_rounded,
              color: const Color(0xFF1877F2),
              bgColor: const Color(0xFFEFF6FF),
              onTap: () {
                Navigator.pop(ctx);
                launchUrlString(context, fb, 'Facebook');
              },
            ),
            const SizedBox(height: 10),

            // YouTube
            _buildSupportTile(
              context: ctx,
              title: 'YouTube Channel & Tutorials',
              subtitle: yt.isNotEmpty ? yt : (isBn ? 'ব্যবহার নির্দেশিকা ও ভিডিও' : 'Guides & videos'),
              icon: Icons.smart_display_rounded,
              color: const Color(0xFFFF0000),
              bgColor: const Color(0xFFFEF2F2),
              onTap: () {
                Navigator.pop(ctx);
                launchUrlString(context, yt, 'YouTube');
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSupportTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
