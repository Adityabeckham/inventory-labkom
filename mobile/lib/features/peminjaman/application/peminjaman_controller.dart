import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/status_style.dart';
import '../../aset/application/barang_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../data/peminjaman_repository.dart';
import '../domain/peminjaman.dart';

final peminjamanRepositoryProvider = Provider<PeminjamanRepository>((ref) {
  return PeminjamanRepository(ref.watch(apiClientProvider));
});

/// Filter aktif di tab Peminjaman.
@immutable
class PeminjamanFilter {
  const PeminjamanFilter({this.status, this.cari = ''});

  /// Null berarti chip "Semua".
  final StatusPeminjaman? status;
  final String cari;

  PeminjamanFilter copyWith({
    StatusPeminjaman? status,
    bool clearStatus = false,
    String? cari,
  }) {
    return PeminjamanFilter(
      status: clearStatus ? null : (status ?? this.status),
      cari: cari ?? this.cari,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PeminjamanFilter && other.status == status && other.cari == cari;

  @override
  int get hashCode => Object.hash(status, cari);
}

class PeminjamanFilterNotifier extends Notifier<PeminjamanFilter> {
  @override
  PeminjamanFilter build() => const PeminjamanFilter();

  /// null berarti chip "Semua".
  void pilihStatus(StatusPeminjaman? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
  }

  void cari(String kataKunci) => state = state.copyWith(cari: kataKunci);
}

final peminjamanFilterProvider =
    NotifierProvider<PeminjamanFilterNotifier, PeminjamanFilter>(
  PeminjamanFilterNotifier.new,
);

/// Daftar peminjaman mengikuti filter. Penyaringan dilakukan di server.
final peminjamanListProvider = FutureProvider<List<Peminjaman>>((ref) {
  final filter = ref.watch(peminjamanFilterProvider);
  return ref.watch(peminjamanRepositoryProvider).fetch(
        status: filter.status,
        cari: filter.cari,
      );
});

/// Pengajuan yang menunggu verifikasi — sumber data layar Verifikasi.
///
/// Sengaja provider terpisah dari [peminjamanListProvider]: layar Verifikasi
/// milik Kepala Program dan filternya tidak boleh ikut berubah saat Laboran
/// menggeser chip di layar Transaksi.
final pengajuanMenungguProvider = FutureProvider<List<Peminjaman>>((ref) {
  return ref
      .watch(peminjamanRepositoryProvider)
      .fetch(status: StatusPeminjaman.menungguVerifikasi);
});

/// Detail satu transaksi, termasuk rincian barangnya.
final peminjamanDetailProvider =
    FutureProvider.family<Peminjaman, int>((ref, id) {
  return ref.watch(peminjamanRepositoryProvider).show(id);
});

/// Aksi tulis pada peminjaman.
///
/// Setiap aksi menyegarkan daftar barang juga: mengajukan peminjaman
/// mengurangi stok dan penolakan memulihkannya, jadi angka stok di layar
/// Aset Lab akan basi kalau hanya daftar transaksinya yang di-invalidate.
class PeminjamanActions {
  const PeminjamanActions(this._ref);

  final Ref _ref;

  PeminjamanRepository get _repo => _ref.read(peminjamanRepositoryProvider);

  void _invalidateAll() {
    _ref.invalidate(peminjamanListProvider);
    _ref.invalidate(pengajuanMenungguProvider);
    _ref.invalidate(peminjamanDetailProvider);
    _ref.invalidate(barangListProvider);
    _ref.invalidate(mutasiListProvider);
  }

  Future<Peminjaman> ajukan({
    required int idPeminjam,
    required String tanggalPinjam,
    required String tanggalKembali,
    required List<ItemKeranjang> items,
  }) async {
    final hasil = await _repo.create(
      idPeminjam: idPeminjam,
      tanggalPinjam: tanggalPinjam,
      tanggalKembali: tanggalKembali,
      items: items,
    );
    _invalidateAll();
    return hasil;
  }

  Future<Peminjaman> setujui(int id) async {
    final hasil = await _repo.verifikasi(id, setujui: true);
    _invalidateAll();
    return hasil;
  }

  Future<Peminjaman> tolak(int id, String alasan) async {
    final hasil = await _repo.verifikasi(id, setujui: false, alasan: alasan);
    _invalidateAll();
    return hasil;
  }
}

final peminjamanActionsProvider =
    Provider<PeminjamanActions>(PeminjamanActions.new);
