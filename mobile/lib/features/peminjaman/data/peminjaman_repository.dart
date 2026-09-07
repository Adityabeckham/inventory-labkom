import '../../../core/network/api_client.dart';
import '../../../core/theme/status_style.dart';
import '../domain/peminjaman.dart';

/// FR-05 Peminjaman dan FR-07 Verifikasi.
///
/// GET dibuka untuk kedua level di backend; POST hanya Laboran dan
/// verifikasi hanya Kepala Program. UI cuma menyembunyikan tombolnya —
/// penolakannya tetap datang dari server.
class PeminjamanRepository {
  const PeminjamanRepository(this._api);

  final ApiClient _api;

  /// [status] null berarti semua status.
  Future<List<Peminjaman>> fetch({StatusPeminjaman? status, String? cari}) async {
    final data = await _api.get('/api/peminjaman', query: {
      'status': ?status?.value,
      if (cari != null && cari.isNotEmpty) 'cari': cari,
    }) as List<dynamic>;

    return data
        .map((e) => Peminjaman.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Peminjaman> show(int id) async {
    final data = await _api.get('/api/peminjaman/$id') as Map<String, dynamic>;
    return Peminjaman.fromJson(data);
  }

  Future<Peminjaman> create({
    required int idPeminjam,
    required String tanggalPinjam,
    required String tanggalKembali,
    required List<ItemKeranjang> items,
  }) async {
    final data = await _api.post('/api/peminjaman', body: {
      'id_peminjam': idPeminjam,
      'tanggal_pinjam': tanggalPinjam,
      'tanggal_kembali': tanggalKembali,
      'items': items.map((e) => e.toJson()).toList(growable: false),
    }) as Map<String, dynamic>;

    return Peminjaman.fromJson(data);
  }

  /// FR-07 — approve tanpa alasan, reject wajib menyertakannya.
  Future<Peminjaman> verifikasi(
    int id, {
    required bool setujui,
    String? alasan,
  }) async {
    final data = await _api.patch('/api/peminjaman/$id/verifikasi', body: {
      'aksi': setujui ? 'approve' : 'reject',
      if (!setujui) 'alasan': alasan,
    }) as Map<String, dynamic>;

    return Peminjaman.fromJson(data);
  }
}
