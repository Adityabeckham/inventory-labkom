import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Status transaksi peminjaman — cerminan ENUM `peminjaman.status` di database.
/// Lihat Database_Final_dan_Arsitektur.md §3.5.
enum StatusPeminjaman {
  menungguVerifikasi('menunggu_verifikasi', 'Menunggu Verifikasi'),
  dipinjam('dipinjam', 'Dipinjam'),
  sebagianKembali('sebagian_kembali', 'Sebagian Kembali'),
  dikembalikan('dikembalikan', 'Dikembalikan'),
  dibatalkan('dibatalkan', 'Dibatalkan');

  const StatusPeminjaman(this.value, this.label);

  /// Nilai persis seperti yang disimpan database.
  final String value;

  /// Teks yang ditampilkan ke pengguna.
  final String label;

  static StatusPeminjaman? tryParse(String? raw) {
    if (raw == null) return null;
    for (final s in values) {
      if (s.value == raw) return s;
    }
    return null;
  }
}

/// Status TURUNAN pada layar Pengembalian — dihitung backend dari data
/// peminjaman + detail + pengembalian, bukan kolom di database.
/// Lihat Database_Final_dan_Arsitektur.md §3.7.1.
///
/// Keempatnya bukan pembagian yang saling lepas: satu transaksi bisa memenuhi
/// "Sebagian Kembali" sekaligus "Terlambat". Nilai di sini adalah badge
/// tunggal yang sudah dipilih backend dengan urutan Terlambat menang.
enum StatusPengembalian {
  belumKembali('belum_kembali', 'Belum Kembali'),
  sebagianKembali('sebagian_kembali', 'Sebagian Kembali'),
  sudahKembali('sudah_kembali', 'Sudah Kembali'),
  terlambat('terlambat', 'Terlambat');

  const StatusPengembalian(this.value, this.label);

  final String value;
  final String label;

  static StatusPengembalian? tryParse(String? raw) {
    if (raw == null) return null;
    for (final s in values) {
      if (s.value == raw) return s;
    }
    return null;
  }
}

/// Warna badge status. Pemetaan mengikuti UIUX_Wireframe_dan_Flow.md §4.
@immutable
class StatusStyle {
  const StatusStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;

  static const _pending = StatusStyle(
    background: AppColors.pendingBg,
    foreground: AppColors.pendingFg,
    border: AppColors.pendingBorder,
  );
  static const _active = StatusStyle(
    background: AppColors.navyTint,
    foreground: AppColors.navy,
    border: AppColors.navyTint,
  );
  static const _partial = StatusStyle(
    background: AppColors.partialBg,
    foreground: AppColors.partialFg,
    border: AppColors.partialBorder,
  );
  static const _success = StatusStyle(
    background: AppColors.successBg,
    foreground: AppColors.successFg,
    border: AppColors.successBorder,
  );
  static const _danger = StatusStyle(
    background: AppColors.dangerBg,
    foreground: AppColors.dangerFg,
    border: AppColors.dangerBorder,
  );

  static StatusStyle of(StatusPeminjaman status) => switch (status) {
        StatusPeminjaman.menungguVerifikasi => _pending,
        StatusPeminjaman.dipinjam => _active,
        StatusPeminjaman.sebagianKembali => _partial,
        StatusPeminjaman.dikembalikan => _success,
        StatusPeminjaman.dibatalkan => _danger,
      };

  static StatusStyle ofPengembalian(StatusPengembalian status) => switch (status) {
        StatusPengembalian.belumKembali => _active,
        StatusPengembalian.sebagianKembali => _partial,
        StatusPengembalian.sudahKembali => _success,
        StatusPengembalian.terlambat => _danger,
      };

  /// Barang tersedia / stok aman.
  static const tersedia = _success;

  /// Stok menipis, barang rusak, atau pengembalian terlambat.
  static const kritis = _danger;

  /// Tag kategori — netral, bukan status.
  static const kategori = StatusStyle(
    background: AppColors.neutralBg,
    foreground: AppColors.neutralFg,
    border: AppColors.neutralBg,
  );
}
