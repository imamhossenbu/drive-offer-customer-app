import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents
  static const Color primary = Color(0xFF0D5E36);
  static const Color primaryLight = Color(0xFF15803D);
  static const Color primaryDark = Color(0xFF083D22);
  static const Color secondary = Color(0xFFD97706);
  static const Color accentMint = Color(0xFFDCFCE7);
  static const Color accentMintDark = Color(0xFF16A34A);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentGold = Color(0xFFF59E0B);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Text & Typography
  static const Color textDark = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // Status & Feedback
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFE0F2FE);

  // Operators
  static const Color gp = Color(0xFF0284C7);
  static const Color robi = Color(0xFFE11D48);
  static const Color airtel = Color(0xFFEF4444);
  static const Color banglalink = Color(0xFFF97316);
  static const Color teletalk = Color(0xFF16A34A);

  // MFS Gateways
  static const Color bkash = Color(0xFFE2136E);
  static const Color nagad = Color(0xFFF7941D);
  static const Color rocket = Color(0xFF8C3494);
  static const Color upay = Color(0xFF005697);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0A4427), Color(0xFF0D5E36), Color(0xFF15803D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0F5132), Color(0xFF107C41)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppConstants {
  static const String appName = 'আলোকিত টেলিকম';
  static const String appNameEn = 'Alokito Telecom';
  static const String appTagline = 'সেরা ড্রাইভ অফার ও ইনস্ট্যান্ট রিচার্জ';
  static const String appTaglineEn = 'Best Drive Offers & Instant Top-Up';
  
  // Default API Endpoint
  static const String defaultBaseUrl = 'https://alokito-telecom-backend-1.onrender.com/api/v1';
  static const String localBaseUrl = 'http://localhost:4000/api/v1';
  static const String emulatorBaseUrl = 'http://10.0.2.2:4000/api/v1';
}
