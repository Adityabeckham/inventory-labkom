import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Skala tipografi dari `design/DESIGN.md`.
///
/// Letter spacing di dokumen ditulis dalam em; di sini sudah dikalikan ukuran
/// fontnya, karena Flutter memakai logical pixel.
abstract final class AppTypography {
  /// Inter di-bundel sebagai aset, bukan diambil `google_fonts` saat runtime.
  ///
  /// Aplikasi ini dipakai di lab yang koneksinya tidak selalu ada, jadi font
  /// tidak boleh bergantung pada unduhan pertama. Efek sampingnya: pengujian
  /// widget mengukur metrik Inter yang sebenarnya, bukan font pengganti.
  static const String family = 'Inter';

  /// Inter yang di-bundel adalah variable font. Pada variable font,
  /// [TextStyle.fontWeight] saja tidak menggeser sumbu `wght` — nilainya harus
  /// disebut lewat [FontVariation], kalau tidak semua teks tampil Regular.
  static List<FontVariation> _wght(FontWeight weight) =>
      [FontVariation('wght', weight.value.toDouble())];

  /// Menempelkan Inter pada gaya bawaan Material untuk slot yang tidak
  /// disebut `DESIGN.md`, lengkap dengan sumbu berat yang sesuai.
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
      // Empat slot berikut tidak punya token di DESIGN.md dan tidak dipakai
      // layar mana pun; ukurannya dibiarkan bawaan Material, fontnya diseragamkan.
      displayMedium: _inter(base.displayMedium),
      displaySmall: _inter(base.displaySmall),
      headlineSmall: _inter(base.headlineSmall),
      titleSmall: _inter(base.titleSmall),
    );
  }

  /// code-md — kode barang, serial number, kode transaksi.
  ///
  /// Angka dibuat tabular supaya lebarnya seragam, dan tracking dilonggarkan
  /// agar `0` tidak tertukar dengan `O`, atau `1` dengan `l`, saat laboran
  /// mencocokkan label fisik di rak.
  static TextStyle code({Color color = AppColors.textPrimary}) {
    return TextStyle(
      fontFamily: family,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      fontVariations: _wght(FontWeight.w500),
      height: 18 / 13,
      letterSpacing: 0.65,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
