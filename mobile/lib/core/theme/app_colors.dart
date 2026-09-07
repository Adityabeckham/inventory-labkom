import 'package:flutter/material.dart';

/// Token warna dari `design/DESIGN.md`.
///
/// Catatan deviasi: frontmatter DESIGN.md menulis `primary: #1e3484`, sedangkan
/// bagian prosanya, PRD §10 Putaran 4, dan wireframe UI/UX sama-sama menyebut
/// `#384C9D` sebagai Deep Navy identitas aplikasi. Tiga rujukan mengalahkan
/// satu, jadi `#384C9D` yang dipakai sebagai primary. Nilai frontmatter tetap
/// dipertahankan untuk peran turunan (container, on-color, surface).
abstract final class AppColors {
  // ── Merek ──────────────────────────────────────────────────────────
  /// Deep Navy — app bar, tombol aksi utama, tab aktif.
  static const navy = Color(0xFF384C9D);
  static const navyDark = Color(0xFF1E3484);
  static const navyTint = Color(0xFFEEF2FF);
  static const onNavy = Color(0xFFFFFFFF);

  /// Crimson — FAB, aksi destruktif, peringatan stok kritis & keterlambatan.
  static const crimson = Color(0xFFD8232A);
  static const crimsonDark = Color(0xFFBB0119);
  static const onCrimson = Color(0xFFFFFFFF);

  /// Gold — menunggu verifikasi, flag perawatan.
  /// Selalu dipasangkan teks gelap; teks putih di atas gold gagal kontras.
  static const gold = Color(0xFFFCD116);
  static const onGold = Color(0xFF78350F);

  // ── Permukaan ──────────────────────────────────────────────────────
  static const canvas = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFE7EEFF);

  // ── Teks & garis ───────────────────────────────────────────────────
  static const textPrimary = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
  static const outline = Color(0xFFE2E8F0);
  static const outlineStrong = Color(0xFFCBD5E1);

  // ── Status semantik (DESIGN.md §Status Badges) ─────────────────────
  static const successBg = Color(0xFFECFDF5);
  static const successFg = Color(0xFF065F46);
  static const successBorder = Color(0xFFA7F3D0);

  static const pendingBg = Color(0xFFFEF9C3);
  static const pendingFg = Color(0xFF854D0E);
  static const pendingBorder = Color(0xFFFDE047);

  static const dangerBg = Color(0xFFFEF2F2);
  static const dangerFg = Color(0xFF991B1B);
  static const dangerBorder = Color(0xFFFECACA);

  /// Gaya tambahan untuk status `sebagian_kembali` — tidak ada di DESIGN.md,
  /// dibentuk mengikuti formula yang sama (bg muda + teks tua + border tipis).
  /// Lihat UIUX_Wireframe_dan_Flow.md §4.
  static const partialBg = Color(0xFFEFF6FF);
  static const partialFg = Color(0xFF1E40AF);
  static const partialBorder = Color(0xFFBFDBFE);

  static const neutralBg = Color(0xFFF1F5F9);
  static const neutralFg = Color(0xFF475569);

  static const error = Color(0xFFBA1A1A);
}
