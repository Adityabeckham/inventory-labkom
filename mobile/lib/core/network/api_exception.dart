/// Kegagalan panggilan API yang sudah diterjemahkan jadi pesan siap tampil.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Token tidak ada, kedaluwarsa, atau ditolak — pengguna harus login ulang.
  bool get isUnauthorized => statusCode == 401;

  /// Sudah login, tapi levelnya tidak diizinkan mengakses endpoint ini.
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}
