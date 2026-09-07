# Sprint Planning & Task Breakdown
## Sistem Inventory Laboratorium Komputer Berbasis Mobile — "Inventory Labkom"

| | |
|---|---|
| **Versi** | 1.1 (update: tambah FR-13 Kelola Stok Barang & Laporan Denda) |
| **Rujukan** | PRD v1.6, Database_Final_dan_Arsitektur.md v1.5, UIUX_Wireframe_dan_Flow.md v1.5, `DESIGN.md` |
| **Metode** | Prototype (sesuai skripsi), dipecah jadi sprint mingguan untuk eksekusi |

> Scope kerja dibatasi ketat ke fitur yang sudah difinalisasi (FR-01–FR-12, sesuai kebutuhan skripsi). Desain visual mengacu 100% ke `DESIGN.md` — tidak ada task tambahan di luar itu (barcode scanning, multi-lab, BAST, dll sudah diputuskan di luar scope).

---

## 1. Asumsi

- **Durasi sprint**: 1 minggu/sprint (7 sprint total ≈ 7 minggu). Sesuaikan kalau kapasitas kerja kamu beda (misal jadi 2 minggu/sprint kalau dikerjakan part-time sambil kuliah/magang).
- **Tim**: bisa dikerjakan 1 orang (full-stack) atau dipecah 2 peran (Backend PHP+DB, Frontend Flutter) — task breakdown di bawah sudah dipisah per peran biar gampang dibagi kalau ada 2 orang.
- **Testing**: pakai **Black Box Testing** di tiap sprint (sesuai metode skripsi), bukan cuma di akhir — supaya bug ketemu lebih awal.
- Setiap sprint diasumsikan berakhir dengan build yang **bisa di-demo** (working increment), bukan cuma kode setengah jadi.

---

## 2. Ringkasan Sprint

| Sprint | Fokus | FR Terkait |
|---|---|---|
| 0 | Setup Fondasi (repo, project, schema, tema desain) | — |
| 1 | Autentikasi & Kelola User + Shell Navigasi | FR-01, FR-12 |
| 2 | Kelola Barang, Kategori, Peminjam, Mutasi Stok | FR-02, FR-03, FR-04, FR-13 |
| 3 | Peminjaman Multi-Item & Verifikasi | FR-05, FR-07 |
| 4 | Pengembalian & Pengaturan Denda | FR-06, FR-11 |
| 5 | Laporan (5 jenis × 3 format) | FR-08, FR-09 |
| 6 | Dashboard Real-Data, Polish, Testing Penuh, Build APK | FR-10, semua |

---

## 3. Detail per Sprint

### Sprint 0 — Setup Fondasi
**Tujuan**: environment siap, semua orang bisa mulai coding di sprint 1.

| Task | Peran | Estimasi |
|---|---|---|
| Setup struktur repo GitHub (`/mobile`, `/backend`, `/database`, `/design`, `/docs`) | Siapa saja | 0.5 hari |
| Setup project Flutter baru + konfigurasi tema (warna/tipografi/shape dari `DESIGN.md` sebagai `ThemeData`) | Frontend | 1 hari |
| Setup project PHP backend (struktur folder REST API) + JWT library | Backend | 1 hari |
| Buat `schema.sql` dari `Database_Final_dan_Arsitektur.md` v1.4 + jalankan di MySQL lokal (XAMPP) | Backend | 0.5 hari |
| Buat `seed.sql` (data contoh: kategori, barang, peminjam, tarif denda default) | Backend | 0.5 hari |
| Setup Riverpod / state management skeleton di Flutter | Frontend | 0.5 hari |

**Definition of Done**: `flutter run` menampilkan splash kosong tanpa error, backend bisa diakses via Postman, database ke-import dengan seed data.

---

### Sprint 1 — Autentikasi & Kelola User + Shell Navigasi
**Tujuan**: bisa login, role-based redirect jalan, Bottom Nav + Dashboard grid (kosongan) tampil sesuai `DESIGN.md`.

| Task | Peran | Estimasi |
|---|---|---|
| `POST /api/auth/login` — validasi username/password (hash bcrypt), return JWT, dukung `remember_me` | Backend | 1 hari |
| `CRUD /api/users` (Kelola User) — role-check hanya Laboran | Backend | 1 hari |
| Layar Login (sesuai Figma: header navy, form, Ingat Saya, Lupa Sandi) | Frontend | 1 hari |
| Token storage (secure storage) + auto-login kalau "Ingat saya" dicentang | Frontend | 0.5 hari |
| Shell navigasi: Bottom Nav 4 tab (Laboran) / 3 tab (Kepala Program) + Dashboard grid kosongan | Frontend | 1 hari |
| Layar Kelola User (list + form tambah/edit + hapus) | Frontend | 1 hari |
| Role-based route guard (Kepala Program tidak bisa akses route Laboran) | Frontend | 0.5 hari |

**Testing (Black Box)**: login sukses/gagal, redirect sesuai role, Kepala Program dicoba akses URL Laboran (harus ditolak backend), Kelola User CRUD.

**Definition of Done**: kedua role bisa login dan lihat Dashboard-nya masing-masing sesuai Figma; Laboran bisa tambah/hapus akun user.

---

### Sprint 2 — Kelola Barang, Kategori, Peminjam, Mutasi Stok
**Tujuan**: seluruh master data bisa dikelola Laboran, termasuk penyesuaian stok manual.

| Task | Peran | Estimasi |
|---|---|---|
| `CRUD /api/kategori` | Backend | 0.5 hari |
| `CRUD /api/barang` (termasuk field `serial_number` opsional) | Backend | 1 hari |
| `CRUD /api/peminjam` (nama, NIS/NIP, kelas/jabatan, no HP) | Backend | 1 hari |
| `GET/POST /api/stok-mutasi` — catat mutasi masuk/keluar, update `barang.stok` otomatis (validasi tidak boleh negatif) | Backend | 1 hari |
| Layar Aset Lab — segmented control "Daftar Barang \| Mutasi Stok" + list + filter kategori + search | Frontend | 1.5 hari |
| Form Tambah/Edit Barang | Frontend | 1 hari |
| Layar Kategori (list + tambah) | Frontend | 0.5 hari |
| Layar Data Peminjam — tabel + search + form tambah/edit | Frontend | 1.5 hari |
| Layar Mutasi Stok — riwayat mutasi + form catat mutasi baru | Frontend | 1 hari |

**Testing**: CRUD barang/kategori/peminjam, validasi field wajib, cek stok ke-update benar saat barang baru ditambah, cek mutasi stok masuk/keluar update `barang.stok` dengan benar & tidak bisa jadi negatif.

**Definition of Done**: Laboran bisa isi seluruh master data (barang, kategori, peminjam) dan mencatat penyesuaian stok manual dari awal sampai siap dipakai transaksi.

---

### Sprint 3 — Peminjaman Multi-Item & Verifikasi
**Tujuan**: alur peminjaman inti (fitur paling sering dipakai) jalan penuh, termasuk approval Kepala Program.

| Task | Peran | Estimasi |
|---|---|---|
| `POST /api/peminjaman` — multi-item, generate kode `PMJ-2026-XXX` otomatis, kurangi stok, status awal `menunggu_verifikasi` | Backend | 1.5 hari |
| `GET /api/peminjaman` — list + filter status (Semua/Menunggu/Dipinjam/Dikembalikan/Dibatalkan) | Backend | 1 hari |
| `PATCH /api/peminjaman/{id}/verifikasi` — approve (→dipinjam) / reject (→dibatalkan + alasan + restore stok otomatis) | Backend | 1 hari |
| Layar Transaksi (segmented control) tab Peminjaman — list + filter chip | Frontend | 1 hari |
| FAB "+ Peminjaman Baru" → Form multi-item (keranjang barang, pilih peminjam, tanggal) | Frontend | 2 hari |
| Layar Verifikasi (Kepala Program) — list pengajuan + Detail Pengajuan + tombol Setujui/Tolak | Frontend | 1.5 hari |

**Testing**: buat peminjaman multi-item → cek stok berkurang → Kepala Program approve → status jadi dipinjam; ulangi dengan reject → cek stok balik otomatis + alasan tersimpan.

**Definition of Done**: alur penuh Laboran ajukan peminjaman → Kepala Program verifikasi → status & stok berubah benar, bisa didemo end-to-end.

---

### Sprint 4 — Pengembalian & Pengaturan Denda
**Tujuan**: barang bisa dikembalikan per-item dengan denda otomatis.

| Task | Peran | Estimasi |
|---|---|---|
| `GET/PUT /api/pengaturan-denda` | Backend | 0.5 hari |
| `POST /api/pengembalian` — per item, hitung hari telat & denda otomatis dari `pengaturan_denda` | Backend | 1.5 hari |
| `GET /api/pengembalian` — list transaksi + status turunan (Belum/Sebagian/Sudah Kembali/Terlambat) | Backend | 1 hari |
| Update status header `peminjaman` otomatis (sebagian_kembali/dikembalikan) saat semua/sebagian item kembali | Backend | 0.5 hari |
| Layar Transaksi tab Pengembalian — list + filter chip | Frontend | 1 hari |
| Detail Pengembalian (status per-item) + Form Pengembalian (kondisi + info denda read-only) | Frontend | 1.5 hari |
| Layar Pengaturan Denda | Frontend | 0.5 hari |

**Testing**: kembalikan barang tepat waktu (denda 0), telat (denda terhitung benar sesuai tarif), kembalikan sebagian barang dari 1 transaksi (status jadi sebagian_kembali).

**Definition of Done**: seluruh siklus peminjaman→pengembalian bisa didemo termasuk kasus telat & multi-item sebagian kembali.

---

### Sprint 5 — Laporan (5 jenis × 3 format)
**Tujuan**: semua laporan bisa di-generate dan diunduh.

| Task | Peran | Estimasi |
|---|---|---|
| Setup library `mPDF`/`TCPDF` (PDF), `PHPWord` (Word), `PhpSpreadsheet` (Excel) di backend | Backend | 0.5 hari |
| `GET /api/laporan/barang` — 3 format | Backend | 1 hari |
| `GET /api/laporan/peminjaman` — 3 format | Backend | 1 hari |
| `GET /api/laporan/pengembalian` — 3 format | Backend | 1 hari |
| `GET /api/laporan/stok` — 3 format | Backend | 1 hari |
| `GET /api/laporan/denda` — 3 format (rekap denda dari tabel `pengembalian`) | Backend | 0.5 hari |
| Layar Laporan — 5 card jenis laporan + filter tanggal + pilih format + unduh | Frontend | 1.5 hari |
| Mode read-only untuk Kepala Program (label "Mode Lihat Saja") | Frontend | 0.5 hari |

**Testing**: generate tiap kombinasi jenis×format (15 kombinasi), buka file hasil download, pastikan data akurat & format tidak corrupt.

**Definition of Done**: Laboran & Kepala Program bisa generate dan unduh semua jenis laporan dalam 3 format tanpa error.

---

### Sprint 6 — Dashboard Real-Data, Polish, Testing Penuh, Build APK
**Tujuan**: aplikasi siap rilis.

| Task | Peran | Estimasi |
|---|---|---|
| Hubungkan Dashboard (ringkasan angka: Total Barang, Sedang Dipinjam, Perlu Verifikasi) ke data backend asli | Frontend + Backend | 1 hari |
| Samakan terminologi status jadi "Dipinjam/Dibatalkan" konsisten di semua layar (termasuk layar Verifikasi) | Frontend | 0.5 hari |
| Perbaiki label header/tab yang salah (hasil review Figma — Data Peminjam, Detail Pengembalian, Pengaturan Denda) | Frontend | 0.5 hari |
| Uji seluruh FR-01–FR-13 dengan Black Box Testing menyeluruh (sesuai metode skripsi Bab III) | Semua | 2 hari |
| Perbaikan bug dari hasil testing | Semua | 1-2 hari |
| Build APK release (`flutter build apk --release`) | Frontend | 0.5 hari |
| Tulis `INSTALLATION.md`, `CONFIGURATION.md`, `USER_GUIDE.md` | Siapa saja | 1 hari |
| Push final ke GitHub Repository + buat GitHub Release dengan APK | Siapa saja | 0.5 hari |

**Definition of Done**: APK bisa di-install & dipakai penuh sesuai PRD, dokumentasi lengkap, repo & release siap diserahkan ke klien.

---

## 4. Rekap Estimasi Total

| Sprint | Estimasi Total (hari-kerja) |
|---|---|
| Sprint 0 | ~4 hari |
| Sprint 1 | ~6 hari |
| Sprint 2 | ~8.5 hari |
| Sprint 3 | ~8 hari |
| Sprint 4 | ~6 hari |
| Sprint 5 | ~7.5 hari |
| Sprint 6 | ~7-8 hari |
| **Total** | **~47-49 hari-kerja** (≈ 7-10 minggu tergantung kapasitas kerja per hari) |

---

## 5. Risiko & Ketergantungan

| Risiko | Mitigasi |
|---|---|
| Generate laporan 3 format × 5 jenis (Sprint 5) berpotensi paling makan waktu | Kerjakan PDF dulu (paling penting/umum), Word & Excel menyusul; bisa reuse query data yang sama untuk 3 format |
| Alur multi-item peminjaman (Sprint 3) adalah bagian paling kompleks secara logika (stok, status, verifikasi) | Testing paling ketat di sprint ini, jangan lanjut ke Sprint 4 sebelum alur ini benar-benar teruji |
| Kalau dikerjakan 1 orang, total ~7-9 minggu penuh mepet buat timeline skripsi — cek kalender sidang | Kalau perlu dipercepat, Sprint 2 & 5 paling mungkin dipangkas/disederhanakan tanpa mengubah fitur inti |

---

## 6. Next Step
Setelah Sprint 0 selesai (environment siap), mulai eksekusi Sprint 1. Dokumen ini bisa dipakai langsung sebagai checklist/board (Trello, GitHub Projects, dll).
