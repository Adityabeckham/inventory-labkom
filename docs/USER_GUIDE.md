# Panduan Pengguna — Inventory Labkom

Aplikasi pencatatan inventaris laboratorium komputer SMK Al-Madani
Jampangkulon. Panduan ini untuk **yang memakai aplikasi**, bukan yang
memasangnya — untuk pemasangan lihat [INSTALLATION.md](INSTALLATION.md).

---

## 1. Dua peran, dua tampilan berbeda

Aplikasi ini punya dua jenis akun, dan tampilannya memang berbeda. Kalau menu
yang Anda cari tidak ada, kemungkinan besar itu bukan kerusakan — melainkan
memang bukan bagian dari peran Anda.

| | **Laboran** | **Kepala Program** |
|---|---|---|
| Mengelola barang, kategori, peminjam, user | ✅ | ❌ |
| Membuat pengajuan peminjaman | ✅ | ❌ |
| Mencatat pengembalian | ✅ | ❌ |
| Mengatur tarif denda | ✅ | ❌ |
| **Memutuskan pengajuan (setujui/tolak)** | ❌ | ✅ |
| Membuka dan mengunduh laporan | ✅ | ✅ |

Pembagian ini disengaja: yang mengajukan dan yang menyetujui adalah orang yang
berbeda. Kalau Laboran bisa menyetujui pengajuannya sendiri, verifikasinya
kehilangan gunanya.

**Tab di bawah layar:**

- Laboran — Dashboard · Aset Lab · Transaksi · Laporan
- Kepala Program — Dashboard · Verifikasi · Laporan

---

## 2. Masuk ke aplikasi

1. Buka aplikasi **Inventory Labkom**.
2. Isi **Username** dan **Password** dari administrator sekolah.
3. Centang **Ingat saya** kalau HP-nya dipakai sendiri, bukan bergantian.
4. Tekan **Masuk**.

> **Ingat saya** membuat Anda tidak perlu login ulang setiap membuka aplikasi.
> Jangan dicentang di HP yang dipakai bergantian banyak orang.

**Kalau tidak bisa masuk:**

| Pesan | Artinya |
|---|---|
| "Username atau password salah" | Periksa huruf besar-kecilnya. Password membedakan huruf besar dan kecil. |
| "Akun Anda dinonaktifkan" | Hubungi administrator sekolah. |
| "Tidak dapat terhubung ke server" | HP tidak satu jaringan dengan server sekolah, atau servernya mati. |

Untuk keluar, tekan ikon keluar di pojok kanan atas Dashboard.

---

## 3. Dashboard — melihat keadaan sekilas

Dashboard menampilkan angka ringkasan yang diambil langsung dari data terbaru.
Angkanya diperbarui setiap kali Anda membuka tab ini; kalau Anda berdiam lama
di layar ini, tarik layar ke bawah untuk menyegarkannya.

| Kartu | Artinya |
|---|---|
| **Total Barang** | Seluruh unit yang dimiliki lab, dan berapa yang sedang ada di rak |
| **Sedang Dipinjam** | Unit pada peminjaman yang **sudah disetujui** dan belum kembali |
| **Perlu Verifikasi** | Pengajuan yang masih menunggu keputusan Kepala Program |
| **Terlambat** | Muncul hanya kalau ada transaksi lewat jatuh tempo yang belum lengkap |
| **Denda Tercatat** | Total seluruh denda yang pernah dicatat |

> **Kenapa "Total Barang" dikurangi "ada di rak" tidak sama dengan "Sedang
> Dipinjam"?**
>
> Karena stok berkurang **sejak pengajuan dibuat**, bukan sejak disetujui —
> supaya barang yang sama tidak diajukan dua kali oleh dua orang. Selisihnya
> persis sebesar unit yang masih menunggu verifikasi, dan itu disebutkan pada
> kartu **Perlu Verifikasi**. Jadi angka-angka ini tidak bertentangan; ketiganya
> memang menjawab pertanyaan yang berbeda.

Kartu yang punya tanda panah bisa disentuh untuk langsung membuka layarnya.

### Akses cepat (khusus Laboran)

Di bawah sapaan ada empat pintasan yang tidak punya tab sendiri:
**Kategori**, **Kelola User**, **Data Peminjam**, dan **Pengaturan Denda**.

---

## 4. Aset Lab — barang dan stoknya (Laboran)

Tab **Aset Lab** (atau diklik dari kartu **Total Barang** di Dashboard) memuat tabel data barang beserta stoknya secara terstruktur.

- **Buka dari Dashboard** — Sentuh kartu **Total Barang** di Dashboard untuk langsung berpindah ke tabel barang dengan filter ter-reset ke `Semua`.
- **Filter Kategori 1-Klik** — Sentuh tombol filter chip di atas tabel (`Semua`, `Komputer`, `Jaringan`, `Elektronik`, `Aksesori & Tools`). Begitu diklik, data langsung menyaring secara instan (*real-time*).
- **Mencari barang** — Ketik di kotak pencarian: nama barang, kode, merk, serial number, atau spesifikasi ringkas.
- **Melihat Detail Spesifikasi (Pop-up Sheet)** — Sentuh baris barang apa saja pada tabel untuk memunculkan modal pop-up detail spesifikasi (Merk, Tipe, RAM/SSD/Resolusi/Port, Serial Number, Stok & Kondisi).

### Menambah barang baru

1. Tekan tombol **Tambah Barang**.
2. Isi **Kode Barang**, **Nama Barang**, **Kategori**, **Spesifikasi / Detail Ringkas** (*fleksibel untuk laptop maupun Switch/Proyektor/Kabel*), dan **Jumlah unit**.
   **Merk** dan **Serial Number** boleh dikosongkan jika tidak ada.
3. Tekan **Simpan**.

Untuk mengubah atau menghapus barang yang sudah ada, buka baris barangnya pada tabel untuk menampilkan pop-up detail, lalu tekan **Edit Barang** atau **Hapus Barang**.

### Mengubah jumlah stok (mutasi)

Gunakan **Catat Mutasi** kalau ada barang **masuk** (pembelian baru, hibah) atau
**keluar** (rusak berat, dihapus dari inventaris) — bukan untuk peminjaman.
Peminjaman sudah mengurangi stok dengan sendirinya.

1. Di tab **Aset Lab**, tekan **Catat Mutasi**.
2. Pilih barangnya, pilih arah mutasi (masuk atau keluar), isi **Jumlah** dan
   **Keterangan**.
3. Tekan **Catat Mutasi**.

Setiap mutasi tercatat dengan keterangan dan tanggalnya, dan bisa dilihat lagi
di riwayat barang tersebut.

> Barang yang sudah punya riwayat mutasi atau riwayat peminjaman **tidak bisa
> dihapus**. Ini disengaja — menghapusnya akan membuat laporan lama jadi
> menunjuk barang yang tidak ada.

---

## 5. Meminjamkan barang (Laboran)

### Langkah 1 — Buat pengajuan

1. Buka tab **Transaksi**, pastikan berada di bagian **Peminjaman**, lalu tekan
   **Peminjaman Baru**.
2. Pilih **Peminjam** dari daftar. Kalau belum terdaftar, tambahkan dulu lewat
   Dashboard → **Data Peminjam**.
3. Isi **Tanggal pinjam** dan **Jatuh tempo**.
4. Tambahkan barang satu per satu lewat **Tambah Barang**: pilih **Barang**,
   isi **Jumlah**, lalu simpan ke keranjang. Ulangi untuk barang berikutnya.
   Mau mengubah jumlahnya, sentuh barangnya lagi (**Ubah Jumlah**); mau
   membatalkan, tekan **Keluarkan dari keranjang**.
5. Tekan **Ajukan Peminjaman**.

> **Stok langsung berkurang saat diajukan**, sebelum disetujui. Ini mencegah
> barang yang sama diajukan dua kali. Kalau pengajuannya ditolak nanti,
> stoknya dikembalikan otomatis.

Sistem akan memberi kode transaksi otomatis, misalnya `PMJ-2026-014`.

### Langkah 2 — Tunggu keputusan Kepala Program

Statusnya jadi **Menunggu Verifikasi**. Barangnya **belum boleh diserahkan**
sampai disetujui.

### Langkah 3 — Setelah disetujui

Statusnya berubah jadi **Dipinjam**. Barang boleh diserahkan ke peminjam.

Kalau ditolak, statusnya jadi **Dibatalkan**, alasannya bisa dibaca di rincian
transaksi, dan stoknya sudah kembali sendiri.

### Melihat dan mencari transaksi

Tab **Transaksi** punya dua bagian yang dipilih lewat tombol geser di atas:
**Peminjaman** dan **Pengembalian**. Kotak pencarian menerima kode transaksi,
nama peminjam, atau NIS.

Arti setiap status:

| Status | Artinya |
|---|---|
| **Menunggu Verifikasi** | Sudah diajukan, belum diputuskan Kepala Program |
| **Dipinjam** | Disetujui, barang di tangan peminjam |
| **Sebagian Kembali** | Sebagian barangnya sudah kembali, sebagian belum |
| **Dikembalikan** | Semua barangnya sudah kembali |
| **Dibatalkan** | Ditolak Kepala Program; stok sudah dipulihkan |

---

## 6. Memutuskan pengajuan (Kepala Program)

1. Buka tab **Verifikasi**. Isinya hanya pengajuan yang menunggu keputusan.
2. Sentuh kartunya untuk membaca rinciannya: siapa peminjamnya, barang apa
   saja, berapa unit, dan jatuh temponya kapan.
3. Tekan **Setujui** atau **Tolak**.
   - **Setujui** → status jadi **Dipinjam**.
   - **Tolak** → wajib mengisi **alasan**, lalu status jadi **Dibatalkan** dan
     stoknya dipulihkan otomatis.

Satu pengajuan hanya bisa diputuskan sekali. Kalau sudah diputuskan orang lain
lebih dulu, aplikasi akan memberi tahu dan menyegarkan daftarnya.

---

## 7. Menerima pengembalian (Laboran)

Pengembalian dicatat **per barang**, bukan per transaksi — peminjam boleh
mengembalikan sebagian dulu.

1. Buka tab **Transaksi** → bagian **Pengembalian**.
2. Gunakan chip saringan bila perlu: **Semua**, **Belum Kembali**,
   **Sebagian Kembali**, **Sudah Kembali**, **Terlambat**.
   Saringan ini bisa beririsan — transaksi yang telat dan baru sebagian kembali
   akan muncul di kedua-duanya. Badge yang ditampilkan memilih yang paling
   mendesak, dan **Terlambat** selalu menang.
3. Sentuh kartu transaksinya untuk melihat status tiap barang.
4. Sentuh barang yang dikembalikan, lalu:
   - Isi **Tanggal pengembalian** (bawaannya hari ini).
   - Pilih **Kondisi barang**: **Baik** atau **Rusak**.
   - Aplikasi menampilkan pratinjau denda: **Tepat waktu, tidak ada denda**
     atau **Terlambat N hari** beserta hitungannya.
5. Tekan **Kembalikan Barang**, lalu **Konfirmasi Pengembalian**.

Setelah dicatat, stoknya bertambah kembali dan status transaksinya menyesuaikan
sendiri (**Sebagian Kembali** atau **Dikembalikan**).

**Beberapa hal yang perlu diketahui:**

- Satu barang dikembalikan **utuh atau belum sama sekali** — tidak bisa 2 dari
  3 unit. Kalau perlu terpisah, ajukan sebagai baris terpisah sejak awal.
- Barang berkondisi **Rusak** tetap menambah stok kembali. Untuk mengeluarkannya
  dari inventaris, catat mutasi **keluar** di Aset Lab dengan keterangan.
- **Denda memakai tarif saat pengembalian dicatat.** Kalau tarif diubah nanti,
  denda yang sudah tercatat tidak ikut berubah — dan memang begitu seharusnya.

---

## 8. Pengaturan denda (Laboran)

Dashboard → **Pengaturan Denda**.

Isi **Tarif denda keterlambatan** (rupiah per hari), lalu tekan
**Simpan Tarif**. Layarnya menampilkan contoh perhitungan supaya angkanya
langsung terlihat efeknya. Rumusnya:

```
denda = jumlah hari terlambat × tarif per hari
```

Dendanya **tidak dikali jumlah unit**. Satu barang telat 3 hari dengan tarif
Rp 5.000 dikenai Rp 15.000, berapa pun jumlah unit di baris itu.

Tarif Rp 0 berarti keterlambatan tidak dikenai denda sama sekali. Batas
atasnya Rp 1.000.000 per hari.

> Perubahan tarif hanya berlaku untuk pengembalian yang dicatat **setelahnya**.

---

## 9. Laporan (kedua peran)

Tab **Laporan** menyediakan lima jenis laporan, masing-masing dalam tiga format:
**PDF**, **Word**, dan **Excel**.

| Laporan | Isinya |
|---|---|
| **Barang** | Daftar seluruh barang beserta kategori dan jumlahnya |
| **Peminjaman** | Transaksi peminjaman beserta statusnya |
| **Pengembalian** | Catatan pengembalian, kondisi barang, dan dendanya |
| **Stok** | Keadaan stok saat ini |
| **Denda** | Rekap denda yang tercatat |

**Cara mengunduh:**

1. Atur **Periode** bila perlu — isi **Dari** dan/atau **Sampai**.
   Dibiarkan kosong berarti seluruh periode. Tekan **Bersihkan** untuk
   mengosongkannya lagi.
2. Tekan tombol format yang diinginkan pada kartu laporannya.
3. Berkasnya tersimpan dan langsung terbuka di aplikasi pembaca yang ada di HP.

> Laporan **Stok** tidak terpengaruh filter periode — isinya keadaan sekarang,
> bukan rentang waktu.

Kepala Program melihat penanda **Mode Lihat Saja** di layar ini. Isinya sama
persis; penanda itu hanya menegaskan bahwa dari sini tidak ada yang bisa diubah.

Selama satu unduhan berjalan, tombol format lain dimatikan sementara supaya
tidak ada dua unduhan yang saling menimpa.

---

## 10. Data peminjam dan pengguna (Laboran)

### Data Peminjam

Dashboard → **Data Peminjam**. Berisi siswa atau guru yang boleh meminjam:
nama, NIS/NIP, kelas/jabatan, dan nomor HP.

Peminjam yang sudah punya riwayat transaksi tidak bisa dihapus.

### Kelola User

Dashboard → **Kelola User**. Untuk mengelola akun yang bisa masuk ke aplikasi
beserta perannya.

Dua pengaman yang tidak bisa dilanggar, supaya sistem tidak terkunci dari
semua orang:

- Anda **tidak bisa menghapus akun Anda sendiri**.
- Anda **tidak bisa menurunkan peran Laboran yang terakhir**.

---

## 11. Kalau ada masalah

| Gejala | Yang bisa dicoba |
|---|---|
| "Tidak dapat terhubung ke server" | Pastikan HP satu jaringan Wi-Fi dengan server sekolah. Kalau alamat servernya berubah, aplikasinya perlu dibangun ulang. |
| "Sesi Anda berakhir. Silakan login kembali." | Login lagi. Sesi memang dibatasi masa berlakunya. |
| Angka Dashboard terasa tidak cocok | Tarik layar ke bawah untuk menyegarkan. Kalau masih terasa janggal, baca lagi penjelasan di bagian 3 — pengajuan yang belum diverifikasi ikut memotong stok. |
| Barang tidak bisa dihapus | Barangnya punya riwayat. Ini disengaja; kalau sudah tidak dipakai, catat mutasi **keluar** sampai stoknya nol. |
| Tombol Setujui/Tolak tidak ada | Anda masuk sebagai Laboran. Keputusan pengajuan hanya bisa dilakukan Kepala Program. |
| Tulisan terpotong saat ukuran font HP dibesarkan | Layarnya sudah diuji sampai ukuran font 1,3×. Kalau masih terpotong di ukuran yang lebih besar, laporkan beserta ukuran fontnya. |

Untuk masalah yang tidak ada di tabel ini, catat: **apa yang Anda lakukan**,
**apa yang Anda harapkan**, dan **apa yang terjadi** — beserta kode transaksinya
kalau ada. Itu yang paling membantu saat pemeriksaan.
