import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan token JWT.
///
/// Dibuat sebagai antarmuka supaya pengujian bisa memakai implementasi di
/// memori — Keystore Android tidak tersedia di lingkungan test.
abstract interface class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Implementasi produksi: token disimpan terenkripsi lewat Android Keystore,
/// bukan sebagai teks biasa. Ini yang membuat "Ingat saya" bisa bertahan
/// setelah aplikasi ditutup tanpa meninggalkan token yang bisa dibaca.
class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'auth_token';

  /// Opsi bawaan flutter_secure_storage 11 sudah memakai AES-GCM dengan kunci
  /// dibungkus RSA di Android Keystore — tidak perlu dikonfigurasi lagi.
  factory SecureTokenStorage.standard() =>
      const SecureTokenStorage(FlutterSecureStorage());

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      // Keystore bisa gagal dibaca setelah restore backup atau ganti
      // perangkat. Perlakukan seperti belum pernah login, jangan crash.
      return null;
    }
  }

  @override
  Future<void> write(String token) async {
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {
      // Gagal menyimpan berarti sesi tidak bertahan setelah app ditutup —
      // mengganggu, tapi tidak boleh menggagalkan login yang sudah berhasil.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Diabaikan: state di memori tetap dibersihkan oleh pemanggil.
    }
  }
}

/// Token hanya bertahan selama proses berjalan. Dipakai pengujian, dan cocok
/// juga untuk platform yang tidak punya penyimpanan aman.
class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
