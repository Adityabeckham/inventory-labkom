import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';
import '../data/user_repository.dart';
import '../domain/managed_user.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

/// Daftar akun. AsyncNotifier menangani loading dan error sekaligus, jadi UI
/// cukup memetakan tiga keadaannya tanpa flag manual.
class UsersController extends AsyncNotifier<List<ManagedUser>> {
  @override
  Future<List<ManagedUser>> build() {
    return ref.watch(userRepositoryProvider).fetchAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).fetchAll(),
    );
  }

  Future<void> create({
    required String username,
    required String password,
    required UserLevel level,
    String? nip,
  }) async {
    await ref.read(userRepositoryProvider).create(
          username: username,
          password: password,
          level: level,
          nip: nip,
        );
    await refresh();
  }

  /// Dinamai updateUser, bukan update — AsyncNotifier sudah punya method
  /// `update` bawaan dengan tanda tangan berbeda.
  Future<void> updateUser(
    int id, {
    String? username,
    String? password,
    UserLevel? level,
    String? nip,
  }) async {
    await ref.read(userRepositoryProvider).update(
          id,
          username: username,
          password: password,
          level: level,
          nip: nip,
        );
    await refresh();
  }

  Future<void> delete(int id) async {
    await ref.read(userRepositoryProvider).delete(id);
    await refresh();
  }
}

final usersControllerProvider =
    AsyncNotifierProvider<UsersController, List<ManagedUser>>(
  UsersController.new,
);
