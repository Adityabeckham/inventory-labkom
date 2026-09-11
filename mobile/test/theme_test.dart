import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_labkom/core/theme/app_colors.dart';
import 'package:inventory_labkom/core/theme/app_dimens.dart';
import 'package:inventory_labkom/core/theme/app_theme.dart';
import 'package:inventory_labkom/core/theme/status_style.dart';

void main() {
  group('Tema mengikuti DESIGN.md', () {
    final theme = AppTheme.light();

    test('primary memakai Electric Blue #1622E5', () {
      expect(theme.colorScheme.primary, AppColors.primary);
    });

    test('FAB memakai Primary Electric Blue #1622E5', () {
      expect(theme.floatingActionButtonTheme.backgroundColor, AppColors.primary);
    });

    test('app bar melengkung 24px di sudut bawah', () {
      final shape = theme.appBarTheme.shape;
      expect(shape, isA<RoundedRectangleBorder>());
      expect(
        (shape! as RoundedRectangleBorder).borderRadius,
        const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
      );
    });

    test('tombol memenuhi target sentuh minimum 48dp', () {
      final size = theme.filledButtonTheme.style
          ?.minimumSize
          ?.resolve(<WidgetState>{});
      expect(size?.height, kMinTouchTarget);
    });

    test('kanvas memakai Slate Canvas, bukan putih polos', () {
      expect(theme.scaffoldBackgroundColor, AppColors.canvas);
    });
  });

  group('Status peminjaman', () {
    test('nilai enum cocok persis dengan ENUM database', () {
      // Database_Final_dan_Arsitektur.md §3.5 — urutan boleh beda, isi tidak.
      expect(
        StatusPeminjaman.values.map((s) => s.value).toSet(),
        {
          'menunggu_verifikasi',
          'dipinjam',
          'sebagian_kembali',
          'dikembalikan',
          'dibatalkan',
        },
      );
    });

    test('tryParse mengenali nilai dari API dan menolak yang asing', () {
      expect(StatusPeminjaman.tryParse('dipinjam'), StatusPeminjaman.dipinjam);
      expect(StatusPeminjaman.tryParse('ditolak'), isNull);
      expect(StatusPeminjaman.tryParse(null), isNull);
    });

    test('setiap status punya gaya badge sendiri', () {
      final latar = StatusPeminjaman.values
          .map((s) => StatusStyle.of(s).background)
          .toSet();
      // Lima status, lima warna berbeda — tidak ada yang tertukar.
      expect(latar.length, StatusPeminjaman.values.length);
    });

    test('menunggu verifikasi memakai gaya Gold', () {
      final gaya = StatusStyle.of(StatusPeminjaman.menungguVerifikasi);
      expect(gaya.background, AppColors.pendingBg);
      expect(gaya.foreground, AppColors.pendingFg);
    });

    test('dibatalkan memakai gaya Critical', () {
      expect(
        StatusStyle.of(StatusPeminjaman.dibatalkan).background,
        AppColors.dangerBg,
      );
    });
  });
}
