# Product Requirements Document (PRD)
## Sistem Inventory Laboratorium Komputer Berbasis Mobile
### Studi Kasus: SMK Al-Madani Jampangkulon — Nama Aplikasi: **"Inventory Labkom"**

| | |
|---|---|
| **Versi Dokumen** | 1.6 |
| **Status** | FINAL — siap jadi acuan Sprint Planning |
| **Terkait Skripsi** | Rancang Bangun System Inventory Laboratorium Komputer Berbasis Mobile Menggunakan Metode PIECES (Aria Rimba Fauna — Universitas Faletehan) |
| **Metode Pengembangan** | Prototype |
| **Metode Analisis** | PIECES (Performance, Information, Economy, Control, Efficiency, Service) |

---

## 1. Latar Belakang & Masalah

SMK Al-Madani saat ini mengelola inventaris laboratorium komputer menggunakan Microsoft Excel. Berdasarkan analisis PIECES pada dokumen klien, masalah yang teridentifikasi:

| Aspek | Masalah |
|---|---|
| **Performance** | Pengolahan data manual, update stok belum real-time, pembuatan laporan lambat |
| **Information** | Data tidak terintegrasi (tersebar di banyak file Excel), rawan human error, stok kurang akurat |
| **Economy** | Waktu kerja tidak efisien, biaya operasional laporan manual tinggi |
| **Control** | Keamanan data rendah (tanpa login/autentikasi), risiko kehilangan data tinggi, tidak ada backup |
| **Efficiency** | Input data berulang, tidak ada otomatisasi |
| **Service** | Pengguna kesulitan mengakses data inventori secara cepat |

**Solusi**: Aplikasi mobile (Android) "Inventory Labkom" dengan autentikasi, manajemen barang terpusat, alur peminjaman–pengembalian–verifikasi, dan pelaporan otomatis.

---

## 2. Tujuan Produk

1. Menyediakan sistem pencatatan inventaris barang lab yang terpusat, akurat, dan real-time.
2. Menyediakan alur peminjaman dan pengembalian barang yang terdokumentasi dan bisa diverifikasi.
3. Menyediakan mekanisme keamanan akses berbasis peran (role-based access).
4. Menghasilkan laporan inventori yang bisa dicetak/diekspor kapan saja.

---

## 3. Aktor & Peran Pengguna

| Aktor | Level Akses | Hak Akses |
|---|---|---|
| **Laboran** (admin teknis) | `admin` | Login, kelola akun user, kelola data barang (CRUD), kelola kategori, kelola data peminjam, catat peminjaman, catat pengembalian, cetak laporan, atur tarif denda |
| **Kepala Program / Kepala Lab** | `super_admin` (level manajerial) | Login, verifikasi pengajuan peminjaman, lihat laporan (read-only, untuk pengawasan) |

> **Dikonfirmasi klien**: penamaan role di UI mengikuti dokumen skripsi — **Laboran** (level `admin`) dan **Kepala Program** (level `super_admin`).

> **Catatan penting**: ada 2 entitas "orang" berbeda yang jangan tertukar — **User** (akun login Laboran/Kepala Program, dikelola lewat fitur **Kelola User**) vs **Peminjam** (siswa/guru/staf yang meminjam barang, dikelola lewat fitur **Data Peminjam**, punya NIS/NIP & Kelas/Jabatan). Ditemukan dari mockup UI asli skripsi.

---

## 4. Ruang Lingkup (Scope)

### 4.1 In-Scope (Fitur Utama)
1. **Autentikasi** — Login berbasis username & password, opsi "Ingat saya", link "Lupa Password".
2. **Kelola User** — Laboran mengelola akun login (Laboran & Kepala Program).
3. **Kelola Barang** — Tambah, ubah, hapus, lihat data barang inventaris + kategori.
4. **Kelola Stok Barang** — Catat mutasi stok masuk/keluar (di luar transaksi peminjaman) dengan log riwayat.
5. **Kelola Peminjam** — CRUD data peminjam (nama, NIS/NIP, kelas/jabatan, no. HP).
6. **Peminjaman Barang** — Catat transaksi peminjaman multi-item (barang, peminjam, tanggal pinjam).
7. **Pengembalian Barang** — Catat pengembalian per-item (tanggal kembali, kondisi barang, denda otomatis jika terlambat).
8. **Verifikasi** — Kepala Program menyetujui/membatalkan pengajuan peminjaman.
9. **Laporan** — 5 jenis (Data Barang, Peminjaman, Pengembalian, Stok Barang, Denda), ekspor PDF/Word/Excel (Laboran); lihat laporan read-only (Kepala Program).
10. **Dashboard** — Navigasi hybrid akses cepat ke semua fitur, sesuai role.

### 4.2 Out-of-Scope (Fase 1)
- Notifikasi push / reminder otomatis jatuh tempo pengembalian — dikonfirmasi klien: cukup badge di dashboard, mengikuti scope asli skripsi.
- Reset password via email/OTP otomatis — direkomendasikan reset manual oleh Laboran lewat Kelola User (perlu dikonfirmasi ulang saat sprint planning bila klien mau opsi email).
- Multi-cabang / multi-sekolah.
- Barcode/QR scanning untuk barang (bisa jadi fase 2 — disarankan).
- Integrasi pembayaran denda online.
- Mode offline — aplikasi mengasumsikan koneksi internet/jaringan lokal tersedia saat digunakan di lab (dikonfirmasi klien).

---

## 5. Tech Stack

| Layer | Teknologi | Keterangan |
|---|---|---|
| **Mobile App (Frontend)** | **Flutter** (Dart) | Sesuai dokumen klien; target platform Android |
| **State Management** | Provider / Riverpod / Bloc | Rekomendasi: **Riverpod** |
| **Backend / REST API** | **PHP** (native atau framework ringan seperti Slim/Laravel) | Menjembatani Flutter ↔ MySQL via REST API (JSON) |
| **Database** | **MySQL** | Sesuai dokumen klien |
| **Local Dev Server** | **XAMPP** | Untuk development lokal backend + MySQL |
| **IDE Pendukung** | NetBeans (jika ada bagian non-Flutter) | Sesuai dokumen klien |
| **API Communication** | HTTP REST + JSON, JWT token (mendukung opsi "Ingat saya" via refresh token) | |
| **Version Control** | Git + GitHub | |

### Rekomendasi Tambahan
- **Password hashing** (bcrypt) — dokumen asli menyimpan password polos, celah keamanan yang diperbaiki.
- **JWT** untuk token sesi API.

---

## 6. Arsitektur Sistem (Ringkas)

<img width="4169" height="600" alt="Project-2026-09-08-053122" src="https://github.com/user-attachments/assets/27137fa9-2534-44d3-9eb5-8c38a6c83737" />


- Flutter app tidak terhubung langsung ke MySQL — seluruh akses data melalui REST API PHP.
- Role-based access control ditegakkan di sisi backend, agar Kepala Program tidak bisa mengakses endpoint kelola barang/peminjam/user/pengaturan denda meski tahu URL-nya.

---

## 7. Functional Requirements (Detail per Fitur)

| ID | Fitur | Aktor | Deskripsi |
|---|---|---|---|
| FR-01 | Login | Laboran, Kepala Program | Autentikasi username/password, opsi "Ingat saya", link "Lupa Password" (reset manual oleh Laboran), redirect ke dashboard sesuai role |
| FR-02 | Kelola Barang | Laboran | Tambah/ubah/hapus/lihat barang: kode, nama, merk, kategori, jumlah, kondisi, stok, tanggal input, serial number, dan **spesifikasi ringkas fleksibel** (RAM/SSD/CPU/Display/Port/Lumens). Tampilan menggunakan **Tabel Data Barang terstruktur**, **Filter Chip Kategori 1-Klik**, serta **Pop-up Modal Detail Spesifikasi** (`BarangDetailSheet`) yang fleksibel untuk barang laptop maupun non-laptop. |
| FR-03 | Kelola Kategori | Laboran | CRUD kategori barang |
| FR-04 | Kelola Peminjam | Laboran | CRUD data peminjam: nama, **NIS/NIP**, **kelas/jabatan**, no HP |
| FR-05 | Peminjaman Barang | Laboran | Input transaksi: pilih peminjam, pilih satu atau lebih barang (multi-item) dengan jumlah masing-masing, tanggal pinjam & rencana kembali → status awal `menunggu_verifikasi`, stok langsung berkurang |
| FR-06 | Pengembalian Barang | Laboran | Layar terpisah dari Peminjaman. Input tanggal kembali aktual per item, kondisi (baik/rusak) → denda dihitung otomatis oleh sistem berdasarkan hari telat × tarif → status peminjaman jadi `dikembalikan` atau `sebagian_kembali` |
| FR-07 | Verifikasi Peminjaman | Kepala Program | Melihat daftar pengajuan berstatus `menunggu_verifikasi`, approve (→ `dipinjam`) atau reject dengan alasan (→ `dibatalkan`, stok otomatis dikembalikan) |
| FR-08 | Cetak Laporan | Laboran | Generate & export **5 jenis laporan** — Data Barang, Peminjaman, Pengembalian, Stok Barang, **Denda** — dalam format **PDF, Word (.docx), dan Excel (.xlsx)** |
| FR-09 | Lihat Laporan | Kepala Program | Akses laporan read-only (5 jenis) untuk pengawasan |
| FR-10 | Dashboard & Navigasi | Semua | Navigasi **hybrid**: Bottom Nav 4 tab (Laboran: Dashboard/Aset Lab/Transaksi/Laporan) atau 3 tab (Kepala Program: Dashboard/Verifikasi/Laporan) + grid akses fitur sekunder di tab Dashboard. FAB "+ Peminjaman Baru" (Laboran) |
| FR-11 | Pengaturan Denda | Laboran | Atur `tarif_per_hari` untuk perhitungan denda otomatis (nilai default sudah di-seed) |
| FR-12 | Kelola User | Laboran | CRUD akun login (username, password, level: Laboran/Kepala Program) — terpisah dari Data Peminjam |
| FR-13 | Kelola Stok Barang | Laboran | Catat mutasi stok masuk/keluar (di luar transaksi peminjaman/pengembalian) — mis. pengadaan baru, barang rusak/hilang — dengan log riwayat mutasi |

---

## 8. Database Schema

Skema final ada di dokumen terpisah: **`Database_Final_dan_Arsitektur.md`**, agar tidak ada dua sumber kebenaran yang bisa tidak sinkron. Ringkasan perubahan terbaru (Putaran 3, hasil cek mockup asli skripsi):
- `peminjam` ditambah `nis_nip` & `kelas_jabatan`.
- Status `ditolak` diganti jadi `dibatalkan` (istilah dari mockup), plus kolom `alasan_dibatalkan`.
- Status `menunggu_verifikasi` & `sebagian_kembali` ditambahkan sebagai tab ekstra di layar Peminjaman/Pengembalian, di luar 3 tab dasar mockup asli.
- Tabel `users` sekarang eksplisit dikelola lewat fitur Kelola User (FR-12).

---

## 9. Non-Functional Requirements

- **Keamanan**: password harus di-hash, endpoint API dilindungi token, role-based authorization di backend.
- **Usability**: UI mobile harus mempertimbangkan ukuran layar kecil, mengikuti gaya visual mockup asli skripsi (dashboard grid, badge status berwarna).
- **Performance**: proses update stok harus real-time setelah transaksi peminjaman/pengembalian disimpan.
- **Testing**: menggunakan Black Box Testing (sesuai metode pada dokumen skripsi) untuk validasi fungsional sebelum sidang.

---

## 10. Riwayat Keputusan Klien

### Putaran 1
| Pertanyaan | Keputusan Klien |
|---|---|
| Multi-barang per transaksi peminjaman? | **Ya** |
| Format laporan cetak | **Export PDF dan Word (.docx)** |
| Role tambahan di luar Laboran & Kepala Program? | **Tidak** |
| Perhitungan denda | **Otomatis** oleh sistem |
| Mode offline & deliverable akhir | Tidak perlu offline. Deliverable: GitHub Repository + GitHub Release (APK) |

### Putaran 2
| Pertanyaan | Keputusan Klien | Alasan |
|---|---|---|
| Siapa yang atur tarif denda? | **Laboran** | Sesuai Use Case skripsi |
| Perlu notifikasi push? | **Tidak** — cukup badge dashboard | Skripsi tidak mendefinisikan fitur notifikasi |
| Stok saat pengajuan ditolak | **Otomatis dikembalikan** | Konfirmasi klien |

### Putaran 3 (hasil cek mockup UI asli skripsi, Gambar 3.19–3.25)
| Temuan dari mockup asli | Keputusan |
|---|---|
| Nama aplikasi "Inventory Labkom" | Diadopsi sebagai nama resmi |
| Dashboard grid menu ikon | Diadopsi, mengganti desain kartu ringkasan sebelumnya |
| Peminjaman & Pengembalian sebagai 2 layar terpisah | Diadopsi |
| Status "Dibatalkan" (bukan "Ditolak") | Diadopsi sebagai penamaan resmi |
| Status `menunggu_verifikasi` & `sebagian_kembali` tidak ada di mockup asli | **Ditambahkan sebagai tab ekstra** di luar struktur asli — **dikonfirmasi klien** |
| Field `nis_nip` & `kelas_jabatan` di Data Peminjam | Ditambahkan ke skema |
| Menu "Kelola User" terpisah dari "Data Peminjam" | Ditambahkan sebagai FR-12 |
| Laporan 4 jenis (bukan 2) | Diadopsi |
| Login ada "Ingat saya" & "Lupa Password" | Diadopsi ke FR-01 |

### Putaran 4 (klien menyediakan `DESIGN.md` — design system resmi)
| Temuan/Pertanyaan | Keputusan |
|---|---|
| Warna & style visual | Ikuti `DESIGN.md` sepenuhnya (Navy `#384C9D`, Crimson `#D8232A`, Gold `#FCD116`) — **dikonfirmasi klien: boleh beda dari mockup skripsi** |
| Navigasi: Bottom Nav (DESIGN.md) vs Grid (mockup skripsi)? | **Hybrid** — Bottom Nav 4 tab (Laboran)/3 tab (Kepala Program) + grid untuk fitur sekunder |
| FAB barcode/QR scanner di DESIGN.md | Diserahkan ke tim — diputuskan jadi shortcut **"+ Peminjaman Baru"**, bukan barcode (barcode tetap fase 2), didesain future-proof jadi speed-dial |
| Multi lab room (Lab TKJ 1/2, Server Room) | **Tidak diimplementasi** — tetap 1 lab sesuai skripsi asli |

### Putaran 5 (hasil review desain Figma klien)
| Temuan | Keputusan |
|---|---|
| Multi-lab muncul lagi di desain | **Dihapus** — tetap 1 lab sesuai skripsi asli |
| Barcode/QR scanner muncul lagi di desain | **Dihapus** — dicek ke skripsi asli, cuma disebut di tinjauan pustaka, bukan fitur sistem yang dibangun. Tetap out-of-scope |
| Format Laporan (desain pakai PDF/XLS) | Diperluas jadi **3 format: PDF, Word, Excel** |
| Field baru dari desain (`SN` barang, `NIP` user) | Ditambahkan ke skema sebagai field opsional |
| 4 catatan minor lain (label bug, terminologi status, tombol kirim notifikasi, fitur BAST, field Guru Pembimbing UKK, kode transaksi Pengembalian) | Didokumentasikan di `UIUX_Wireframe_dan_Flow.md` §6, direkomendasikan dibahas saat kickoff Sprint Planning |

### Putaran 6 (hasil review Flowchart System, Use Case Table, Activity Diagram, Sequence Diagram skripsi asli)
| Temuan | Keputusan |
|---|---|
| Fitur "Kelola Stok Barang" (mutasi masuk/keluar) — ada di Flowchart System, tidak ada di Use Case Table/mockup | **Ditambahkan** sebagai FR-13, dengan log riwayat mutasi |
| "Laporan Denda" — ada di Flowchart System (5 jenis laporan), tidak ada di 4 jenis yang difinalisasi sebelumnya | **Ditambahkan** jadi laporan ke-5 |
| Status `menunggu_verifikasi` & tombol "Setujui/Tolak" | **Divalidasi konsisten** dengan Activity & Sequence Diagram Verifikasi asli — tidak berubah |
| Scope Kepala Program (Login/Verifikasi/Lihat Laporan saja) | **Divalidasi konsisten** dengan Tabel 3.1 Use Case resmi — tidak berubah |

---

## 11. Deliverable Akhir Proyek

1. **GitHub Repository**, berisi:
   - `/mobile` — source code Flutter
   - `/backend` — source code REST API PHP
   - `/database` — file SQL schema + seed data
   - `/design` — `DESIGN.md` (design system resmi) + hasil desain UI
   - `/docs` — panduan instalasi, konfigurasi, dan penggunaan aplikasi per role
2. **GitHub Release** — build APK siap di-install langsung ke perangkat Android.

---

## 12. Next Steps (Dokumen Selanjutnya)

1. ✅ PRD — final.
2. ✅ Database Schema final + ERD + Arsitektur teknis — lihat `Database_Final_dan_Arsitektur.md`.
3. ✅ UI/UX wireframe & flow — lihat `UIUX_Wireframe_dan_Flow.md` (navigasi hybrid + `DESIGN.md`).
4. ✅ System Desain UI — lihat `design/DESIGN.md` (design system resmi).
5. **Sprint planning / task breakdown** (dipecah per fitur FR-01 s/d FR-13, estimasi per sprint) — lihat `Sprint_Planning_Task_Breakdown.md`.

**Status dokumen: FINAL.** Tidak ada pertanyaan terbuka tersisa.
