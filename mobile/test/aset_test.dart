import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_labkom/features/aset/domain/barang.dart';
import 'package:inventory_labkom/features/aset/domain/stok_mutasi.dart';
import 'package:inventory_labkom/features/kategori/data/kategori.dart';
import 'package:inventory_labkom/features/peminjam/domain/peminjam.dart';

void main() {
  group('Barang', () {
    Barang buat({int jumlah = 40, int stok = 40}) => Barang.fromJson({
          'id_barang': 1,
          'id_kategori': 1,
          'nama_kategori': 'Komputer',
          'kode_barang': 'A01',
          'nama_barang': 'Laptop Lenovo ThinkPad',
          'jumlah': jumlah,
          'stok': stok,
          'tanggal_input': '2026-01-15',
          'merk': 'Lenovo',
          'kondisi': 'Baik',
          'serial_number': 'LNV-TP-0001',
        });

    test('dibaca dari JSON backend', () {
      final b = buat();
      expect(b.kode, 'A01');
      expect(b.namaKategori, 'Komputer');
      expect(b.serialNumber, 'LNV-TP-0001');
    });

    test('sedangDipinjam adalah selisih jumlah dan stok', () {
      expect(buat(jumlah: 40, stok: 32).sedangDipinjam, 8);
      expect(buat(jumlah: 40, stok: 40).sedangDipinjam, 0);
    });

    test('stok nol berarti tidak tersedia', () {
      expect(buat(stok: 0).tersedia, isFalse);
      expect(buat(stok: 1).tersedia, isTrue);
    });

    test('field opsional boleh null', () {
      final b = Barang.fromJson({
        'id_barang': 2,
        'id_kategori': 1,
        'kode_barang': 'A03',
        'nama_barang': 'Keyboard',
        'jumlah': 5,
        'stok': 5,
        'merk': null,
        'kondisi': null,
        'serial_number': null,
      });
      expect(b.merk, isNull);
      expect(b.serialNumber, isNull);
      // nama_kategori tidak ikut saat backend belum join — jangan sampai crash.
      expect(b.namaKategori, '-');
    });
  });

  group('StokMutasi', () {
    test('nilai enum cocok dengan ENUM stok_mutasi.jenis', () {
      expect(JenisMutasi.values.map((j) => j.value).toSet(), {'masuk', 'keluar'});
    });

    test('jenis asing ditolak, bukan diam-diam jadi default', () {
      expect(
        () => StokMutasi.fromJson({
          'id_mutasi': 1,
          'id_barang': 1,
          'jenis': 'melayang',
          'jumlah': 1,
        }),
        throwsFormatException,
      );
    });

    test('dibaca dari JSON lengkap', () {
      final m = StokMutasi.fromJson({
        'id_mutasi': 3,
        'id_barang': 1,
        'kode_barang': 'A01',
        'nama_barang': 'Laptop',
        'jenis': 'keluar',
        'jumlah': 2,
        'keterangan': 'Rusak — dibuang',
        'tanggal_mutasi': '2026-09-07',
        'dicatat_oleh': 'laboran',
      });

      expect(m.jenis, JenisMutasi.keluar);
      expect(m.jumlah, 2);
      expect(m.dicatatOleh, 'laboran');
    });
  });

  group('Kategori', () {
    test('jumlah barang default 0 kalau backend tidak mengirimnya', () {
      final k = Kategori.fromJson({'id_kategori': 1, 'nama_kategori': 'Jaringan'});
      expect(k.jumlahBarang, 0);
    });

    test('jumlah barang terbaca kalau ada', () {
      final k = Kategori.fromJson({
        'id_kategori': 1,
        'nama_kategori': 'Komputer',
        'jumlah_barang': 12,
      });
      expect(k.jumlahBarang, 12);
    });
  });

  group('Peminjam', () {
    test('NIS/NIP dan kelas terbaca — field yang hilang dari BAB 3', () {
      final p = Peminjam.fromJson({
        'id_peminjam': 1,
        'nama_peminjam': 'Raka Maulana',
        'nis_nip': '190001',
        'kelas_jabatan': 'XII TKJ 1',
        'no_hp': '081234567890',
      });

      expect(p.nisNip, '190001');
      expect(p.kelasJabatan, 'XII TKJ 1');
    });

    test('peminjam tanpa NIS tetap sah — mis. tamu', () {
      final p = Peminjam.fromJson({
        'id_peminjam': 2,
        'nama_peminjam': 'Tamu',
        'nis_nip': null,
        'kelas_jabatan': null,
        'no_hp': null,
      });

      expect(p.nama, 'Tamu');
      expect(p.nisNip, isNull);
    });
  });
}
