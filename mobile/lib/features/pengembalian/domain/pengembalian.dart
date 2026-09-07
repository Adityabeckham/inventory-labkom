import 'package:flutter/foundation.dart';

import '../../../core/theme/status_style.dart';

/// Kondisi barang saat dikembalikan — cerminan ENUM `pengembalian.kondisi`.
enum KondisiBarang {
  baik('baik', 'Baik'),
  rusak('rusak', 'Rusak');

  const KondisiBarang(this.value, this.label);

  final String value;
  final String label;

  static KondisiBarang? tryParse(String? raw) {
    if (raw == null) return null;
    for (final k in values) {
      if (k.value == raw) return k;
    }
    return null;
  }
}

/// Catatan pengembalian satu baris `peminjaman_detail`.
///
/// Denda dan hari telat dihitung backend saat dicatat lalu disimpan di
/// barisnya, jadi angka di sini tidak ikut berubah kalau tarif diubah nanti.
@immutable
class InfoPengembalian {
  const InfoPengembalian({
    required this.id,
    required this.tanggal,
    required this.kondisi,
    required this.hariTelat,
    required this.denda,
  });

  final int id;
  final String tanggal;
  final KondisiBarang kondisi;
  final int hariTelat;
  final double denda;

  bool get telat => hariTelat > 0;

  factory InfoPengembalian.fromJson(Map<String, dynamic> json) {
    final kondisi = KondisiBarang.tryParse(json['kondisi'] as String?);
    if (kondisi == null) {
      throw FormatException('Kondisi barang tidak dikenali: ${json['kondisi']}');
    }

    return InfoPengembalian(
      id: (json['id_pengembalian'] as num).toInt(),
      tanggal: json['tanggal_pengembalian'] as String? ?? '',
      kondisi: kondisi,
      hariTelat: (json['jumlah_hari_telat'] as num?)?.toInt() ?? 0,
      denda: (json['denda'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Satu baris di daftar layar Pengembalian — ringkasan per transaksi.
@immutable
class TransaksiPengembalian {
  const TransaksiPengembalian({
    required this.idPeminjaman,
    required this.kode,
    required this.namaPeminjam,
    required this.dicatatOleh,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.tampilanStatus,
    required this.jumlahItem,
    required this.totalUnit,
    required this.itemSisa,
    required this.itemKembali,
    required this.totalDenda,
    this.nisNip,
    this.kelasJabatan,
  });

  final int idPeminjaman;
  final String kode;
  final String namaPeminjam;
  final String dicatatOleh;
  final String tanggalPinjam;

  /// Jatuh tempo.
  final String tanggalKembali;

  /// Badge tunggal yang sudah dipilih backend (Terlambat menang).
  final StatusPengembalian tampilanStatus;

  final int jumlahItem;
  final int totalUnit;

  /// Baris detail yang belum punya catatan pengembalian.
  final int itemSisa;

  final int itemKembali;
  final double totalDenda;

  final String? nisNip;
  final String? kelasJabatan;

  bool get selesai => itemSisa == 0;

  String get identitasPeminjam => [
        if (nisNip?.isNotEmpty ?? false) nisNip!,
        if (kelasJabatan?.isNotEmpty ?? false) kelasJabatan!,
      ].join(' · ');

  factory TransaksiPengembalian.fromJson(Map<String, dynamic> json) {
    final status = StatusPengembalian.tryParse(json['tampilan_status'] as String?);
    if (status == null) {
      throw FormatException(
        'Status tampilan pengembalian tidak dikenali: ${json['tampilan_status']}',
      );
    }

    return TransaksiPengembalian(
      idPeminjaman: (json['id_peminjaman'] as num).toInt(),
      kode: json['kode_peminjaman'] as String,
      namaPeminjam: json['nama_peminjam'] as String? ?? '-',
      dicatatOleh: json['dicatat_oleh'] as String? ?? '-',
      tanggalPinjam: json['tanggal_pinjam'] as String? ?? '',
      tanggalKembali: json['tanggal_kembali'] as String? ?? '',
      tampilanStatus: status,
      jumlahItem: (json['jumlah_item'] as num?)?.toInt() ?? 0,
      totalUnit: (json['total_unit'] as num?)?.toInt() ?? 0,
      itemSisa: (json['item_sisa'] as num?)?.toInt() ?? 0,
      itemKembali: (json['item_kembali'] as num?)?.toInt() ?? 0,
      totalDenda: (json['total_denda'] as num?)?.toDouble() ?? 0,
      nisNip: json['nis_nip'] as String?,
      kelasJabatan: json['kelas_jabatan'] as String?,
    );
  }
}

/// FR-11 — tarif denda per hari keterlambatan, per baris barang.
@immutable
class TarifDenda {
  const TarifDenda({required this.tarifPerHari, this.terkonfigurasi = true});

  final double tarifPerHari;

  /// False kalau baris pengaturannya belum ada di database.
  final bool terkonfigurasi;

  factory TarifDenda.fromJson(Map<String, dynamic> json) => TarifDenda(
        tarifPerHari: (json['tarif_per_hari'] as num?)?.toDouble() ?? 0,
        terkonfigurasi: json['terkonfigurasi'] as bool? ?? false,
      );
}

/// Memformat rupiah tanpa paket intl — hanya pemisah ribuan titik.
///
/// Denda selalu bilangan bulat rupiah dalam praktiknya; desimal ditampilkan
/// hanya kalau memang ada, supaya "Rp 5.000" tidak jadi "Rp 5.000,00".
String rupiah(double nilai) {
  final bulat = nilai.truncate();
  final sisa = ((nilai - bulat) * 100).round();

  final digit = bulat.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digit.length; i++) {
    if (i > 0 && (digit.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digit[i]);
  }

  final tanda = nilai < 0 ? '-' : '';
  final desimal = sisa == 0 ? '' : ',${sisa.toString().padLeft(2, '0')}';

  return 'Rp $tanda$buffer$desimal';
}
