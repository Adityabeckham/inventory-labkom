import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/status_style.dart';
import '../../aset/application/barang_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../../peminjaman/application/peminjaman_controller.dart';
import '../data/pengembalian_repository.dart';
import '../domain/pengembalian.dart';

final pengembalianRepositoryProvider = Provider<PengembalianRepository>((ref) {
  return PengembalianRepository(ref.watch(apiClientProvider));
});

final pengaturanDendaRepositoryProvider =
    Provider<PengaturanDendaRepository>((ref) {
  return PengaturanDendaRepository(ref.watch(apiClientProvider));
});

/// Filter aktif di tab Pengembalian.
@immutable
class PengembalianFilter {
  const PengembalianFilter({this.tab, this.cari = ''});

  /// Null berarti chip "Semua".
  final StatusPengembalian? tab;
  final String cari;

  PengembalianFilter copyWith({
    StatusPengembalian? tab,
    bool clearTab = false,
    String? cari,
  }) {
    return PengembalianFilter(
      tab: clearTab ? null : (tab ?? this.tab),
      cari: cari ?? this.cari,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PengembalianFilter && other.tab == tab && other.cari == cari;

  @override
  int get hashCode => Object.hash(tab, cari);
}

class PengembalianFilterNotifier extends Notifier<PengembalianFilter> {
  @override
  PengembalianFilter build() => const PengembalianFilter();

  void pilihTab(StatusPengembalian? tab) {
    state = state.copyWith(tab: tab, clearTab: tab == null);
  }

  void cari(String kataKunci) => state = state.copyWith(cari: kataKunci);
}

final pengembalianFilterProvider =
    NotifierProvider<PengembalianFilterNotifier, PengembalianFilter>(
  PengembalianFilterNotifier.new,
);

final pengembalianListProvider =
    FutureProvider<List<TransaksiPengembalian>>((ref) {
  final filter = ref.watch(pengembalianFilterProvider);
  return ref.watch(pengembalianRepositoryProvider).fetch(
        tab: filter.tab,
        cari: filter.cari,
      );
});

/// Tarif yang berlaku sekarang — dipakai pratinjau denda di form.
///
/// Pratinjau memakai tarif BERJALAN, sedangkan denda yang sudah tercatat
/// memakai tarif saat kejadian. Keduanya bisa berbeda kalau tarifnya pernah
/// diubah, dan itu memang perilaku yang benar.
final tarifDendaProvider = FutureProvider<TarifDenda>((ref) {
  return ref.watch(pengaturanDendaRepositoryProvider).ambil();
});

/// Aksi tulis pengembalian dan pengaturan denda.
class PengembalianActions {
  const PengembalianActions(this._ref);

  final Ref _ref;

  /// Pengembalian mengubah stok barang DAN status header peminjaman, jadi
  /// daftar peminjaman maupun aset ikut disegarkan — bukan hanya daftar
  /// pengembalian.
  void _invalidateAll() {
    _ref.invalidate(pengembalianListProvider);
    _ref.invalidate(peminjamanListProvider);
    _ref.invalidate(peminjamanDetailProvider);
    _ref.invalidate(barangListProvider);
  }

  Future<InfoPengembalian> catat({
    required int idDetail,
    required KondisiBarang kondisi,
    String? tanggal,
  }) async {
    final hasil = await _ref.read(pengembalianRepositoryProvider).catat(
          idDetail: idDetail,
          kondisi: kondisi,
          tanggal: tanggal,
        );
    _invalidateAll();
    return hasil;
  }

  Future<TarifDenda> simpanTarif(double tarifPerHari) async {
    final hasil =
        await _ref.read(pengaturanDendaRepositoryProvider).simpan(tarifPerHari);
    _ref.invalidate(tarifDendaProvider);
    return hasil;
  }
}

final pengembalianActionsProvider =
    Provider<PengembalianActions>(PengembalianActions.new);
