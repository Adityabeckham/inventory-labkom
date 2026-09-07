import '../../../core/network/api_client.dart';
import 'kategori.dart';

class KategoriRepository {
  const KategoriRepository(this._api);

  final ApiClient _api;

  Future<List<Kategori>> fetchAll() async {
    final data = await _api.get('/api/kategori') as List<dynamic>;
    return data
        .map((e) => Kategori.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Kategori> create(String nama) async {
    final data = await _api.post('/api/kategori', body: {'nama_kategori': nama});
    return Kategori.fromJson(data as Map<String, dynamic>);
  }

  Future<Kategori> update(int id, String nama) async {
    final data = await _api.put('/api/kategori/$id', body: {'nama_kategori': nama});
    return Kategori.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/api/kategori/$id');
}
