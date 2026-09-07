import 'package:flutter/material.dart';

/// Format keluaran laporan (FR-08).
enum FormatLaporan {
  pdf('pdf', 'PDF', 'application/pdf', Icons.picture_as_pdf_outlined),
  docx(
    'docx',
    'Word',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    Icons.description_outlined,
  ),
  xlsx(
    'xlsx',
    'Excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    Icons.table_chart_outlined,
  );

  const FormatLaporan(this.value, this.label, this.mime, this.ikon);

  final String value;
  final String label;
  final String mime;
  final IconData ikon;
}

/// Kelima jenis laporan. `slug` sekaligus jadi segmen terakhir endpoint-nya.
enum JenisLaporan {
  barang(
    'barang',
    'Data Barang',
    'Seluruh barang beserta kategori, merk, kondisi, dan serial number.',
    Icons.inventory_2_outlined,
    berperiode: true,
    dasarPeriode: 'tanggal input barang',
  ),
  peminjaman(
    'peminjaman',
    'Peminjaman',
    'Transaksi peminjaman beserta peminjam, jatuh tempo, dan statusnya.',
    Icons.swap_horiz_outlined,
    berperiode: true,
    dasarPeriode: 'tanggal pinjam',
  ),
  pengembalian(
    'pengembalian',
    'Pengembalian',
    'Barang yang sudah dikembalikan, kondisinya, dan denda per item.',
    Icons.assignment_return_outlined,
    berperiode: true,
    dasarPeriode: 'tanggal pengembalian',
  ),
  stok(
    'stok',
    'Stok Barang',
    'Keadaan stok saat ini: total unit, tersedia, dan yang sedang di luar rak.',
    Icons.warehouse_outlined,
    berperiode: false,
  ),
  denda(
    'denda',
    'Denda',
    'Rekap keterlambatan beserta nominal denda yang tercatat.',
    Icons.payments_outlined,
    berperiode: true,
    dasarPeriode: 'tanggal pengembalian',
  );

  const JenisLaporan(
    this.slug,
    this.judul,
    this.keterangan,
    this.ikon, {
    required this.berperiode,
    this.dasarPeriode,
  });

  final String slug;
  final String judul;
  final String keterangan;
  final IconData ikon;

  /// Laporan Stok tidak punya periode — isinya keadaan saat ini, bukan
  /// rentang waktu, jadi filter tanggalnya disembunyikan.
  final bool berperiode;

  /// Kolom tanggal yang disaring, dijelaskan ke pengguna supaya filternya
  /// tidak terasa sewenang-wenang.
  final String? dasarPeriode;
}
