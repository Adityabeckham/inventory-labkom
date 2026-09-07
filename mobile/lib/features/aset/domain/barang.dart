import 'package:flutter/foundation.dart';

@immutable
class Barang {
  const Barang({
    required this.id,
    required this.idKategori,
    required this.namaKategori,
    required this.kode,
    required this.nama,
    required this.jumlah,
    required this.stok,
    required this.tanggalInput,
    this.merk,
    this.kondisi,
    this.serialNumber,
  });

  final int id;
  final int idKategori;
  final String namaKategori;
  final String kode;
  final String nama;

  /// Total unit yang dimiliki laboratorium.
  final int jumlah;

  /// Unit yang sedang tersedia — berkurang saat dipinjam.
  final int stok;

  final String tanggalInput;
  final String? merk;
  final String? kondisi;
  final String? serialNumber;

  /// Unit yang tidak ada di rak: sudah diambil peminjam ATAU masih tertahan
  /// pengajuan yang menunggu verifikasi.
  ///
  /// Keduanya tidak bisa dipisahkan dari sini, karena stok berkurang sejak
  /// peminjaman diajukan (FR-05), bukan sejak disetujui. Karena itu namanya
  /// bukan "sedangDipinjam" — sebagian di antaranya mungkin masih di rak
  /// menunggu keputusan Kepala Program.
  int get tidakDiRak => jumlah - stok;

  bool get tersedia => stok > 0;

  factory Barang.fromJson(Map<String, dynamic> json) => Barang(
        id: (json['id_barang'] as num).toInt(),
        idKategori: (json['id_kategori'] as num).toInt(),
        namaKategori: json['nama_kategori'] as String? ?? '-',
        kode: json['kode_barang'] as String,
        nama: json['nama_barang'] as String,
        jumlah: (json['jumlah'] as num).toInt(),
        stok: (json['stok'] as num).toInt(),
        tanggalInput: json['tanggal_input'] as String? ?? '',
        merk: json['merk'] as String?,
        kondisi: json['kondisi'] as String?,
        serialNumber: json['serial_number'] as String?,
      );
}
