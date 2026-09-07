import 'package:flutter/foundation.dart';

import '../../../core/theme/status_style.dart';
import '../../pengembalian/domain/pengembalian.dart';

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
    this.pengembalian,
  });

  final int idDetail;
  final int idBarang;
  final String kodeBarang;
  final String namaBarang;
  final int jumlahPinjam;
  final String? merk;

  /// Null berarti barang ini masih di tangan peminjam.
  ///
  /// Satu baris detail dikembalikan UTUH atau belum sama sekali — tabelnya
  /// tidak punya kolom jumlah (D-03), jadi tidak ada keadaan "2 dari 3".
  final InfoPengembalian? pengembalian;

  bool get sudahKembali => pengembalian != null;

  factory PeminjamanItem.fromJson(Map<String, dynamic> json) {
    final pg = json['pengembalian'] as Map<String, dynamic>?;

    return PeminjamanItem(
      idDetail: (json['id_detail'] as num).toInt(),
      idBarang: (json['id_barang'] as num).toInt(),
      kodeBarang: json['kode_barang'] as String? ?? '-',
      namaBarang: json['nama_barang'] as String? ?? '-',
      jumlahPinjam: (json['jumlah_pinjam'] as num).toInt(),
      merk: json['merk'] as String?,
      pengembalian: pg == null ? null : InfoPengembalian.fromJson(pg),
    );
  }
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
    this.totalDenda = 0,
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

  /// Jumlah denda seluruh item yang sudah dikembalikan. Hanya terisi pada
  /// respons detail.
  final double totalDenda;

  final String? nisNip;
  final String? kelasJabatan;
  final String? alasanDibatalkan;
  final List<PeminjamanItem> items;

  bool get menungguVerifikasi => status == StatusPeminjaman.menungguVerifikasi;

  /// Barang yang masih di tangan peminjam. Kosong pada respons daftar,
  /// karena rinciannya hanya dikirim pada respons detail.
  List<PeminjamanItem> get belumKembali =>
      items.where((i) => !i.sudahKembali).toList(growable: false);

  /// Boleh menerima pengembalian: sudah disetujui dan masih ada sisa.
  ///
  /// HANYA sahih pada objek hasil respons DETAIL. Respons daftar tidak
  /// mengirim `items`, jadi [belumKembali] kosong dan getter ini selalu
  /// false di sana — bukan karena transaksinya selesai, melainkan karena
  /// rinciannya belum dimuat. Jangan dipakai untuk menyaring daftar; untuk
  /// itu pakai `TransaksiPengembalian.itemSisa` dari endpoint pengembalian.
  bool get bisaDikembalikan =>
      (status == StatusPeminjaman.dipinjam ||
          status == StatusPeminjaman.sebagianKembali) &&
      belumKembali.isNotEmpty;

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
      totalDenda: (json['total_denda'] as num?)?.toDouble() ?? 0,
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
