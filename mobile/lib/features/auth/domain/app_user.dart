import 'package:flutter/foundation.dart';

/// Level akun sesuai ENUM `users.level` di database.
///
/// Perhatikan: `super_admin` terdengar lebih tinggi dari `admin`, tapi secara
/// hak akses justru LEBIH TERBATAS. Sesuai Tabel 3.1 Use Case, Kepala Program
/// hanya boleh Login, Verifikasi, dan Lihat Laporan — sedangkan Laboran
/// mengelola seluruh data. Jangan pernah bandingkan keduanya sebagai tingkatan.
enum UserLevel {
  laboran('admin', 'Laboran'),
  kepalaProgram('super_admin', 'Kepala Program');

  const UserLevel(this.value, this.label);

  final String value;
  final String label;

  static UserLevel? tryParse(String? raw) {
    if (raw == null) return null;
    for (final level in values) {
      if (level.value == raw) return level;
    }
    return null;
  }
}

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.level,
    this.nip,
  });

  final int id;
  final String username;
  final UserLevel level;
  final String? nip;

  bool get isLaboran => level == UserLevel.laboran;
  bool get isKepalaProgram => level == UserLevel.kepalaProgram;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final level = UserLevel.tryParse(json['level'] as String?);
    if (level == null) {
      throw FormatException('Level akun tidak dikenali: ${json['level']}');
    }

    return AppUser(
      id: (json['id_user'] as num).toInt(),
      username: json['username'] as String,
      level: level,
      nip: json['nip'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.username == username &&
      other.level == level &&
      other.nip == nip;

  @override
  int get hashCode => Object.hash(id, username, level, nip);
}
