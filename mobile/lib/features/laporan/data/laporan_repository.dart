import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../domain/laporan.dart';

/// FR-08 Cetak Laporan / FR-09 Lihat Laporan.
///
/// Unduhan HARUS lewat [ApiClient.unduh], bukan dibuka di browser luar:
/// endpoint-nya berlisensi dan browser luar tidak mengirim header
/// Authorization, jadi hasilnya 401.
class LaporanRepository {
  const LaporanRepository(this._api);

  final ApiClient _api;

  Future<Uint8List> unduh({
    required JenisLaporan jenis,
    required FormatLaporan format,
    String? dari,
    String? sampai,
  }) {
    return _api.unduh('/api/laporan/${jenis.slug}', query: {
      'format': format.value,
      'dari': ?dari,
      'sampai': ?sampai,
    });
  }

  String namaBerkas(JenisLaporan jenis, FormatLaporan format, DateTime kini) {
    final tanggal = '${kini.year.toString().padLeft(4, '0')}-'
        '${kini.month.toString().padLeft(2, '0')}-'
        '${kini.day.toString().padLeft(2, '0')}';

    return 'laporan-${jenis.slug}-$tanggal.${format.value}';
  }
}
