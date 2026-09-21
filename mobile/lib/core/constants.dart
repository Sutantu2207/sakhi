import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Secondary
  static const Color primaryViolet = Color(0xFF3A1C71);
  static const Color softLavender = Color(0xFFE8E2F7);
  static const Color darkCharcoal = Color(0xFF1F1F24);

  // Status & Emergency System
  static const Color emergencyCoral = Color(0xFFE63946);
  static const Color warningAmber = Color(0xFFF4A261);
  static const Color successEmerald = Color(0xFF2A9D8F);

  // Backgrounds & Neutrals
  static const Color surface = Color(0xFFF8F9FC);
  static const Color cardBg = Colors.white;
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);
}

class AppConstants {
  static const String appName = 'SAKHI';
  static const String appTagline = 'Travel safer. Respond faster. Stay connected.';
  static const String safetyPhilosophy = 'Sakhi helps you make informed safety decisions and access support faster.';

  // Default Backend API endpoint (localhost:8000 for web/desktop, 10.0.2.2:8000 for Android emulator)
  static const String defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';

  // National Helplines
  static const String helplineEmergency = '112';
  static const String helplineWomen = '1091';
  static const String helplineCybercrime = '1930';
  static const String helplineOneStopCrisis = '181';
}
