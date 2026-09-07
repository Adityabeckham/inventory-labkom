import '../../../core/network/api_client.dart';
import '../domain/barang.dart';
import '../domain/stok_mutasi.dart';

class BarangRepository {
  const BarangRepository(this._api);

  final ApiClient _api;

  Future<List<Barang>> fetch({int? idKategori, String? cari}) async {
    final data = await _api.get('/api/barang', query: {
      'id_kategori': ?idKategori,
      if (cari != null && cari.isNotEmpty) 'cari': cari,
    }) as List<dynamic>;

    return data
        .map((e) => Barang.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Barang> save(Map<String, dynamic> body, {int? id}) async {
    final data = id == null
        ? await _api.post('/api/barang', body: body)
        : await _api.put('/api/barang/$id', body: body);

    return Barang.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/api/barang/$id');

  // ── FR-13 Mutasi Stok ──────────────────────────────────────────────

  Future<List<StokMutasi>> fetchMutasi({int? idBarang}) async {
    final data = await _api.get('/api/stok-mutasi', query: {
      'id_barang': ?idBarang,
    }) as List<dynamic>;

    return data
        .map((e) => StokMutasi.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<StokMutasi> catatMutasi({
    required int idBarang,
    required JenisMutasi jenis,
    required int jumlah,
    String? keterangan,
    String? tanggal,
  }) async {
    final data = await _api.post('/api/stok-mutasi', body: {
      'id_barang': idBarang,
      'jenis': jenis.value,
      'jumlah': jumlah,
      'keterangan': ?keterangan,
      'tanggal_mutasi': ?tanggal,
    }) as Map<String, dynamic>;

    return StokMutasi.fromJson(data);
  }
}
