import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/barang_repository.dart';
import '../domain/barang.dart';
import '../domain/stok_mutasi.dart';

final barangRepositoryProvider = Provider<BarangRepository>((ref) {
  return BarangRepository(ref.watch(apiClientProvider));
});

/// Filter aktif di layar Daftar Barang.
@immutable
class BarangFilter {
  const BarangFilter({this.idKategori, this.cari = ''});

  /// Null berarti chip "Semua".
  final int? idKategori;
  final String cari;

  BarangFilter copyWith({int? idKategori, bool clearKategori = false, String? cari}) {
    return BarangFilter(
      idKategori: clearKategori ? null : (idKategori ?? this.idKategori),
      cari: cari ?? this.cari,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BarangFilter && other.idKategori == idKategori && other.cari == cari;

  @override
  int get hashCode => Object.hash(idKategori, cari);
}

class BarangFilterNotifier extends Notifier<BarangFilter> {
  @override
  BarangFilter build() => const BarangFilter();

  /// null berarti chip "Semua".
  void pilihKategori(int? idKategori) {
    state = state.copyWith(
      idKategori: idKategori,
      clearKategori: idKategori == null,
    );
  }

  void cari(String kataKunci) => state = state.copyWith(cari: kataKunci);
}

final barangFilterProvider =
    NotifierProvider<BarangFilterNotifier, BarangFilter>(BarangFilterNotifier.new);

/// Daftar barang mengikuti filter. Penyaringan dilakukan di server supaya
/// hasilnya tetap benar walau datanya nanti jauh lebih banyak dari satu layar.
final barangListProvider = FutureProvider<List<Barang>>((ref) {
  final filter = ref.watch(barangFilterProvider);
  return ref.watch(barangRepositoryProvider).fetch(
        idKategori: filter.idKategori,
        cari: filter.cari,
      );
});

final mutasiListProvider = FutureProvider<List<StokMutasi>>((ref) {
  return ref.watch(barangRepositoryProvider).fetchMutasi();
});

/// Aksi tulis pada barang dan mutasi.
///
/// Setelah menulis, kedua daftar di-invalidate sekaligus: mutasi mengubah
/// stok barang, jadi menyegarkan salah satunya saja akan menampilkan angka
/// yang sudah basi di layar sebelah.
class AsetActions {
  const AsetActions(this._ref);

  final Ref _ref;

  BarangRepository get _repo => _ref.read(barangRepositoryProvider);

  void _invalidateAll() {
    _ref.invalidate(barangListProvider);
    _ref.invalidate(mutasiListProvider);
  }

  Future<void> simpanBarang(Map<String, dynamic> body, {int? id}) async {
    await _repo.save(body, id: id);
    _invalidateAll();
  }

  Future<void> hapusBarang(int id) async {
    await _repo.delete(id);
    _invalidateAll();
  }

  Future<void> catatMutasi({
    required int idBarang,
    required JenisMutasi jenis,
    required int jumlah,
    String? keterangan,
  }) async {
    await _repo.catatMutasi(
      idBarang: idBarang,
      jenis: jenis,
      jumlah: jumlah,
      keterangan: keterangan,
    );
    _invalidateAll();
  }
}

final asetActionsProvider = Provider<AsetActions>(AsetActions.new);
