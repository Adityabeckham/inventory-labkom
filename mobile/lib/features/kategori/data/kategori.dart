import 'package:flutter/foundation.dart';

@immutable
class Kategori {
  const Kategori({
    required this.id,
    required this.nama,
    required this.jumlahBarang,
  });

  final int id;
  final String nama;
  final int jumlahBarang;

  factory Kategori.fromJson(Map<String, dynamic> json) => Kategori(
        id: (json['id_kategori'] as num).toInt(),
        nama: json['nama_kategori'] as String,
        jumlahBarang: (json['jumlah_barang'] as num?)?.toInt() ?? 0,
      );
}
