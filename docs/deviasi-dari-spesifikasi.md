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

---

## D-08 · Tiga keputusan pada Pengembalian dan Pengaturan Denda

| | |
|---|---|
| **Rujukan** | `Database_Final_dan_Arsitektur.md` §3.7, §3.7.1, §3.8 |
| **Berkas** | `backend/controllers/PengembalianController.php`, `PengaturanDendaController.php` |

**Barang rusak tetap dipulihkan ke stok.** Dokumen tidak menyebut apa yang terjadi pada unit berkondisi `rusak`. Menahannya di luar stok terdengar masuk akal, tapi akibatnya `jumlah - stok` tinggal 1 selamanya dan layar Aset Lab membacanya sebagai "1 dipinjam atau diajukan" untuk barang yang justru tergeletak rusak di rak — persis kekeliruan tampilan yang dihindari saat getter `tidakDiRak` dinamai ulang. Penghapusan kepemilikan punya jalurnya sendiri: Laboran mencatat mutasi keluar (FR-13), satu-satunya operasi yang memang menurunkan `jumlah` dan `stok` sekaligus.

**Denda tidak dikalikan jumlah unit.** §3.7 menulis rumusnya harfiah: `jumlah_hari_telat × pengaturan_denda.tarif_per_hari`. Frasa "per barang" di §3.8 bukan rumus kedua, melainkan penegasan cakupannya — satu baris `pengembalian` per `id_detail`. Satu baris detail berisi 3 unit yang telat 3 hari kena `3 × tarif`, bukan `3 × 3 × tarif`. Ditulis eksplisit karena bentuknya mengundang orang untuk "memperbaikinya" kemudian.

**Pengaturan denda memakai satu baris, `id_pengaturan` terkecil.** Dokumen tidak menyebut apa yang terjadi kalau tabelnya punya lebih dari satu baris. GET membaca baris terkecil; PUT memperbarui baris itu, atau menyisipkan kalau tabelnya kosong. Tanpa penyisipan itu, satu database yang di-import tanpa `seed.sql` akan membuat seluruh alur pengembalian gagal hanya karena baris konfigurasi hilang.

**Catatan tambahan, bukan deviasi.** Tarif dibaca saat pengembalian dicatat lalu ikut disimpan di baris `pengembalian`. Mengubah tarif tidak pernah mengubah denda yang sudah tercatat — angka di laporan tetap seperti saat kejadian. Konsekuensinya, pratinjau denda di layar (memakai tarif berjalan) bisa berbeda dari denda yang tersimpan bulan lalu.

Satu baris `peminjaman_detail` juga hanya bisa dikembalikan UTUH: tabel `pengembalian` tidak punya kolom jumlah dan `id_detail`-nya UNIQUE (lihat D-03). "2 dari 3 unit kembali" memang tidak punya tempat penyimpanan — ini batasan skema, dan karenanya form pengembalian menampilkan jumlahnya sebagai teks tetap, bukan field yang bisa diubah.

---

## D-09 · Aplikasi Android mengizinkan lalu lintas HTTP polos

Dokumen tidak menyebut TLS sama sekali, dan `Database_Final_dan_Arsitektur.md` §4.1 menuliskan seluruh contoh endpoint sebagai `http://`. Server sekolah adalah satu komputer di jaringan lab, diakses lewat alamat IP, dan tidak punya sertifikat.

Sejak Android 9 (API 28) lalu lintas cleartext **ditolak secara bawaan**, jadi aplikasinya membawa `android/app/src/main/res/xml/network_security_config.xml` dengan `cleartextTrafficPermitted="true"`. Tanpa itu, setiap permintaan gagal di HP modern.

Izinnya berlaku untuk seluruh aplikasi, bukan dibatasi per host. Alamat server ditentukan sekolah saat build (`--dart-define=API_BASE_URL`) dan tidak diketahui saat kode ditulis, sedangkan elemen `<domain>` pada konfigurasi keamanan jaringan tidak menerima rentang subnet.

**Konsekuensi yang harus disadari:** lalu lintas antara HP dan server bisa dibaca siapa pun yang menyadap jaringan lab, termasuk token login. Untuk satu jaringan lab tertutup ini masih sepadan dengan kerumitan memasang TLS di komputer sekolah. Yang **tidak** boleh dilakukan adalah mengekspos backend-nya ke internet dalam keadaan ini. Kalau nanti dipasang HTTPS, ubah berkas itu menjadi `cleartextTrafficPermitted="false"`.

**Catatan terkait, bukan deviasi.** `android.permission.INTERNET` harus dideklarasikan di `src/main/AndroidManifest.xml`. Flutter hanya menaruhnya di manifest `src/debug/`, sehingga `flutter run` selalu berhasil sementara build rilis menghasilkan APK yang tidak bisa berjaringan sama sekali — kegagalan yang tidak terlihat oleh satu pun pengujian di proyek ini, karena tidak ada yang melewati manifest Android. Cara memeriksanya ada di INSTALLATION.md §6 (`aapt dump badging`).
