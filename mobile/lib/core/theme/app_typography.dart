import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Skala tipografi dari `design/DESIGN.md`.
///
/// Letter spacing di dokumen ditulis dalam em; di sini sudah dikalikan ukuran
/// fontnya, karena Flutter memakai logical pixel.
abstract final class AppTypography {
  static TextTheme build() {
    final base = GoogleFonts.interTextTheme();

    TextStyle style({
      required double size,
      required FontWeight weight,
      required double height,
      double letterSpacing = 0,
      Color color = AppColors.textPrimary,
    }) {
      return GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        // DESIGN.md menulis line-height dalam px; Flutter memakai rasio.
        height: height / size,
        letterSpacing: letterSpacing,
        color: color,
      );
    }

    return base.copyWith(
      // display-lg
      displayLarge: style(size: 32, weight: FontWeight.w700, height: 40, letterSpacing: -0.64),
      // headline-lg
      headlineLarge: style(size: 24, weight: FontWeight.w600, height: 32, letterSpacing: -0.24),
      // headline-md
      headlineMedium: style(size: 20, weight: FontWeight.w600, height: 28),
      // title-lg
      titleLarge: style(size: 18, weight: FontWeight.w600, height: 24),
      // title-md
      titleMedium: style(size: 16, weight: FontWeight.w600, height: 24),
      // body-lg
      bodyLarge: style(size: 16, weight: FontWeight.w400, height: 24),
      // body-md
      bodyMedium: style(size: 14, weight: FontWeight.w400, height: 20, color: AppColors.textMuted),
      // body-sm
      bodySmall: style(size: 12, weight: FontWeight.w400, height: 16, color: AppColors.textMuted),
      // label-lg
      labelLarge: style(size: 14, weight: FontWeight.w600, height: 20, letterSpacing: 0.14),
      // label-md
      labelMedium: style(size: 12, weight: FontWeight.w600, height: 16, letterSpacing: 0.24),
      // label-sm — dipakai badge status, huruf kapital
      labelSmall: style(size: 11, weight: FontWeight.w700, height: 16, letterSpacing: 0.44),
    );
  }

  /// code-md — kode barang, serial number, kode transaksi.
  ///
  /// Angka dibuat tabular supaya lebarnya seragam, dan tracking dilonggarkan
  /// agar `0` tidak tertukar dengan `O`, atau `1` dengan `l`, saat laboran
  /// mencocokkan label fisik di rak.
  static TextStyle code({Color color = AppColors.textPrimary}) {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 18 / 13,
      letterSpacing: 0.65,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
