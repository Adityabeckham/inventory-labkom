# Inventory Labkom

Sistem Inventory Laboratorium Komputer Berbasis Mobile — **SMK Al-Madani Jampangkulon**.

Aplikasi Android (Flutter) untuk mengelola inventaris laboratorium komputer: data barang, kategori, peminjam, transaksi peminjaman multi-item, pengembalian dengan denda otomatis, verifikasi oleh Kepala Program, dan laporan dalam 5 jenis × 3 format.

Dibangun sebagai bagian dari skripsi *"Rancang Bangun System Inventory Laboratorium Komputer Berbasis Mobile Menggunakan Metode PIECES"* (Aria Rimba Fauna — Universitas Faletehan). Metode analisis **PIECES**, metode pengembangan **Prototype**.

---

## Struktur Repository

| Folder | Isi |
|---|---|
| `mobile/` | Source code aplikasi Flutter (Android) |
| `backend/` | REST API PHP — menjembatani Flutter ↔ MySQL |
| `database/` | `schema.sql` (struktur tabel) + `seed.sql` (data awal) |
| `design/` | `DESIGN.md` — design system resmi (Material 3) |
| `docs/` | Panduan instalasi, konfigurasi, dan penggunaan |
| `docs_project/` | Dokumen perencanaan: PRD, skema database, wireframe, sprint planning |
| `Dokumentasi-Klien/` | **Arsip** — artefak awal klien, tidak dipakai (lihat catatan di bawah) |

## Arsitektur

```
┌──────────────────┐    HTTPS/JSON     ┌────────────────────┐    SQL    ┌─────────┐
│  Flutter (Android) │ ───────────────▶ │  REST API PHP       │ ────────▶ │  MySQL   │
│                    │ ◀─────────────── │  (XAMPP saat dev)   │ ◀──────── │          │
└──────────────────┘   JWT Bearer      └────────────────────┘           └─────────┘
```

Flutter **tidak** terhubung langsung ke MySQL. Seluruh akses data lewat REST API, dan otorisasi berbasis role ditegakkan di backend — Kepala Program tidak bisa mengakses endpoint kelola barang/peminjam/user meski tahu URL-nya.

## Aktor

| Aktor | `users.level` | Hak akses |
|---|---|---|
| **Laboran** | `admin` | Kelola user, barang, kategori, peminjam, mutasi stok, catat peminjaman & pengembalian, atur tarif denda, cetak laporan |
| **Kepala Program** | `super_admin` | Verifikasi pengajuan peminjaman, lihat laporan (read-only) |

## Mulai dari Mana

1. **Setup** — ikuti [docs/INSTALLATION.md](docs/INSTALLATION.md)
2. **Konfigurasi** — ikuti [docs/CONFIGURATION.md](docs/CONFIGURATION.md)
3. **Rencana kerja** — [docs_project/Sprint_Planning_Task_Breakdown.md](docs_project/Sprint_Planning_Task_Breakdown.md)

## Dokumen Acuan

Sumber kebenaran ada di `docs_project/`, semuanya berstatus FINAL:

| Dokumen | Isi |
|---|---|
| [PRD](docs_project/PRD_Sistem_Inventory_Lab_SMK_AlMadani.md) | Kebutuhan produk, FR-01 s/d FR-13, riwayat keputusan klien |
| [Database & Arsitektur](docs_project/Database_Final_dan_Arsitektur.md) | Skema 9 tabel, alur status, kontrak endpoint API |
| [UI/UX & Flow](docs_project/UIUX_Wireframe_dan_Flow.md) | Struktur navigasi, wireframe per layar, mapping badge status |
| [Sprint Planning](docs_project/Sprint_Planning_Task_Breakdown.md) | Task breakdown Sprint 0–6 dengan estimasi |
| [DESIGN.md](design/DESIGN.md) | Design system: warna, tipografi, shape, komponen |
| [Analisis Dokumen Skripsi](docs/analisis-dokumen.md) | Ekstraksi BAB 1–3 + peta 12 ketidaksesuaian dan resolusinya |
| [Deviasi dari Spesifikasi](docs/deviasi-dari-spesifikasi.md) | Tempat kode sengaja berbeda dari dokumen, beserta alasannya |

## Status Pengerjaan

| Sprint | Fokus | Status |
|---|---|---|
| 0 | Setup fondasi | Selesai — backend, database, dokumentasi, project Flutter, dan tema `DESIGN.md` |
| 1 | Autentikasi & Kelola User | Selesai — Login, shell navigasi, Kelola User, secure storage, route guard |
| 2 | Barang, Kategori, Peminjam, Mutasi Stok | Selesai — Aset Lab, Kategori, Data Peminjam, Mutasi Stok |
| 3 | Peminjaman multi-item & Verifikasi | Belum |
| 4 | Pengembalian & Pengaturan Denda | Belum |
| 5 | Laporan | Belum |
| 6 | Dashboard, polish, testing, build APK | Belum |

## Verifikasi

Dua lapis pengujian, keduanya tanpa dependensi Composer.

**Unit — tidak butuh server maupun database:**

```bash
php backend/tests/run.php
```

Menguji implementasi JWT tulis tangan (tampering payload, serangan `alg:none`, token kedaluwarsa, token tanpa `exp`, penerbit asing, `nbf` masa depan), pencocokan pola route, dan normalisasi path untuk tiap mode deploy.

**Flutter — unit (tema, model, matriks hak akses):**

```bash
cd mobile && flutter test
```

**Flutter — integrasi terhadap backend sungguhan.** Membuktikan lapisan jaringan (dio, header token, penguraian respons, pemetaan model) benar-benar nyambung — hal yang tidak bisa dibuktikan unit test dengan data palsu. Dilewati otomatis kalau backend tidak terjangkau:

```bash
cd mobile && flutter test test/api_integration_test.dart
```

**Black Box — menguji API lewat HTTP**, sesuai metode pengujian di skripsi (BAB II). Butuh server jalan dan database sudah di-import:

```bash
php backend/tests/api.php
```

Menguji tiap endpoint dari sisi klien: login benar/salah, "Ingat saya", penolakan yang tidak membocorkan username mana yang valid, penegakan hak akses (Kepala Program ditolak dari endpoint kelola), CRUD akun, reset password, dan pengaman yang mencegah aplikasi terkunci.

Beri argumen base URL kalau backend tidak di `127.0.0.1:8080`:

```bash
php backend/tests/api.php http://localhost/inventory
```

## Catatan tentang platform web di `mobile/`

Target aplikasi adalah **Android** (PRD §5), dan deliverable akhirnya APK. Platform `web` diaktifkan sebagai alat bantu verifikasi visual selama pengembangan — Android SDK belum terpasang, jadi web adalah satu-satunya cara menjalankan dan memeriksa tampilan UI.

Bisa dihapus sebelum penyerahan akhir:

```bash
rm -rf mobile/web
```

## Catatan tentang `Dokumentasi-Klien/`

Folder ini berisi artefak awal dari klien dan **disimpan sebagai arsip saja**:

- `inventory_db.sql` — dump phpMyAdmin skema **lama** (versi dokumen skripsi). Berbeda dari skema final di `database/schema.sql`.
- `Inventory_api/` — prototipe API awal. **Jangan dipakai sebagai basis**: query dirangkai langsung dari `$_POST` (SQL injection terbuka), password dibandingkan plaintext, tanpa JWT maupun otorisasi role.

Backend di `backend/` ditulis ulang dari nol mengikuti `Database_Final_dan_Arsitektur.md` v1.5.
