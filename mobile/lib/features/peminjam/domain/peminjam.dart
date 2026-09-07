import 'package:flutter/foundation.dart';

/// Siswa/guru/staf yang meminjam barang.
///
/// Bukan akun login — itu `AppUser` (FR-12 Kelola User).
@immutable
class Peminjam {
  const Peminjam({
    required this.id,
    required this.nama,
    this.nisNip,
    this.kelasJabatan,
    this.noHp,
  });

  final int id;
  final String nama;
  final String? nisNip;
  final String? kelasJabatan;
  final String? noHp;

  factory Peminjam.fromJson(Map<String, dynamic> json) => Peminjam(
        id: (json['id_peminjam'] as num).toInt(),
        nama: json['nama_peminjam'] as String,
        nisNip: json['nis_nip'] as String?,
        kelasJabatan: json['kelas_jabatan'] as String?,
        noHp: json['no_hp'] as String?,
      );
}
