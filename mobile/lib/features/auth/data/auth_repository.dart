import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/app_user.dart';

class AuthRepository {
  const AuthRepository(this._api, this._tokenStorage);

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  /// FR-01 — login. Token disimpan hanya kalau [rememberMe] dicentang, supaya
  /// perangkat bersama tidak menyimpan sesi tanpa disadari penggunanya.
  Future<AppUser> login({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    final data = await _api.post('/api/auth/login', body: {
      'username': username,
      'password': password,
      'remember_me': rememberMe,
    }) as Map<String, dynamic>;

    final token = data['token'] as String;

    if (rememberMe) {
      await _tokenStorage.write(token);
    } else {
      // Tetap dipakai selama aplikasi hidup, tapi tidak ditulis ke disk.
      await _tokenStorage.clear();
      _api.sessionToken = token;
    }

    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Memulihkan sesi dari token tersimpan saat aplikasi dibuka.
  /// Mengembalikan null kalau tidak ada token atau tokennya sudah tidak sah.
  Future<AppUser?> restore() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) return null;

    try {
      final data = await _api.get('/api/auth/me') as Map<String, dynamic>;
      return AppUser.fromJson(data);
    } catch (_) {
      // Token kedaluwarsa, akun dihapus, atau backend tidak terjangkau.
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _api.sessionToken = null;
  }
}
