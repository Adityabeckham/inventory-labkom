/// Token jarak dan radius dari `design/Design System.md` (Specification: Hyper-Minimal Utility).
abstract final class AppSpacing {
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 20.0;
  static const space6 = 24.0;
  static const space8 = 32.0;

  // Aliases for compatibility
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

  /// Jarak antar kartu bento.
  static const cardGap = 12.0;

  static const appBarHeight = 64.0;
  static const bottomNavHeight = 80.0;
}

abstract final class AppRadius {
  /// 8px — Badge tag kecil, check indicator
  static const sm = 8.0;
  static const base = 8.0;

  /// 12px — Input control, chip status, tombol reguler
  static const md = 12.0;

  /// 16px — Kartu baris riwayat/aktivitas, banner info
  static const lg = 16.0;

  /// 24px — Kartu bento 2x2, kartu statistik ringkas, App Bar
  static const xl = 24.0;

  /// 32px — Kartu hero utama, kartu tumpukan (stacked deck)
  static const xxl = 32.0;

  /// 9999px — Tombol bulat aksi (Quick Action), pill progress, avatar bulat
  static const pill = 9999.0;
  static const full = 9999.0;
}

/// Target sentuh minimum Material 3.
const double kMinTouchTarget = 48.0;
