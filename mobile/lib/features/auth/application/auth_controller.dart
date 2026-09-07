import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

// ── Penyedia dependensi ──────────────────────────────────────────────
//
// apiClientProvider sengaja TIDAK menyentuh authControllerProvider. Kalau
// keduanya saling merujuk, Riverpod tidak bisa menyimpulkan tipenya dan
// providernya jadi melingkar. Penanganan 401 dipasang dari sisi AuthController.

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage.standard();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(tokenStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

// ── State ────────────────────────────────────────────────────────────

@immutable
class AuthState {
  const AuthState({
    this.user,
    this.isRestoring = true,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// Null berarti belum login.
  final AppUser? user;

  /// Sedang memeriksa token tersimpan saat aplikasi dibuka. Selama true,
  /// router menahan navigasi supaya layar Login tidak berkedip sesaat bagi
  /// pengguna yang sebenarnya masih punya sesi sah.
  final bool isRestoring;

  final bool isSubmitting;
  final String? errorMessage;

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    bool? isRestoring,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user,
      isRestoring: isRestoring ?? this.isRestoring,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── Controller ───────────────────────────────────────────────────────

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Token ditolak backend di tengah pemakaian (kedaluwarsa, atau akunnya
    // dihapus lewat Kelola User) — sesi dibersihkan supaya router memulangkan
    // pengguna ke layar Login, bukan meninggalkan layar kosong tanpa penjelasan.
    ref.read(apiClientProvider).onUnauthorized = () {
      if (state.isLoggedIn) {
        forceLogout('Sesi Anda berakhir. Silakan login kembali.');
      }
    };

    // build() harus sinkron, jadi pemulihan sesi dijalankan setelahnya.
    Future.microtask(_restore);

    return const AuthState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> _restore() async {
    final user = await _repository.restore();
    state = AuthState(user: user, isRestoring: false);
  }

  Future<bool> login({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final user = await _repository.login(
        username: username,
        password: password,
        rememberMe: rememberMe,
      );
      state = AuthState(user: user, isRestoring: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Terjadi kesalahan tak terduga: $e',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(isRestoring: false);
  }

  /// Logout yang dipicu sistem, bukan pengguna. Alasannya dibawa ke layar
  /// Login supaya pengguna tahu kenapa tiba-tiba dikeluarkan.
  void forceLogout(String reason) {
    unawaited(_repository.logout());
    state = AuthState(isRestoring: false, errorMessage: reason);
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Akun yang sedang login. Melempar kalau dibaca dari layar yang seharusnya
/// hanya bisa dicapai setelah login — kegagalan seperti itu lebih baik terlihat
/// jelas saat development daripada tersamar jadi UI kosong.
final currentUserProvider = Provider<AppUser>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) {
    throw StateError('currentUserProvider dibaca saat belum ada sesi login.');
  }
  return user;
});
