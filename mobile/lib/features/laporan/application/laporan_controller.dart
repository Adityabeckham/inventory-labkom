import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/laporan_repository.dart';
import '../data/penyimpan_berkas.dart';
import '../domain/laporan.dart';

final laporanRepositoryProvider = Provider<LaporanRepository>((ref) {
  return LaporanRepository(ref.watch(apiClientProvider));
});

/// Penyimpan berkas disuntikkan lewat provider, bukan dipanggil langsung.
///
/// Implementasi bawaannya menyentuh plugin platform (path_provider,
/// open_filex) yang tidak tersedia di `flutter test`. Dengan begini pengujian
/// bisa menggantinya tanpa menyentuh plugin sungguhan, dan jalur pemanggilnya
/// tetap yang asli.
final penyimpanBerkasProvider = Provider<PenyimpanBerkas>((ref) {
  return simpanDanBuka;
});

/// Rentang tanggal yang dipilih untuk satu jenis laporan.
@immutable
class PeriodeLaporan {
  const PeriodeLaporan({this.dari, this.sampai});

  final DateTime? dari;
  final DateTime? sampai;

  bool get kosong => dari == null && sampai == null;

  static String? iso(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  String get label {
    final a = iso(dari);
    final b = iso(sampai);

    return switch ((a, b)) {
      (final x?, final y?) => '$x s.d. $y',
      (final x?, null) => 'sejak $x',
      (null, final y?) => 'sampai $y',
      _ => 'Seluruh periode',
    };
  }

  PeriodeLaporan copyWith({
    DateTime? dari,
    DateTime? sampai,
    bool hapusDari = false,
    bool hapusSampai = false,
  }) {
    return PeriodeLaporan(
      dari: hapusDari ? null : (dari ?? this.dari),
      sampai: hapusSampai ? null : (sampai ?? this.sampai),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PeriodeLaporan && other.dari == dari && other.sampai == sampai;

  @override
  int get hashCode => Object.hash(dari, sampai);
}

class PeriodeNotifier extends Notifier<PeriodeLaporan> {
  @override
  PeriodeLaporan build() => const PeriodeLaporan();

  void aturDari(DateTime? d) => state = d == null
      ? state.copyWith(hapusDari: true)
      : state.copyWith(dari: d);

  void aturSampai(DateTime? d) => state = d == null
      ? state.copyWith(hapusSampai: true)
      : state.copyWith(sampai: d);

  void bersihkan() => state = const PeriodeLaporan();
}

final periodeLaporanProvider =
    NotifierProvider<PeriodeNotifier, PeriodeLaporan>(PeriodeNotifier.new);

/// Jenis laporan yang sedang diunduh, supaya kartunya bisa menampilkan
/// indikator dan tombolnya dimatikan sementara.
final laporanSedangDiunduhProvider =
    NotifierProvider<LaporanSedangDiunduh, JenisLaporan?>(
  LaporanSedangDiunduh.new,
);

class LaporanSedangDiunduh extends Notifier<JenisLaporan?> {
  @override
  JenisLaporan? build() => null;

  void mulai(JenisLaporan jenis) => state = jenis;
  void selesai() => state = null;
}

class LaporanActions {
  const LaporanActions(this._ref);

  final Ref _ref;

  /// Mengunduh lalu menyerahkan berkasnya, dan mengembalikan kalimat hasil.
  ///
  /// Periode diabaikan untuk jenis laporan yang tidak berperiode — mengirim
  /// filter tanggal ke laporan Stok akan ditolak backend, dan menyaringnya di
  /// sini lebih baik daripada memunculkan error yang membingungkan.
  Future<String> unduh(JenisLaporan jenis, FormatLaporan format) async {
    final penanda = _ref.read(laporanSedangDiunduhProvider.notifier);
    penanda.mulai(jenis);

    try {
      final periode = jenis.berperiode
          ? _ref.read(periodeLaporanProvider)
          : const PeriodeLaporan();

      final repo = _ref.read(laporanRepositoryProvider);
      final bytes = await repo.unduh(
        jenis: jenis,
        format: format,
        dari: PeriodeLaporan.iso(periode.dari),
        sampai: PeriodeLaporan.iso(periode.sampai),
      );

      final nama = repo.namaBerkas(jenis, format, DateTime.now());

      return await _ref.read(penyimpanBerkasProvider)(bytes, nama, format.mime);
    } finally {
      penanda.selesai();
    }
  }
}

final laporanActionsProvider = Provider<LaporanActions>(LaporanActions.new);
