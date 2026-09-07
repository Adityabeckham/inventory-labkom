# Pemetaan Kebutuhan Fungsional ke Pengujian

Dokumen ini memetakan setiap kebutuhan fungsional (FR-01 – FR-13) pada PRD ke
pengujian yang membuktikannya. Metode utamanya **Black Box Testing** sesuai Bab
III skripsi: yang diperiksa perilaku sistem lewat antarmukanya, bukan isi
kodenya.

Tabel ini dibuat supaya klaim "sudah diuji" bisa ditelusuri, bukan dipercaya
begitu saja. Kolom terakhir sengaja mencatat apa yang **belum** tercakup.

## Berkas pengujian

| Berkas | Jenis | Jumlah | Cara menjalankan |
|---|---|---|---|
| `backend/tests/api.php` | Black Box, API sungguhan lewat HTTP | 307 | `php backend/tests/api.php` |
| `backend/tests/run.php` | Unit, komponen internal backend | 28 | `php backend/tests/run.php` |
| `mobile/test/screen_smoke_test.dart` | Render & interaksi layar | 83 | `flutter test` |
| `mobile/test/api_integration_test.dart` | Flutter ↔ backend hidup | 53 | `flutter test` |
| `mobile/test/auth_test.dart` | Unit, sesi dan token | 15 | `flutter test` |
| `mobile/test/aset_test.dart` | Unit, model & filter aset | 11 | `flutter test` |
| `mobile/test/theme_test.dart` | Unit, token desain | 10 | `flutter test` |
| **Total** | | **507** | |

Uji integrasi Flutter dan Black Box PHP **memerlukan backend hidup** di
`http://127.0.0.1:8080` dengan database terisi seed. Uji integrasi Flutter
melewati dirinya sendiri (skip) kalau backend mati; Black Box PHP akan gagal.

> Keduanya **mengubah data**: transaksi uji dibuat, disetujui, dan
> dikembalikan. Jalankan di database pengembangan, bukan database sekolah.

---

## Peta FR → pengujian

| FR | Nama | Black Box (`api.php`) | Pengujian Flutter | Catatan cakupan |
|---|---|---|---|---|
| FR-01 | Login | 15 — token sah/salah, akun nonaktif, klaim JWT, penolakan tanpa token | `auth_test.dart` (15): penyimpanan token, "Ingat saya", pemulihan sesi. Smoke: grup Login | Ganti password bukan bagian FR-01 di PRD dan memang belum ada |
| FR-02 | Kelola Barang | 15 — CRUD, validasi, tolak hapus barang berriwayat | Smoke: grup Aset Lab. `aset_test.dart` (11): model, filter kategori, pencarian | Unggah foto barang di luar scope (tidak ada di PRD) |
| FR-03 | Kelola Kategori | 7 — CRUD, tolak hapus kategori terpakai | Smoke: grup Kategori | — |
| FR-04 | Kelola Peminjam | 8 — CRUD, tolak hapus peminjam berriwayat | Smoke: grup Data Peminjam | — |
| FR-05 | Peminjaman Barang | 27 — multi-item, potong stok, kode berurut, tolak stok kurang, tolak item ganda | Smoke: grup Peminjaman Baru, Transaksi. Integrasi Sprint 3 | Uji balapan (dua permintaan bersamaan) tidak otomatis; penguncian baris diperiksa lewat pembacaan kode, dicatat di [deviasi D-07](deviasi-dari-spesifikasi.md) |
| FR-06 | Pengembalian Barang | 39 — per item, kondisi baik/rusak, denda, pulihkan stok, tolak pengembalian ganda, empat tab saringan | Smoke: grup Pengembalian. Integrasi Sprint 4 | Pengembalian sebagian jumlah (mis. 2 dari 3 unit) memang tidak ada — satu baris detail utuh atau belum, lihat [D-08](deviasi-dari-spesifikasi.md) |
| FR-07 | Verifikasi Peminjaman | 17 — approve/reject, alasan wajib saat tolak, pulihkan stok saat tolak, tolak verifikasi ganda, khusus Kepala Program | Smoke: grup Verifikasi. Integrasi Sprint 3 | — |
| FR-08 | Cetak Laporan | 99 — 5 jenis × 3 format: HTTP, magic bytes, Content-Type, nama lampiran, ukuran wajar, isi ZIP; isi laporan; filter periode; format tidak dikenal ditolak | Integrasi Sprint 5 (unduhan nyata + magic bytes). Smoke: grup Laporan | Isi PDF diperiksa manual dengan `pdftotext` (data, header, ringkasan, jejak cetak); yang otomatis baru isi XLSX/DOCX |
| FR-09 | Lihat Laporan | tercakup FR-08 — Kepala Program menerima 200 untuk semua laporan | Smoke: penandaan "Mode Lihat Saja" | Sama endpoint dengan FR-08; yang membedakan hanya penandaan UI |
| FR-10 | Dashboard & Navigasi | 38 — bentuk dan tipe tiap angka, kedua peran sama, identitas `total − tersedia = dipinjam + diajukan`, pergerakan angka menempuh alur ajukan → setujui → kembalikan | Smoke: grup Dashboard (9). Integrasi Sprint 6 (3) | Navigasi antar-tab diuji lewat matriks route di sisi Flutter, bukan Black Box — router ada di klien, tidak punya endpoint |
| FR-11 | Pengaturan Denda | 11 — baca, ubah, tarif tersimpan ikut ke pengembalian, batas nilai | Smoke: grup Pengaturan Denda. Integrasi Sprint 4 | Satu baris tarif berlaku global, lihat [D-08](deviasi-dari-spesifikasi.md) |
| FR-12 | Kelola User | 11 — CRUD, tolak hapus akun sendiri, tolak menurunkan Laboran terakhir | Smoke: grup Kelola User | — |
| FR-13 | Kelola Stok Barang | 14 — mutasi masuk/keluar, riwayat, tolak mutasi yang membuat stok negatif | Smoke: grup Aset Lab (lembar mutasi) | — |

### Pengujian yang melintasi banyak FR

| Bagian | Jumlah | Yang dibuktikan |
|---|---|---|
| Otorisasi (Tabel 3.1 Use Case) | 4 | Kepala Program ditolak di endpoint kelola; Laboran ditolak di endpoint verifikasi |
| Pengaman | 2 | Sistem tidak bisa dibuat terkunci: akun sendiri tidak bisa dihapus, Laboran terakhir tidak bisa diturunkan |
| Skala teks sistem | 12 | Tiap layar tetap utuh saat ukuran font Android dinaikkan ke 1,3 (dan 1,5 di layar pendek) |
| Unit backend (`run.php`) | 28 | JWT (termasuk penolakan `alg:none`, token kedaluwarsa, penerbit asing), pencocokan route, normalisasi path per mode deploy |

---

## Yang belum tercakup pengujian otomatis

Dicatat terbuka supaya tidak terbaca sebagai "semua sudah teruji".

1. **Uji balapan (concurrency).** Dua permintaan peminjaman atas barang yang
   sama pada saat bersamaan. Penguncian baris (`SELECT … FOR UPDATE`) sudah
   dipasang dan urutan kuncinya diseragamkan untuk menghindari deadlock, tapi
   pembuktiannya lewat pembacaan kode, bukan uji otomatis.
2. **Isi visual PDF.** Diperiksa manual dengan `pdftotext`. Yang otomatis baru
   struktur berkas dan isi XLSX/DOCX.
3. **Pengujian di perangkat sungguhan.** Uji layar berjalan di mesin uji Flutter
   dengan ukuran layar disimulasikan (360×740 dan 360×640), bukan di HP.
4. **Uji beban.** Tidak ada, dan tidak diminta PRD. Skala pemakaiannya satu lab
   satu sekolah.

---

## Menjalankan seluruh pengujian

```bash
# 1. Backend harus hidup
php -S 127.0.0.1:8080 -t backend/public

# 2. Di terminal lain
php backend/tests/run.php     # 28 unit
php backend/tests/api.php     # 307 Black Box
cd mobile && flutter test     # 172 uji Flutter
```

Untuk mengembalikan database ke keadaan bersih setelah pengujian:

```bash
mysql -u root < database/schema.sql && mysql -u root < database/seed.sql
```
