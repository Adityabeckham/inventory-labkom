import 'package:flutter/foundation.dart';

import '../../../core/theme/status_style.dart';

/// Satu baris barang di dalam transaksi peminjaman (`peminjaman_detail`).
@immutable
class PeminjamanItem {
  const PeminjamanItem({
    required this.idDetail,
    required this.idBarang,
    required this.kodeBarang,
    required this.namaBarang,
    required this.jumlahPinjam,
    this.merk,
  });

  final int idDetail;
  final int idBarang;
  final String kodeBarang;
  final String namaBarang;
  final int jumlahPinjam;
  final String? merk;

  factory PeminjamanItem.fromJson(Map<String, dynamic> json) => PeminjamanItem(
        idDetail: (json['id_detail'] as num).toInt(),
        idBarang: (json['id_barang'] as num).toInt(),
        kodeBarang: json['kode_barang'] as String? ?? '-',
        namaBarang: json['nama_barang'] as String? ?? '-',
        jumlahPinjam: (json['jumlah_pinjam'] as num).toInt(),
        merk: json['merk'] as String?,
      );
}

/// Header transaksi peminjaman (FR-05).
///
/// [items] hanya terisi pada respons detail; daftar ringkas mengirim
/// [jumlahItem] dan [totalUnit] saja supaya payload listnya tetap kecil.
@immutable
class Peminjaman {
  const Peminjaman({
    required this.id,
    required this.kode,
    required this.idPeminjam,
    required this.namaPeminjam,
    required this.dicatatOleh,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.status,
    required this.jumlahItem,
    required this.totalUnit,
    this.nisNip,
    this.kelasJabatan,
    this.alasanDibatalkan,
    this.items = const [],
  });

  final int id;
  final String kode;
  final int idPeminjam;
  final String namaPeminjam;

  /// Username Laboran yang mencatat transaksi.
  final String dicatatOleh;

  final String tanggalPinjam;

  /// Rencana kembali / jatuh tempo.
  final String tanggalKembali;

  final StatusPeminjaman status;

  /// Banyaknya jenis barang.
  final int jumlahItem;

  /// Total unit dari seluruh jenis barang.
  final int totalUnit;

  final String? nisNip;
  final String? kelasJabatan;
  final String? alasanDibatalkan;
  final List<PeminjamanItem> items;

  bool get menungguVerifikasi => status == StatusPeminjaman.menungguVerifikasi;

  /// Identitas peminjam dalam satu baris, tanpa pemisah menggantung kalau
  /// NIS atau kelasnya tidak diisi.
  String get identitasPeminjam => [
        if (nisNip?.isNotEmpty ?? false) nisNip!,
        if (kelasJabatan?.isNotEmpty ?? false) kelasJabatan!,
      ].join(' · ');

  factory Peminjaman.fromJson(Map<String, dynamic> json) {
    final status = StatusPeminjaman.tryParse(json['status'] as String?);
    if (status == null) {
      throw FormatException('Status peminjaman tidak dikenali: ${json['status']}');
    }

    final rawItems = json['items'] as List<dynamic>?;

    return Peminjaman(
      id: (json['id_peminjaman'] as num).toInt(),
      kode: json['kode_peminjaman'] as String,
      idPeminjam: (json['id_peminjam'] as num).toInt(),
      namaPeminjam: json['nama_peminjam'] as String? ?? '-',
      dicatatOleh: json['dicatat_oleh'] as String? ?? '-',
      tanggalPinjam: json['tanggal_pinjam'] as String? ?? '',
      tanggalKembali: json['tanggal_kembali'] as String? ?? '',
      status: status,
      jumlahItem: (json['jumlah_item'] as num?)?.toInt() ?? 0,
      totalUnit: (json['total_unit'] as num?)?.toInt() ?? 0,
      nisNip: json['nis_nip'] as String?,
      kelasJabatan: json['kelas_jabatan'] as String?,
      alasanDibatalkan: json['alasan_dibatalkan'] as String?,
      items: rawItems == null
          ? const []
          : rawItems
              .map((e) => PeminjamanItem.fromJson(e as Map<String, dynamic>))
              .toList(growable: false),
    );
  }
}

/// Satu baris di keranjang form Peminjaman Baru, sebelum dikirim ke server.
///
/// Menyimpan stok barang saat dipilih supaya jumlahnya bisa divalidasi di
/// layar tanpa menunggu balasan server.
@immutable
class ItemKeranjang {
  const ItemKeranjang({
    required this.idBarang,
    required this.kodeBarang,
    required this.namaBarang,
    required this.jumlah,
    required this.stokTersedia,
  });

  final int idBarang;
  final String kodeBarang;
  final String namaBarang;
  final int jumlah;
  final int stokTersedia;

  ItemKeranjang copyWith({int? jumlah}) => ItemKeranjang(
        idBarang: idBarang,
        kodeBarang: kodeBarang,
        namaBarang: namaBarang,
        jumlah: jumlah ?? this.jumlah,
        stokTersedia: stokTersedia,
      );

  Map<String, dynamic> toJson() => {'id_barang': idBarang, 'jumlah': jumlah};
}
