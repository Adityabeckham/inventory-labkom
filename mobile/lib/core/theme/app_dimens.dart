/// Token jarak dan radius dari `design/DESIGN.md`.
/// Nilai rem di dokumen dikonversi ke logical pixel dengan basis 16.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Margin tepi layar pada viewport mobile.
  static const screenMargin = 16.0;

  /// Jarak antar kartu dalam daftar padat.
  static const cardGap = 12.0;

  static const appBarHeight = 64.0;
  static const bottomNavHeight = 80.0;
}

abstract final class AppRadius {
  static const sm = 4.0;
  static const base = 8.0;

  /// Input, tombol, segmented control.
  static const md = 12.0;

  /// Kartu, modal sheet, blok ringkasan.
  static const lg = 16.0;

  /// Lengkung bawah app bar.
  static const xl = 24.0;

  /// Chip dan badge status — bentuk pil penuh.
  static const pill = 9999.0;
}

/// Target sentuh minimum Material 3, berlaku walau ikonnya kecil.
const double kMinTouchTarget = 48.0;
