import 'package:flutter/foundation.dart';

/// Arah mutasi — cerminan ENUM `stok_mutasi.jenis`.
enum JenisMutasi {
  masuk('masuk', 'Masuk'),
  keluar('keluar', 'Keluar');

  const JenisMutasi(this.value, this.label);

  final String value;
  final String label;

  static JenisMutasi? tryParse(String? raw) {
    if (raw == null) return null;
    for (final j in values) {
      if (j.value == raw) return j;
    }
    return null;
  }
}

@immutable
class StokMutasi {
  const StokMutasi({
    required this.id,
    required this.idBarang,
    required this.kodeBarang,
    required this.namaBarang,
    required this.jenis,
    required this.jumlah,
    required this.tanggal,
    required this.dicatatOleh,
    this.keterangan,
  });

  final int id;
  final int idBarang;
  final String kodeBarang;
  final String namaBarang;
  final JenisMutasi jenis;
  final int jumlah;
  final String tanggal;
  final String dicatatOleh;
  final String? keterangan;

  factory StokMutasi.fromJson(Map<String, dynamic> json) {
    final jenis = JenisMutasi.tryParse(json['jenis'] as String?);
    if (jenis == null) {
      throw FormatException('Jenis mutasi tidak dikenali: ${json['jenis']}');
    }

    return StokMutasi(
      id: (json['id_mutasi'] as num).toInt(),
      idBarang: (json['id_barang'] as num).toInt(),
      kodeBarang: json['kode_barang'] as String? ?? '-',
      namaBarang: json['nama_barang'] as String? ?? '-',
      jenis: jenis,
      jumlah: (json['jumlah'] as num).toInt(),
      tanggal: json['tanggal_mutasi'] as String? ?? '',
      dicatatOleh: json['dicatat_oleh'] as String? ?? '-',
      keterangan: json['keterangan'] as String?,
    );
  }
}
