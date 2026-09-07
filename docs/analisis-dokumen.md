# Analisis Dokumen Skripsi — Inventory Laboratorium Komputer (Mobile)

Sumber: `BAB 1 - 3 Mobile Inventory.docx`
Judul: Rancang Bangun System Inventory Laboratorium Komputer Berbasis Mobile Menggunakan Metode PIECES (Studi Kasus SMK Al-Madani Jampangkulon)
Penulis: Aria Rimba Fauna (5520125031029) — Universitas Faletehan
Tanggal analisis: 2026-09-07

---

## 1. Ringkasan sistem

| Aspek | Isi dokumen |
|---|---|
| Metode analisis | PIECES (Performance, Information, Economy, Control, Efficiency, Service) |
| Metode pengembangan | Prototype (evolusioner) |
| Frontend | Flutter (Dart) |
| Database | MySQL |
| Tools | XAMPP (server lokal), NetBeans (disebut di BAB 2, kemungkinan sisa template) |
| Bahasa backend | PHP disebut di BAB 2, tapi arsitektur API tidak dirinci |
| Aktor | Laboran (admin teknis) & Kepala Program TKJ / Kepala Lab (managerial) |
| Pemodelan | UML: use case, activity, sequence, collaboration, class diagram + ERD + flowchart |

## 2. Aktor dan hak akses

Dari Tabel 3.1 (Deskripsi Use Case) dan Gambar 3.5 (Use Case Diagram):

**Laboran**
- Login / Logout
- Kelola Barang (CRUD)
- Kelola Peminjam (CRUD)
- Kelola Peminjaman & Pengembalian
- Lihat Data Barang
- Cetak Laporan

**Kepala Program / Kepala Lab**
- Login / Logout
- Verifikasi pengajuan peminjaman
- Lihat Laporan
- Lihat Data Barang *(hanya ada di diagram, tidak di Tabel 3.1)*
- Lihat Data Peminjaman *(hanya ada di diagram, tidak di Tabel 3.1)*

## 3. Skema database

Gabungan Tabel 3.2–3.7 (teks) dan Gambar 3.18 (ERD). **ERD punya 7 tabel, teks hanya mendaftar 6.**

### tbl_user
| Field | Tipe | Ket |
|---|---|---|
| id_user | int(11) | PK |
| username | varchar(50) | |
| password | varchar(50) | |
| level | enum('admin','super_admin') | |

### tbl_barang
| Field | Tipe | Ket |
|---|---|---|
| id_barang | int(11) | PK |
| id_kategori | int(11) | FK → kategori |
| kode_barang | varchar(30) | |
| nama_barang | varchar(100) | |
| merk | varchar(100) | |
| jumlah | int(11) | |
| kondisi | varchar(50) | |
| stok | int(11) | |
| tanggal_input | date | |
| foto | varchar(255) | **hanya ada di ERD, tidak di Tabel 3.3** |

### kategori
| Field | Tipe | Ket |
|---|---|---|
| id_kategori | int(11) | PK |
| nama_kategori | varchar(100) | |

### peminjam
| Field | Tipe | Ket |
|---|---|---|
| id_peminjam | int(11) | PK |
| nama_peminjam | varchar(100) | |
| no_hp | varchar(20) | |

### peminjaman
| Field | Tipe | Ket |
|---|---|---|
| id_peminjaman | int(11) | PK |
| id_peminjam | int(11) | FK → peminjam |
| id_user | int(11) | FK → tbl_user |
| tanggal_pinjam | date | |
| tanggal_kembali | date | |
| status | enum('dipinjam','dikembalikan') | |

### detail_peminjaman *(hanya ada di ERD & class diagram)*
| Field | Tipe | Ket |
|---|---|---|
| id_detail | int(11) | PK |
| id_peminjaman | int(11) | FK → peminjaman |
| id_barang | int(11) | FK → tbl_barang |
| jumlah_pinjam | int(11) | |

### pengembalian
| Field | Tipe | Ket |
|---|---|---|
| id_pengembalian | int(11) | PK |
| id_peminjaman | int(11) | FK → peminjaman |
| tanggal_pengembalian | date | |
| kondisi | enum('Baik','Rusak') | |
| denda | decimal(10,2) | |

## 4. Rancangan layar (Gambar 3.19–3.25)

| Layar | Isi |
|---|---|
| **Login** | Header ungu "INVENTORY LABKOM", field Username & Password (toggle mata), checkbox "Ingat saya", link "Lupa Password?", tombol hitam "Masuk" |
| **Dashboard** | Header ungu + sapaan "Halo Laboran", search bar, grid 3×3 menu: Data Barang, Kategori, Kelola User, Pengembalian, Data Peminjam, Laporan, Peminjaman, Verifikasi, Pengaturan + tombol Logout |
| **Daftar Barang** | Search, filter chip (semua/Komputer/Jaringan/Elektronik), tombol "+ Tambah Barang", list card: nama, kode, stok, badge status hijau "Tersedia" |
| **Peminjaman** | Search, filter chip (Semua/Dipinjam/Dikembalikan/Dibatalkan), tombol "+ Tambah Peminjaman", list card: kode PMJ-2026-001, nama peminjam, tgl pinjam, jatuh tempo, badge status warna |
| **Pengembalian** | Search, filter chip (Semua/Belum Kembali/Sudah Kembali/Terlambat), list card mirip peminjaman dengan badge status |
| **Laporan** | Banner ungu "Laporan Inventaris", list menu: Laporan Data Barang, Laporan Peminjaman, Laporan Pengembalian, Laporan Stok Barang |
| **Kelola Peminjam** | Search + tombol "+ Tambah Peminjam", tabel: No, Nama Peminjam, NIS/NIP, Kelas/Jabatan, No. HP, Aksi (edit/hapus) |

**Warna dominan:** ungu/indigo (±`#5B4BFF`), aksen hitam untuk tombol utama, abu muda untuk field & card, badge hijau/oranye/merah muda untuk status.

## 5. Alur sistem (Gambar 3.2 — Flowchart)

```
MULAI → Form Login → Input username/password → valid?
  tidak → pesan gagal → kembali input
  ya   → Dashboard
Dashboard bercabang ke:
  1. Kelola Kategori  (tambah/ubah/hapus/lihat)
  2. Kelola Barang    (tambah/ubah/hapus/lihat)
  3. Kelola Stok      (lihat stok, update stok, mutasi masuk/keluar)
  4. Peminjaman       (pilih peminjam → pilih barang → input tgl pinjam → simpan)
  5. Pengembalian     (pilih peminjaman → input tgl kembali → update stok → simpan)
  6. Laporan          (barang, stok, peminjaman, pengembalian, denda)
→ Logout → konfirmasi → SELESAI
```

---

## 6. Temuan: ketidaksesuaian antar-artefak dokumen

Poin-poin ini **wajib diputuskan** sebelum coding, karena kode akan dibandingkan dengan BAB 3 saat sidang.

| # | Temuan | Dampak |
|---|---|---|
| **T1** | **Tidak ada state verifikasi di mana pun.** `peminjaman.status` hanya `dipinjam`/`dikembalikan`, padahal Verifikasi oleh Kepala Program adalah use case inti dan mockup menampilkan badge **"Dibatalkan"**. Tidak ada status *menunggu*, tidak ada `id_verifikator`, tidak ada `tanggal_verifikasi`. | Fitur verifikasi tidak bisa dibangun tanpa menambah enum + kolom |
| **T2** | `detail_peminjaman` ada di ERD & class diagram, **tidak ada di daftar Tabel 3.2–3.7** | Satu peminjaman multi-barang mustahil tanpa tabel ini |
| **T3** | `tbl_barang.foto varchar(255)` ada di ERD, tidak ada di Tabel 3.3 | Perlu keputusan: pakai foto atau tidak |
| **T4** | Mockup Kelola Peminjam menampilkan kolom **NIS/NIP** dan **Kelas/Jabatan**, tabel `peminjam` cuma punya nama + no_hp | Mockup tidak bisa dibuat apa adanya |
| **T5** | Nama role tidak konsisten: batasan masalah & use case menyebut **Laboran / Kepala Program**, tapi `user.level` = `enum('admin','super_admin')` | Perlu pemetaan eksplisit |
| **T6** | Hak akses Kepala Lab berbeda antara Gambar 3.5 (dapat Lihat Data Barang + Lihat Data Peminjaman) dan Tabel 3.1 (tidak) | Menentukan gating menu |
| **T7** | `barang.jumlah` vs `barang.stok` — dua kolom int tanpa definisi beda | Perlu ditetapkan: jumlah = total aset, stok = sisa tersedia |
| **T8** | Flowchart menyebut **"Mutasi Stok (Masuk/Keluar)"** dan **"Laporan Denda"**, tidak ada tabel pendukung | Butuh tabel mutasi atau fitur dicoret |
| **T9** | Dashboard punya menu **"Kelola User"** dan **"Pengaturan"**, tidak ada di use case manapun | Butuh keputusan scope |
| **T10** | `password varchar(50)` tidak muat hash bcrypt (60 karakter) | Bertentangan dengan argumen PIECES aspek *Control* soal keamanan |
| **T11** | BAB 2 menyebut **NetBeans (Java)** sebagai tools, padahal stack-nya Flutter + PHP | Kemungkinan sisa template, abaikan |
| **T12** | Flutter **tidak bisa** konek MySQL langsung — butuh lapisan REST API (PHP), dan dokumen tidak merinci lapisan ini | Menentukan struktur repo |

Setiap deviasi yang nanti diambil dicatat di `docs/deviasi-dari-bab3.md` supaya bisa dipertahankan saat sidang atau dipakai untuk merevisi BAB 3.

---

## 7. Status temuan setelah repo `inventory-labkom` di-clone (2026-09-07)

Repo `Adityabeckham/inventory-labkom` sudah berisi dokumen perencanaan FINAL yang **sudah menyelesaikan seluruh 12 temuan di atas**. Dokumen ini turun status jadi **catatan traceability** — sumber kebenaran ada di `docs_project/`.

| # | Temuan | Resolusi di dokumen repo |
|---|---|---|
| T1 | Verifikasi tanpa state | `peminjaman.status` jadi ENUM 5 nilai: `menunggu_verifikasi`, `dipinjam`, `sebagian_kembali`, `dikembalikan`, `dibatalkan` + kolom `alasan_dibatalkan`. Reject → stok otomatis dikembalikan. (DB v1.5 §3.5) |
| T2 | `detail_peminjaman` hilang dari BAB 3 | Resmi jadi tabel `peminjaman_detail` (pivot multi-barang). Klien konfirmasi multi-item = ya. (DB v1.5 §3.6) |
| T3 | `barang.foto` hanya di ERD | Tidak diadopsi; diganti `serial_number VARCHAR(50) NULL` hasil review Figma. (DB v1.5 §3.3) |
| T4 | NIS/NIP & Kelas/Jabatan tidak ada di tabel | Ditambahkan ke `peminjam`. (DB v1.5 §3.4, Putaran 3) |
| T5 | Nama role tidak konsisten | Dipetakan eksplisit: `admin` = Laboran, `super_admin` = Kepala Program. UI pakai nama Laboran/Kepala Program. (PRD §3) |
| T6 | Hak akses Kepala Lab ambigu | Diputuskan ikut **Tabel 3.1** (tekstual lebih otoritatif): Login, Verifikasi, Lihat Laporan saja. (UIUX v1.5 Putaran 6) |
| T7 | `jumlah` vs `stok` | `jumlah` = total unit dimiliki, `stok` = unit tersedia. (DB v1.5 §3.3) |
| T8 | Mutasi stok & Laporan Denda tanpa tabel | Tabel baru `stok_mutasi` (FR-13) + Laporan Denda jadi laporan ke-5. (DB v1.5 §3.9, Putaran 6) |
| T9 | Kelola User & Pengaturan tanpa use case | Kelola User jadi FR-12, Pengaturan Denda jadi FR-11. (PRD §7) |
| T10 | `password varchar(50)` | Jadi `VARCHAR(255)` + hash bcrypt + JWT. (DB v1.5 §3.1) |
| T11 | NetBeans di BAB 2 | Diabaikan — stack final Flutter + PHP + MySQL. |
| T12 | Flutter tidak bisa konek MySQL | Arsitektur resmi: Flutter → REST API PHP (JWT) → MySQL. (DB v1.5 §4) |

### Tambahan di luar 12 temuan
Dokumen repo juga menambahkan: `users.nip`, tabel `pengaturan_denda`, `peminjaman.kode_peminjaman` (`PMJ-2026-001`), status turunan layar Pengembalian (Belum/Sebagian/Sudah/Terlambat), navigasi hybrid Bottom Nav + grid, laporan 5 jenis × 3 format (PDF/Word/Excel), dan design system `DESIGN.md` (Navy `#384C9D` / Crimson `#D8232A` / Gold `#FCD116`) yang **sengaja berbeda dari mockup ungu di skripsi** — sudah dikonfirmasi klien.

### Catatan soal `Dokumentasi-Klien/`
Isi folder ini adalah artefak lama klien, **bukan basis kode yang dipakai**:
- `inventory_db.sql` — dump phpMyAdmin skema **lama** (7 tabel versi skripsi: `tbl_user`, `tbl_barang`, `detail_peminjaman`, dst). Beda dari skema final v1.5 (`users`, `barang`, `peminjaman_detail`, `pengaturan_denda`, `stok_mutasi`).
- `Inventory_api/*.php` — prototipe API awal (14 file, 360 baris). Masalah serius: query `mysqli` dirangkai langsung dari `$_POST` (SQL injection terbuka lebar), password dibandingkan plaintext, tanpa JWT/otorisasi, dan `login.php` query ke tabel `user` yang tidak ada di dump-nya sendiri (`tbl_user`).
- Keduanya berguna sebagai **rujukan niat klien**, tapi backend final harus ditulis ulang mengikuti `Database_Final_dan_Arsitektur.md` v1.5.
