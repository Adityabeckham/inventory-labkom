import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Skala tipografi dari `design/Design System.md` (Specification: Hyper-Minimal Utility).
abstract final class AppTypography {
  static const String family = 'Inter';

  static List<FontVariation> _wght(FontWeight weight) =>
      [FontVariation('wght', weight.value.toDouble())];

  static TextStyle? _inter(TextStyle? style) => style?.copyWith(
        fontFamily: family,
        fontVariations: _wght(style.fontWeight ?? FontWeight.w400),
      );

  static TextTheme build() {
    final base = Typography.material2021().black;

    TextStyle style({
      required double size,
      required FontWeight weight,
      required double height,
      double letterSpacing = 0,
      Color color = AppColors.textPrimary,
    }) {
      return TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        fontVariations: _wght(weight),
        height: height / size,
        letterSpacing: letterSpacing,
        color: color,
      );
    }

    return base.copyWith(
      // display-number / displayLarge (36px, 900 Black)
      displayLarge: style(size: 36, weight: FontWeight.w900, height: 40, letterSpacing: -1.08),
      // title-screen / headlineLarge (24px, 800 Bold)
      headlineLarge: style(size: 24, weight: FontWeight.w800, height: 28, letterSpacing: -0.48),
      // headline-md (20px, 700 Bold)
      headlineMedium: style(size: 20, weight: FontWeight.w700, height: 26, letterSpacing: -0.2),
      // title-lg (18px, 700 Bold)
      titleLarge: style(size: 18, weight: FontWeight.w700, height: 24, letterSpacing: -0.18),
      // title-section / titleMedium (14px, 700 Bold)
      titleMedium: style(size: 14, weight: FontWeight.w700, height: 18, letterSpacing: -0.14),
      // body-lg (16px, 500 Medium)
      bodyLarge: style(size: 16, weight: FontWeight.w500, height: 22),
      // body-medium (13px, 500 Medium)
      bodyMedium: style(size: 13, weight: FontWeight.w500, height: 18, color: AppColors.textSecondary),
      // body-sm / caption-label (11px, 500 Medium)
      bodySmall: style(size: 11, weight: FontWeight.w500, height: 14, color: AppColors.textMuted),
      // label-lg (14px, 700 Bold)
      labelLarge: style(size: 14, weight: FontWeight.w700, height: 18),
      // label-md (12px, 600 SemiBold)
      labelMedium: style(size: 12, weight: FontWeight.w600, height: 16),
      // label-sm / badge-micro (10px, 700 Bold)
      labelSmall: style(size: 10, weight: FontWeight.w700, height: 12, letterSpacing: 0.2),
      displayMedium: _inter(base.displayMedium),
      displaySmall: _inter(base.displaySmall),
      headlineSmall: _inter(base.headlineSmall),
      titleSmall: _inter(base.titleSmall),
    );
  }

  /// display-number: 36px Black (900)
  static TextStyle displayNumber({Color color = AppColors.textPrimary}) {
    return TextStyle(
      fontFamily: family,
      fontSize: 36,
      fontWeight: FontWeight.w900,
      fontVariations: _wght(FontWeight.w900),
      height: 1.1,
      letterSpacing: -1.08,
      color: color,
    );
  }

  /// metric-card-val: 16px Bold (800)
  static TextStyle metricCardVal({Color color = AppColors.textPrimary}) {
    return TextStyle(
      fontFamily: family,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      fontVariations: _wght(FontWeight.w800),
      height: 1.25,
      letterSpacing: -0.16,
      color: color,
    );
  }

  /// caption-label: 11px Medium (500)
  static TextStyle captionLabel({Color color = AppColors.textMuted}) {
    return TextStyle(
      fontFamily: family,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      fontVariations: _wght(FontWeight.w500),
      height: 1.2,
      letterSpacing: 0.11,
      color: color,
    );
  }

  /// code-md — kode barang, serial number, kode transaksi.
  static TextStyle code({Color color = AppColors.textPrimary}) {
    return TextStyle(
      fontFamily: family,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      fontVariations: _wght(FontWeight.w600),
      height: 18 / 13,
      letterSpacing: 0.5,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
