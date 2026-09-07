import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/peminjam_repository.dart';
import '../domain/peminjam.dart';

final peminjamRepositoryProvider = Provider<PeminjamRepository>((ref) {
  return PeminjamRepository(ref.watch(apiClientProvider));
});

class PeminjamCariNotifier extends Notifier<String> {
  @override
  String build() => '';

  void ubah(String kataKunci) => state = kataKunci;
}

final peminjamCariProvider =
    NotifierProvider<PeminjamCariNotifier, String>(PeminjamCariNotifier.new);

final peminjamListProvider = FutureProvider<List<Peminjam>>((ref) {
  return ref.watch(peminjamRepositoryProvider).fetch(
        cari: ref.watch(peminjamCariProvider),
      );
});

class PeminjamActions {
  const PeminjamActions(this._ref);

  final Ref _ref;

  PeminjamRepository get _repo => _ref.read(peminjamRepositoryProvider);

  Future<void> simpan({
    int? id,
    required String nama,
    String? nisNip,
    String? kelasJabatan,
    String? noHp,
  }) async {
    await _repo.save(
      id: id,
      nama: nama,
      nisNip: nisNip,
      kelasJabatan: kelasJabatan,
      noHp: noHp,
    );
    _ref.invalidate(peminjamListProvider);
  }

  Future<void> hapus(int id) async {
    await _repo.delete(id);
    _ref.invalidate(peminjamListProvider);
  }
}

final peminjamActionsProvider = Provider<PeminjamActions>(PeminjamActions.new);
