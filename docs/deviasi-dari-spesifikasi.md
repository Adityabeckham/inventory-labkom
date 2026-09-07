# Deviasi dari Dokumen Perencanaan

Setiap tempat di mana kode **sengaja berbeda** dari `docs_project/` atau `design/DESIGN.md`, beserta alasannya.

Dokumen ini ada karena satu alasan praktis: saat sidang, penguji akan membandingkan kode dengan BAB 3. Tiap perbedaan di bawah perlu bisa dipertahankan — atau dipakai sebagai bahan revisi dokumen.

> Ini **bukan** daftar ketidaksesuaian di dalam dokumen skripsi itu sendiri. Yang itu ada di [analisis-dokumen.md §7](analisis-dokumen.md), dan semuanya sudah diselesaikan di `docs_project/`.

---

## D-01 · Warna primary: `#384C9D`, bukan `#1e3484`

| | |
|---|---|
| **Rujukan** | `design/DESIGN.md` frontmatter baris 19 |
| **Dokumen bilang** | `primary: '#1e3484'` |
| **Kode memakai** | `#384C9D` |
| **Berkas** | `mobile/lib/core/theme/app_colors.dart` |

`DESIGN.md` bertentangan dengan dirinya sendiri: frontmatter-nya menulis `#1e3484`, sedangkan bagian prosanya menulis "**Primary (`#384C9D` — Deep Navy Blue)**". Dua dokumen lain ikut mengutip `#384C9D`:

- `PRD` §10 Putaran 4 — "Navy `#384C9D`, Crimson `#D8232A`, Gold `#FCD116`"
- `UIUX_Wireframe_dan_Flow.md` §5.1 — "App bar Deep Navy #384C9D"

Tiga rujukan lawan satu. Nilai frontmatter tetap dipakai untuk peran turunan (`navyDark`).

**Bila ditanya:** frontmatter itu kemungkinan hasil generate palet Material 3, dan `#384c9d` memang ada di sana sebagai `primary-container`. Yang dilihat pengguna sebagai identitas aplikasi adalah nilai yang dikutip PRD dan wireframe.

---

## D-02 · Mutasi stok mengubah `jumlah`, bukan hanya `stok`

| | |
|---|---|
| **Rujukan** | `Database_Final_dan_Arsitektur.md` §3.9 baris 165 |
| **Dokumen bilang** | "Setiap mutasi otomatis update `barang.stok` (`+jumlah` untuk masuk, `-jumlah` untuk keluar)" |
| **Kode melakukan** | Menyesuaikan `stok` **dan** `jumlah` dengan delta yang sama |
| **Berkas** | `backend/controllers/StokMutasiController.php` |

`barang.jumlah` didefinisikan sebagai "Jumlah total unit dimiliki" dan `barang.stok` sebagai "Stok tersedia" (§3.3). Kalau mutasi hanya menyentuh `stok`, invariannya langsung rusak:

```
Barang A01: jumlah = 40, stok = 40
Mutasi masuk 10 unit (pengadaan baru)
Hasil menurut dokumen: jumlah = 40, stok = 50
```

Stok tersedia 50 unit dari total 40 unit yang dimiliki — mustahil. Contoh keterangan yang dokumen sendiri berikan ("Pengadaan APBD 2026", "Rusak — dibuang") jelas berarti unit fisik bertambah atau berkurang, bukan sekadar ketersediaannya berubah.

Backend memvalidasi `stok` maupun `jumlah` tidak boleh negatif, sehingga invarian `0 ≤ stok ≤ jumlah` selalu terjaga.

**Usulan revisi dokumen:** ubah §3.9 jadi "update `barang.stok` dan `barang.jumlah`".

---

## D-03 · `pengembalian.id_detail` diberi constraint UNIQUE

| | |
|---|---|
| **Rujukan** | `Database_Final_dan_Arsitektur.md` §3.7 |
| **Dokumen bilang** | Tidak menyebut UNIQUE |
| **Kode menambahkan** | `UNIQUE KEY uq_pengembalian_detail (id_detail)` |
| **Berkas** | `database/schema.sql` |

Satu baris `peminjaman_detail` mewakili satu barang dalam satu transaksi peminjaman, dan barang itu hanya bisa dikembalikan sekali. Tanpa UNIQUE, kesalahan input ganda akan menghasilkan dua baris pengembalian untuk barang yang sama — dendanya terhitung dua kali, dan status `sebagian_kembali`/`dikembalikan` jadi tidak bisa dihitung dengan benar.

Constraint ini menegakkan aturan yang memang sudah tersirat di §3.7.1.

---

## D-04 · NIS/NIP unik ditegakkan aplikasi, bukan database

| | |
|---|---|
| **Rujukan** | `Database_Final_dan_Arsitektur.md` §3.4 |
| **Dokumen bilang** | `nis_nip VARCHAR(30)`, tanpa UNIQUE |
| **Kode melakukan** | Menolak duplikat di `PeminjamController`, skema dibiarkan apa adanya |
| **Berkas** | `backend/controllers/PeminjamController.php` |

Dua siswa dengan NIS sama hampir pasti salah input, dan akan menyulitkan penelusuran saat mencari riwayat peminjaman seseorang.

Ditegakkan di aplikasi, bukan skema, karena kolomnya boleh kosong — peminjam tertentu (mis. tamu) mungkin tidak punya NIS/NIP, dan beberapa baris NULL akan bentrok dengan UNIQUE di sebagian konfigurasi MySQL. Skema tetap sesuai dokumen.

---

## D-05 · Panjang password minimal 8 karakter

| | |
|---|---|
| **Rujukan** | Tidak diatur dokumen manapun |
| **Kode melakukan** | Menolak password di bawah 8 karakter dan di atas 72 byte |
| **Berkas** | `backend/core/Validator.php` |

Dokumen tidak menyebut aturan panjang password sama sekali. Batas bawah 8 karakter dipilih karena analisis PIECES aspek **Control** justru menjadikan lemahnya keamanan sebagai masalah utama sistem lama.

Batas atas 72 byte bukan pilihan, melainkan sifat bcrypt: byte ke-73 dan seterusnya diabaikan diam-diam. Tanpa batas eksplisit, pengguna bisa mengira passwordnya panjang padahal yang diperiksa hanya 72 byte pertama.

---

## D-06 · Deploy sub-path didukung, dan CORS memakai daftar putih

| | |
|---|---|
| **Rujukan** | `Database_Final_dan_Arsitektur.md` §4 |
| **Dokumen bilang** | Tidak membahas base path maupun CORS |
| **Kode melakukan** | Membuang prefix pemasangan dari path; header CORS hanya untuk origin terdaftar |
| **Berkas** | `backend/core/Request.php`, `backend/public/index.php` |

Keduanya keputusan implementasi yang tidak bertentangan dengan dokumen, dicatat di sini supaya tidak terlihat sebagai fitur liar.

Prefix dibuang supaya `Alias /inventory` di XAMPP tetap jalan — tanpa itu, seluruh endpoint membalas 404 padahal konfigurasinya benar. Daftar putih CORS dipilih daripada `*` karena wildcard membuka API ke JavaScript dari situs mana pun; daftarnya kosong secara default, sebab klien Flutter native tidak butuh CORS sama sekali.

---

## D-07 · Nama field verifikasi ditetapkan `aksi`, dan Laboran tidak boleh memverifikasi

| | |
|---|---|
| **Rujukan** | `Database_Final_dan_Arsitektur.md` §4.1 |
| **Dokumen bilang** | `PATCH /api/peminjaman/{id}/verifikasi` — "body: `approve` atau `reject` + `alasan` jika reject" |
| **Kode melakukan** | Body `{"aksi": "approve"\|"reject", "alasan": "..."}`; endpoint dibatasi ke Kepala Program |
| **Berkas** | `backend/controllers/PeminjamanController.php`, `backend/routes/api.php` |

Dokumen menyebut nilainya tapi tidak menyebut nama fieldnya. Dipilih `aksi` supaya sejalan dengan bahasa yang dipakai seluruh kode ini, dan divalidasi sebagai enum agar salah tulis membalas 422, bukan diam-diam tidak melakukan apa pun.

Pembatasan ke Kepala Program adalah penegasan Tabel 3.1 Use Case, bukan penambahan: memisahkan yang mengajukan dari yang menyetujui adalah inti FR-07. Kalau Laboran bisa menyetujui pengajuannya sendiri, verifikasinya kehilangan fungsi. `GET /api/peminjaman` sengaja dibuka untuk kedua level, karena membaca daftar pengajuan adalah bagian dari use case Verifikasi.

**Catatan konkurensi.** Nomor urut kode diambil dengan `SELECT MAX(...) ... FOR UPDATE` pada rentang prefiks tahun, yang di REPEATABLE READ mengambil gap lock sehingga penyisipan bersamaan menunggu, bukan berlomba. `UNIQUE KEY uq_peminjaman_kode` tetap jadi jaring terakhir. Ini **belum diuji secara paralel**: server bawaan `php -S` melayani satu request pada satu waktu, jadi tabrakan tidak bisa direproduksi di lingkungan development.
