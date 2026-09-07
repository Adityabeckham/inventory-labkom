import '../../../core/network/api_client.dart';
import '../../auth/domain/app_user.dart';
import '../domain/managed_user.dart';

/// FR-12 — Kelola User. Seluruh endpoint di bawah ini dibatasi ke Laboran
/// di sisi backend; UI hanya menyembunyikannya sebagai kenyamanan.
class UserRepository {
  const UserRepository(this._api);

  final ApiClient _api;

  Future<List<ManagedUser>> fetchAll() async {
    final data = await _api.get('/api/users') as List<dynamic>;
    return data
        .map((e) => ManagedUser.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ManagedUser> create({
    required String username,
    required String password,
    required UserLevel level,
    String? nip,
  }) async {
    final data = await _api.post('/api/users', body: {
      'username': username,
      'password': password,
      'level': level.value,
      if (nip case final value? when value.isNotEmpty) 'nip': value,
    }) as Map<String, dynamic>;

    return ManagedUser.fromJson(data);
  }

  /// Field yang null tidak dikirim, jadi nilainya di server tidak berubah.
  /// Ini juga jalur reset password manual untuk "Lupa Password".
  Future<ManagedUser> update(
    int id, {
    String? username,
    String? password,
    UserLevel? level,
    String? nip,
  }) async {
    final data = await _api.put('/api/users/$id', body: {
      'username': ?username,
      if (password case final value? when value.isNotEmpty) 'password': value,
      'level': ?level?.value,
      'nip': ?nip,
    }) as Map<String, dynamic>;

    return ManagedUser.fromJson(data);
  }

  Future<void> delete(int id) => _api.delete('/api/users/$id');
}
