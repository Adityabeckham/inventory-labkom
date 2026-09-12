# UI/UX Wireframe & User Flow
## Sistem Inventory Laboratorium Komputer Berbasis Mobile — "Inventory Labkom"

| | |
|---|---|
| **Versi** | 1.5 (Final — hasil review Flowchart/Use Case/Activity/Sequence Diagram skripsi asli) |
| **Rujukan** | PRD v1.6, Database_Final_dan_Arsitektur.md v1.5, `DESIGN.md` (design system resmi klien) |

> Struktur layar & flow mengikuti mockup asli skripsi (Gambar 3.19–3.25). Gaya visual (warna, tipografi, shape, elevation, komponen) sekarang mengikuti **`DESIGN.md`** yang disediakan klien — klien konfirmasi warna boleh beda dari mockup skripsi. Navigasi memakai struktur **hybrid**: Bottom Navigation Bar untuk 4 menu utama + Dashboard grid untuk fitur sekunder.

---

## 1. Struktur Navigasi (Hybrid — dikonfirmasi klien)

### Laboran — Bottom Navigation Bar (4 tab)
| Tab | Isi |
|---|---|
| **Dashboard** | Ringkasan + grid akses fitur sekunder: Kategori, Kelola User, Data Peminjam, Pengaturan Denda |
| **Aset Lab** | Segmented control internal "Daftar Barang \| Mutasi Stok" — Daftar Barang (list, tambah, ubah, hapus); Mutasi Stok (riwayat + catat mutasi masuk/keluar, FR-13) |
| **Transaksi** | Segmented control internal "Peminjaman \| Pengembalian" (masing-masing dengan filter tab status sendiri) |
| **Laporan** | 5 jenis laporan (Data Barang, Peminjaman, Pengembalian, Stok Barang, Denda) |

> Profil/Pengaturan Akun (Edit Profile, Ubah Password, Logout) diakses melalui ikon Profil pada Top App Bar.

**FAB (Floating Action Button)**: shortcut global **"+ Peminjaman Baru"**, muncul di atas Bottom Nav pada tab Dashboard & Transaksi. Warna Crimson Red (`#D8232A`) sesuai DESIGN.md, ikon "+" polos (bukan barcode scanner — barcode scanning tetap di luar scope Fase 1). Didesain future-proof: kalau fase 2 menambah fitur scan barcode, FAB bisa diperluas jadi Extended/Speed-dial FAB dengan 2 opsi ("Scan Barcode" & "Tambah Manual") tanpa mengubah struktur navigasi.

### Kepala Program — Bottom Navigation Bar (3 tab)
| Tab | Isi |
|---|---|
| **Dashboard** | Ringkasan pengawasan |
| **Verifikasi** | Daftar pengajuan `menunggu_verifikasi` → Setuju/Tolak |
| **Laporan** | Read-only, 5 jenis sama seperti Laboran |

> Menu Verifikasi **tidak** muncul di Bottom Nav Laboran — kalau Laboran perlu lihat status pengajuan, aksesnya lewat grid Dashboard (read-only, tanpa tombol approve/reject; otorisasi tetap ditegakkan di backend).

> Profil/Pengaturan Akun (Edit Profile, Ubah Password, Logout) diakses melalui ikon Profil pada Top App Bar.

---

## 2. Daftar Layar Lengkap

### Laboran
1. Login (dengan "Ingat saya" & "Lupa Password")
2. Dashboard (ringkasan + grid: Kategori, Kelola User, Data Peminjam, Pengaturan Denda)
3. Aset Lab → Data Barang (list, form tambah/ubah) via segmented control "Daftar Barang | Mutasi Stok"
4. Aset Lab → Mutasi Stok (riwayat + form catat mutasi masuk/keluar) — **BARU, FR-13**
4. Kategori (dari grid)
5. Kelola User (dari grid)
6. Data Peminjam (dari grid — tabel: nama, NIS/NIP, kelas/jabatan, no HP)
7. Transaksi → Peminjaman (list + form Peminjaman Baru multi-item, via segmented control)
8. Transaksi → Pengembalian (list + form pengembalian per-item, via segmented control)
9. Laporan (5 jenis — Data Barang, Peminjaman, Pengembalian, Stok Barang, Denda)
10. Pengaturan Denda (dari grid)

### Kepala Program
1. Login
2. Dashboard (ringkasan pengawasan)
3. Verifikasi — daftar pengajuan → detail → Setuju/Tolak
4. Laporan (read-only)

---

## 3. User Flow per Fitur

### 3.1 Login
```
<img width="710" height="1542" alt="Galaxy-S22+-localhost" src="https://github.com/user-attachments/assets/c6723feb-8fbe-4d35-9354-2c5e1c781633" />
```

### 3.2 Dashboard (tab pertama di Bottom Nav)

### 3.2.1 Ringkasan Inventoris
```
<img width="710" height="1542" alt="Galaxy-S22+-localhost (1)" src="https://github.com/user-attachments/assets/144d338c-edd0-4497-84f9-5c802bf20333" />
```

### 3.2.1 Dasboard Laboran + Akses Cepat
```
<img width="710" height="1542" alt="Galaxy-S22+-localhost (2)" src="https://github.com/user-attachments/assets/a1f3cea3-ffa0-4c82-83f0-2bc030dfb7c7" />
```



### 3.3 Aset Lab — Segmented Control (Daftar Barang | Mutasi Stok)
```
<img width="710" height="1542" alt="Galaxy-S22+-localhost" src="https://github.com/user-attachments/assets/9feaa955-2c64-42f7-aace-54e8f0976447" />

```

### 3.3 Aset Lab — Mutasi Stok 
```
<img width="710" height="1542" alt="Galaxy-S22+-localhost" src="https://github.com/user-attachments/assets/7876c955-73c2-45e5-a4d4-6537aa969bc9" />

```
Fitur ini **terpisah** dari perubahan stok akibat transaksi Peminjaman/Pengembalian — khusus penyesuaian manual (barang baru datang, rusak, hilang, dll), sesuai Flowchart System asli skripsi yang memisahkan menu "Kelola Stok Barang" dari "Kelola Barang".



### 3.4 Kelola User (dari grid Dashboard)
```
<img width="710" height="1542" alt="Kelola-User" src="https://github.com/user-attachments/assets/83baa0c7-0cf6-4990-9dc8-c5dc263715c0" />

```

### 3.6 Data Peminjam (dari grid Dashboard) — tampilan tabel
```

```

### 3.7 Transaksi — Peminjaman (segmented control kiri)
```
<img width="742" height="1612" alt="Peminjaman" src="https://github.com/user-attachments/assets/b0cc5e18-f577-44d9-995e-c7c07370e55a" />

```

### 3.8 Peminjaman Baru — Multi-Item (dibuka dari FAB + Peminjaman Baru)
```
<img width="742" height="1612" alt="Galaxy-S22+-localhost (3)" src="https://github.com/user-attachments/assets/529e4f56-c448-4b44-bb4a-009cbef4e109" />

```

### 3.9 Transaksi — Pengembalian (segmented control kanan)
```
<img width="742" height="1612" alt="Galaxy-S22+-localhost (1)" src="https://github.com/user-attachments/assets/7ffe7652-11b1-4833-a490-019bd2e91ef0" />

```

### 3.10 Verifikasi Peminjaman (Kepala Program)
```
<img width="742" height="1612" alt="Galaxy-S22+-localhost (6)" src="https://github.com/user-attachments/assets/364f47a6-5ad7-4d11-91ea-8acdd5dbe8f6" />

```

### 3.11 Laporan (5 jenis)
```

```
Laboran: generate & unduh. Kepala Program: read-only, label "Mode Lihat Saja".
"Laporan Denda" ditambahkan hasil review Flowchart System asli skripsi — rekap seluruh denda keterlambatan pengembalian.

### 3.12 Pengaturan Denda (dari grid Dashboard)
```
<img width="742" height="1612" alt="Galaxy-S22+-localhost (4)" src="https://github.com/user-attachments/assets/af177d16-e83a-4a8c-9243-ed222273c00f" />

```

---

## 4. Mapping Badge Status ke `DESIGN.md`

DESIGN.md mendefinisikan 3 gaya badge dasar (Nominal/Hijau, Pending/Gold, Critical/Merah) + 1 neutral tag. Status transaksi kita ada 5 nilai, jadi dipetakan sebagai berikut (1 tambahan gaya baru untuk "sebagian", mengikuti formula visual yang sama):

| Status | Gaya Badge | Warna |
|---|---|---|
| `menunggu_verifikasi` | Pending Verification | bg `#FEF9C3`, teks `#854D0E`, border `#FDE047` |
| `dipinjam` / Belum Kembali | Neutral/Category Tag (varian navy tint) | bg `#EEF2FF`, teks `#384C9D` |
| `sebagian_kembali` | **Baru** — mengikuti formula sama (bg muda + teks tua + border tipis), warna biru | bg `#EFF6FF`, teks `#1E40AF`, border `#BFDBFE` |
| `dikembalikan` / Sudah Kembali | Nominal / In-Service | bg `#ECFDF5`, teks `#065F46`, border `#A7F3D0` |
| `dibatalkan` / Terlambat | Critical / Overdue | bg `#FEF2F2`, teks `#991B1B`, border `#FECACA` |

---

## 5. Wireframe Ringkas (ASCII — layar kunci, gaya DESIGN.md)

### 5.1 Login
<img width="390" height="1447" alt="LOGIN-Laboran" src="https://github.com/user-attachments/assets/dc1aebb7-e322-4d24-aaf9-c08b7b587d18" />

### 5.2 Dashboard Laboran (dengan Bottom Nav + FAB)
<img width="390" height="1447" alt="2 2 Dashboard Laboran" src="https://github.com/user-attachments/assets/9ea70120-e18b-4a97-89f9-7ae39e084210" />


### 5.3 Transaksi — Peminjaman (segmented control)
```
<img width="742" height="1612" alt="Peminjaman" src="https://github.com/user-attachments/assets/40e215bf-80da-47d3-932e-9f66be17fb80" />

```

### 5.4 Data Peminjam — Tabel
```
┌─────────────────────────────────────┐
│ ←   Kelola Peminjam                    │
├─────────────────────────────────────┤
│ 🔍 Cari peminjam...   + Tambah Peminjam │
├─────────────────────────────────────┤
│ No│Nama       │NIS/NIP│Kelas   │HP │✎🗑│
│ 1 │Raka Maulana│190001│XII TKJ1│08..│✎🗑│
└─────────────────────────────────────┘
```

### 5.5 Verifikasi (Kepala Program)
```
<img width="742" height="1612" alt="Galaxy-S22+-localhost (6)" src="https://github.com/user-attachments/assets/815e40c4-9b08-4592-95d2-c552bd01af42" />

```

---

## 6. Riwayat Keputusan Klien

### Putaran 1–3
Lihat ringkasan lengkap di `PRD_Sistem_Inventory_Lab_SMK_AlMadani.md` §10 dan `Database_Final_dan_Arsitektur.md` §5.

### Putaran 4 — Adopsi `DESIGN.md` (design system resmi klien)
| Item | Keputusan |
|---|---|
| Warna & style visual | Ikuti `DESIGN.md` sepenuhnya (Deep Navy `#384C9D` primary, Crimson `#D8232A` secondary, Gold `#FCD116` tertiary) — **dikonfirmasi klien: boleh beda dari mockup skripsi** |
| Navigasi | **Hybrid**: Bottom Nav 4 tab (Laboran) / 3 tab (Kepala Program) + Dashboard grid untuk fitur sekunder |
| FAB Barcode/QR Scanner | **Tidak dipakai untuk barcode** (tetap fase 2) — direpurpose jadi shortcut global "+ Peminjaman Baru", didesain future-proof untuk speed-dial nanti |
| Multi Lab Room | **Tidak diimplementasi** — tetap 1 lab sesuai skripsi asli, konsep "Lab TKJ 1/2, Server Room" dihapus dari desain |

### Putaran 5 — Hasil Review Desain Figma (link klien)
Desain Figma ([WSK4wdfvMKBAFLmcNyIZnI](https://www.figma.com/design/WSK4wdfvMKBAFLmcNyIZnI)) direview layar-per-layar terhadap dokumen ini. Penomoran layar di Figma **sudah persis mengikuti** struktur dokumen ini (2.2 Dashboard Laboran, 2.3 Aset Lab, dst) — eksekusi desain sudah sangat sesuai kerangka.

| Temuan | Keputusan |
|---|---|
| Konsep multi-lab muncul lagi (dropdown "Lab TKJ 1" di Dashboard, field "Lokasi Lab" di form Tambah Barang, lokasi per item) | **Dihapus dari desain** — dikonfirmasi ulang: tetap 1 lab sesuai skripsi asli |
| Ikon barcode/QR scanner muncul lagi (search Aset Lab, form Tambah Barang, search Pengembalian) | **Dihapus dari semua layar** — dicek ke skripsi asli: barcode/QR cuma disebut di tinjauan pustaka (penelitian orang lain), bukan fitur sistem yang dibangun skripsi ini. Tetap out-of-scope |
| Format Laporan di desain pakai PDF/XLS, kesepakatan awal PDF/Word | **Diperluas jadi 3 format**: PDF, Word, dan Excel |

**Resolusi 4 catatan minor (diputuskan: scope tetap ketat mengikuti skripsi, UI mengikuti `DESIGN.md`):**
1. Label header/tab salah di beberapa layar (Data Peminjam, Detail Pengembalian, Pengaturan Denda menampilkan "Aset Lab") — **bug murni, perbaiki di Figma**, tidak ada keputusan fitur yang menggantung.
2. Terminologi status "Disetujui/Ditolak" (layar Verifikasi) vs "Dipinjam/Dibatalkan" (layar lain) — **diseragamkan jadi "Dipinjam/Dibatalkan"** di semua layar, sesuai istilah database & skripsi asli.
3. Tombol "Kirim Notifikasi"/"Tagih & Selesaikan" dan fitur "Berita Acara (BAST)" — **tidak ada di skripsi asli, di luar scope**. Dihapus dari desain/implementasi fase ini (boleh jadi catatan fase 2 kalau klien minta nanti).
4. Field "Disetujui Guru Pembimbing UKK" di form Peminjaman Baru — **skripsi asli cuma punya 2 aktor** (Laboran & Kepala Program), tidak ada role approval ketiga. Field ini diturunkan jadi catatan teks bebas saja (bagian dari "Catatan Keperluan/Praktik"), bukan approval gate/workflow baru.

**Status dokumen: FINAL.** Semua temuan hasil review Figma sudah diputuskan, tidak ada yang menggantung.

### Putaran 6 — Review Flowchart System, Use Case Table, Activity Diagram, Sequence Diagram skripsi asli
Setelah desain Figma, dilakukan review lanjutan terhadap dokumen perancangan formal skripsi (bukan cuma mockup UI) — Flowchart System (Gambar 3.2), Use Case Diagram + Tabel 3.1, Activity Diagram, dan Sequence Diagram.

| Temuan | Keputusan |
|---|---|
| Flowchart System punya menu terpisah "Kelola Stok Barang" (Lihat Stok, Update Stok, Mutasi Masuk/Keluar) — tidak ada di Use Case Table maupun mockup Figma | **Ditambahkan** sebagai FR-13 — segmented control baru "Mutasi Stok" di tab Aset Lab (lihat §3.3b) |
| Flowchart System sebut 5 jenis laporan termasuk "Laporan Denda" — sebelumnya cuma 4 jenis (ikut mockup) | **Ditambahkan** jadi laporan ke-5 |
| Status `menunggu_verifikasi` (kita tambahkan di Putaran 1-3) | **Divalidasi konsisten** — Activity & Sequence Diagram Verifikasi asli skripsi memang punya konsep "data yang belum diverifikasi" |
| Tombol aksi "Setujui/Tolak" di layar Verifikasi | **Divalidasi konsisten** dengan istilah di Activity Diagram Verifikasi asli ("Verifikasi disetujui/ditolak") |
| Scope Kepala Program (Login/Verifikasi/Lihat Laporan saja, tanpa akses Data Barang/Peminjaman) | **Divalidasi konsisten** dengan Tabel 3.1 Use Case resmi — diagram Use Case bergambar sempat terlihat ambigu, tapi tabel deskripsi tekstual lebih otoritatif dan itu sudah sesuai implementasi kita |

**Status dokumen: FINAL.** Semua elemen formal skripsi (Flowchart, Use Case, Activity, Sequence) sudah dicek dan disinkronkan.

---

## 7. Next Step
Lanjut ke **Sprint Planning / Task Breakdown** — pecah FR-01 s/d FR-13 jadi task teknis per sprint dengan estimasi.
