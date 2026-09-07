import '../../../core/network/api_client.dart';
import '../../../core/theme/status_style.dart';
import '../domain/pengembalian.dart';

/// FR-06 Pengembalian dan FR-11 Pengaturan Denda.
class PengembalianRepository {
  const PengembalianRepository(this._api);

  final ApiClient _api;

  /// [tab] null berarti chip "Semua".
  ///
  /// Keempat tab adalah SARINGAN yang bisa beririsan, bukan pembagian yang
  /// saling lepas — penyaringannya dilakukan server (§3.7.1).
  Future<List<TransaksiPengembalian>> fetch({
    StatusPengembalian? tab,
    String? cari,
  }) async {
    final data = await _api.get('/api/pengembalian', query: {
      'tab': ?tab?.value,
      if (cari != null && cari.isNotEmpty) 'cari': cari,
    }) as List<dynamic>;

    return data
        .map((e) => TransaksiPengembalian.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Mencatat satu baris `peminjaman_detail` sebagai kembali.
  ///
  /// Tidak ada parameter jumlah: satu baris detail kembali utuh atau belum
  /// sama sekali. Denda dihitung dan disimpan backend.
  Future<InfoPengembalian> catat({
    required int idDetail,
    required KondisiBarang kondisi,
    String? tanggal,
  }) async {
    final data = await _api.post('/api/pengembalian', body: {
      'id_detail': idDetail,
      'kondisi': kondisi.value,
      'tanggal_pengembalian': ?tanggal,
    }) as Map<String, dynamic>;

    return InfoPengembalian.fromJson(data);
  }
}

/// FR-11 — tarif denda. GET boleh kedua level, PUT hanya Laboran.
class PengaturanDendaRepository {
  const PengaturanDendaRepository(this._api);

  final ApiClient _api;

  Future<TarifDenda> ambil() async {
    final data = await _api.get('/api/pengaturan-denda') as Map<String, dynamic>;
    return TarifDenda.fromJson(data);
  }

  Future<TarifDenda> simpan(double tarifPerHari) async {
    final data = await _api.put('/api/pengaturan-denda', body: {
      'tarif_per_hari': tarifPerHari,
    }) as Map<String, dynamic>;

    return TarifDenda.fromJson(data);
  }
}
