import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/kategori.dart';
import '../data/kategori_repository.dart';

final kategoriRepositoryProvider = Provider<KategoriRepository>((ref) {
  return KategoriRepository(ref.watch(apiClientProvider));
});

final kategoriListProvider = FutureProvider<List<Kategori>>((ref) {
  return ref.watch(kategoriRepositoryProvider).fetchAll();
});

class KategoriActions {
  const KategoriActions(this._ref);

  final Ref _ref;

  KategoriRepository get _repo => _ref.read(kategoriRepositoryProvider);

  Future<void> tambah(String nama) async {
    await _repo.create(nama);
    _ref.invalidate(kategoriListProvider);
  }

  Future<void> ubah(int id, String nama) async {
    await _repo.update(id, nama);
    _ref.invalidate(kategoriListProvider);
  }

  Future<void> hapus(int id) async {
    await _repo.delete(id);
    _ref.invalidate(kategoriListProvider);
  }
}

final kategoriActionsProvider = Provider<KategoriActions>(KategoriActions.new);
