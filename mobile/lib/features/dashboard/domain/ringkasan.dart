import 'package:flutter/foundation.dart';

/// Angka ringkasan Dashboard (FR-10), cerminan `GET /api/dashboard`.
///
/// [unitDipinjam] dan [unitDiajukan] sengaja dipisah. Stok berkurang sejak
/// pengajuan dibuat, jadi kalau keduanya digabung jadi satu angka "Sedang
/// Dipinjam", angkanya akan lebih besar dari jumlah transaksi yang benar-benar
/// disetujui — dan itu terbaca seperti bug. Hubungannya:
///
///   totalUnit - unitTersedia == unitDipinjam + unitDiajukan
@immutable
class RingkasanDashboard {
  const RingkasanDashboard({
    required this.jenisBarang,
    required this.totalUnit,
    required this.unitTersedia,
    required this.jenisHabis,
    required this.unitDipinjam,
    required this.transaksiDipinjam,
    required this.unitDiajukan,
    required this.menungguVerifikasi,
    required this.terlambat,
    required this.totalDenda,
  });

  final int jenisBarang;
  final int totalUnit;
  final int unitTersedia;
  final int jenisHabis;

  final int unitDipinjam;
  final int transaksiDipinjam;
  final int unitDiajukan;
  final int menungguVerifikasi;
  final int terlambat;

  final double totalDenda;

  factory RingkasanDashboard.fromJson(Map<String, dynamic> json) {
    final barang = json['barang'] as Map<String, dynamic>? ?? const {};
    final pinjam = json['peminjaman'] as Map<String, dynamic>? ?? const {};
    final denda = json['denda'] as Map<String, dynamic>? ?? const {};

    int angka(Map<String, dynamic> sumber, String kunci) =>
        (sumber[kunci] as num?)?.toInt() ?? 0;

    return RingkasanDashboard(
      jenisBarang: angka(barang, 'jenis'),
      totalUnit: angka(barang, 'total_unit'),
      unitTersedia: angka(barang, 'unit_tersedia'),
      jenisHabis: angka(barang, 'jenis_habis'),
      unitDipinjam: angka(pinjam, 'unit_dipinjam'),
      transaksiDipinjam: angka(pinjam, 'transaksi_dipinjam'),
      unitDiajukan: angka(pinjam, 'unit_diajukan'),
      menungguVerifikasi: angka(pinjam, 'menunggu_verifikasi'),
      terlambat: angka(pinjam, 'terlambat'),
      totalDenda: (denda['total_tercatat'] as num?)?.toDouble() ?? 0,
    );
  }
}
