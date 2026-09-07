import 'package:flutter/foundation.dart';

import '../../auth/domain/app_user.dart';

/// Akun pengguna sebagaimana ditampilkan di layar Kelola User (FR-12).
///
/// Berbeda dari Peminjam (FR-04): peminjam adalah siswa/guru yang meminjam
/// barang dan tidak punya akun untuk masuk ke aplikasi.
@immutable
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.username,
    required this.level,
    this.nip,
    this.createdAt,
  });

  final int id;
  final String username;
  final UserLevel level;
  final String? nip;
  final String? createdAt;

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    final level = UserLevel.tryParse(json['level'] as String?);
    if (level == null) {
      throw FormatException('Level akun tidak dikenali: ${json['level']}');
    }

    return ManagedUser(
      id: (json['id_user'] as num).toInt(),
      username: json['username'] as String,
      level: level,
      nip: json['nip'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
