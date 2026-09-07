import 'package:flutter/material.dart';

/// Token warna dari `design/Design System.md` (Specification: Hyper-Minimal Utility).
abstract final class AppColors {
  // ── 2.1 Core Brand (Electric Blue Series) ───────────────────────────
  /// Electric Blue — jangkar visual utama, tombol primer, kartu hero.
  static const primary = Color(0xFF1622E5);
  static const brandHover = Color(0xFF0C16B6);
  static const brandSurfaceTint = Color(0xFFEBF1FE);
  static const brandBorderTint = Color(0xFFBED3FF);
  static const brandSubtle = Color(0xFF84ABFF);

  /// Backwards compatibility alias for navy
  static const navy = primary;
  static const navyDark = brandHover;
  static const navyTint = brandSurfaceTint;
  static const onNavy = Color(0xFFFFFFFF);

  /// Crimson / Secondary — FAB, aksi destruktif & peringatan.
  static const crimson = Color(0xFFEF4444);
  static const crimsonDark = Color(0xFFDC2626);
  static const onCrimson = Color(0xFFFFFFFF);

  /// Gold / Warning
  static const gold = Color(0xFFF59E0B);
  static const onGold = Color(0xFF78350F);

  // ── 2.2 Semantic & Status Tokens ────────────────────────────────────
  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFECFDF5);
  static const successFg = Color(0xFF047857);
  static const successBorder = Color(0xFFA7F3D0);

  static const warning = Color(0xFFF59E0B);
  static const pendingBg = Color(0xFFFEF3C7);
  static const pendingFg = Color(0xFFB45309);
  static const pendingBorder = Color(0xFFFDE68A);

  static const danger = Color(0xFFEF4444);
  static const dangerBg = Color(0xFFFEF2F2);
  static const dangerFg = Color(0xFFB91C1C);
  static const dangerBorder = Color(0xFFFECACA);

  static const info = Color(0xFF3B82F6);
  static const partialBg = Color(0xFFEFF6FF);
  static const partialFg = Color(0xFF1D4ED8);
  static const partialBorder = Color(0xFFBFDBFE);

  static const neutralBg = Color(0xFFF1F3F7);
  static const neutralFg = Color(0xFF475569);
  static const error = Color(0xFFEF4444);

  // ── 2.3 Neutral & Surface Tokens ────────────────────────────────────
  static const canvas = Color(0xFFF8F9FA);
  static const cardBase = Color(0xFFFFFFFF);
  static const cardSubtle = Color(0xFFF4F6F9);
  static const pillInactive = Color(0xFFF1F3F7);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFEBF1FE);

  static const textPrimary = Color(0xFF111217);
  static const textSecondary = Color(0xFF374151);
  static const textMuted = Color(0xFF8E93A4);

  static const borderSubtle = Color(0xFFF0F1F5);
  static const outline = Color(0xFFF0F1F5);
  static const outlineStrong = Color(0xFFD1D5DB);

  static const darkHeaderBtn = Color(0xFF111217);
}

/// Gradient aksen Hyper-Minimal Utility (Electric Blue, Bento Cards).
abstract final class AppGradients {
  /// Saturated Electric Blue Gradient — Hero Card & Peak Highlights.
  static const electricBlue = LinearGradient(
    colors: [Color(0xFF1622E5), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Primary Brand Gradient
  static const primaryNavy = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1622E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft Electric Tinted Surface
  static const softBlue = LinearGradient(
    colors: [Color(0xFFEBF1FE), Color(0xFFF4F8FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Crimson Gradient
  static const crimson = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Ambient & Electric Saturated Shadows dari Design System §4.3.
abstract final class AppShadows {
  /// Subtle Ambient (Kartu putih standar)
  static const subtleAmbient = [
    BoxShadow(
      color: Color(0x08111217),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x05111217),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Focused Lift (Kartu saat ditekan)
  static const focusedLift = [
    BoxShadow(
      color: Color(0x0F111217),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x08111217),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  /// Electric Saturated Glow (Khusus untuk permukaan Electric Blue)
  static const electricGlow = [
    BoxShadow(
      color: Color(0x591622E5),
      blurRadius: 36,
      offset: Offset(0, 16),
    ),
  ];
}
