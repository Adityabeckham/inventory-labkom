import '../../../core/network/api_client.dart';
import '../domain/peminjam.dart';

class PeminjamRepository {
  const PeminjamRepository(this._api);

  final ApiClient _api;

  Future<List<Peminjam>> fetch({String? cari}) async {
    final data = await _api.get('/api/peminjam', query: {
      if (cari case final q? when q.isNotEmpty) 'cari': q,
    }) as List<dynamic>;

    return data
        .map((e) => Peminjam.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Peminjam> save({
    int? id,
    required String nama,
    String? nisNip,
    String? kelasJabatan,
    String? noHp,
  }) async {
    final body = {
      'nama_peminjam': nama,
      'nis_nip': nisNip ?? '',
      'kelas_jabatan': kelasJabatan ?? '',
      'no_hp': noHp ?? '',
    };

    final data = id == null
        ? await _api.post('/api/peminjam', body: body)
        : await _api.put('/api/peminjam/$id', body: body);

    return Peminjam.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/api/peminjam/$id');
}
