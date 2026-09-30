import 'package:flutter/material.dart';
import '../constants.dart';

class OperatorBadge extends StatelessWidget {
  final String codeOrName;
  final double size;
  final bool showLabel;

  final String? logoUrl;

  const OperatorBadge({
    super.key,
    required this.codeOrName,
    this.size = 36,
    this.showLabel = false,
    this.logoUrl,
  });

  // Constructor with operator param alias
  OperatorBadge.withOperator({
    super.key,
    required String operator,
    this.size = 36,
    this.showLabel = false,
    this.logoUrl,
  }) : codeOrName = operator;

  static String cleanKey(String val) {
    final s = val.trim().toUpperCase();
    if (s.contains('GRAMEEN') || s.contains('GP') || s.contains('গ্রামীণ') || s.contains('গ্রামীন') || s.contains('017') || s.contains('013')) return 'gp';
    if (s.contains('ROBI') || s.contains('রবি') || s.contains('018')) return 'robi';
    if (s.contains('AIRTEL') || s.contains('এয়ারটেল') || s.contains('এয়ারটেল') || s.contains('016')) return 'airtel';
    if (s.contains('BANGLALINK') || s.contains('BL') || s.contains('বাংলালিংক') || s.contains('019') || s.contains('014')) return 'banglalink';
    if (s.contains('TELETALK') || s.contains('TT') || s.contains('টেলিটক') || s.contains('015')) return 'teletalk';
    return 'gp';
  }

  Color _getColor(String key) {
    switch (key) {
      case 'gp':
        return AppColors.gp;
      case 'robi':
        return AppColors.robi;
      case 'airtel':
        return AppColors.airtel;
      case 'banglalink':
        return AppColors.banglalink;
      case 'teletalk':
        return AppColors.teletalk;
      default:
        return AppColors.primary;
    }
  }

  String _getLabel(String key) {
    switch (key) {
      case 'gp':
        return 'Grameenphone';
      case 'robi':
        return 'Robi';
      case 'airtel':
        return 'Airtel';
      case 'banglalink':
        return 'Banglalink';
      case 'teletalk':
        return 'Teletalk';
      default:
        return key.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = cleanKey(codeOrName);
    final color = _getColor(key);
    final assetPath = 'assets/operators/$key.png';

    Widget imageContent;
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      imageContent = Image.network(
        logoUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            color: color.withValues(alpha: 0.15),
            alignment: Alignment.center,
            child: Text(
              key.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: size * 0.45,
              ),
            ),
          ),
        ),
      );
    } else {
      imageContent = Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: color.withValues(alpha: 0.15),
          alignment: Alignment.center,
          child: Text(
            key.substring(0, 1).toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
              fontSize: size * 0.45,
            ),
          ),
        ),
      );
    }

    Widget iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: imageContent,
      ),
    );

    if (!showLabel) return iconWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(width: 8),
        Text(
          _getLabel(key),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
