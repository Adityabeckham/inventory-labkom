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

<img width="710" height="1542" alt="Tampilan-Login" src="https://github.com/user-attachments/assets/b742fba4-c924-4b2e-bb10-a960a96c8923" />

### 3.2 Dashboard (tab pertama di Bottom Nav)

### 3.2.1 Ringkasan Inventoris

<img width="710" height="1542" alt="Dashboard-Laboran" src="https://github.com/user-attachments/assets/a217d5df-e731-4715-9ec2-20bf6cc88c43" />

### 3.2.2 Dashboard Laboran + Akses Cepat

<img width="710" height="1542" alt="Dashboard-Laboran + Akses Cepat" src="https://github.com/user-attachments/assets/cfd162af-44e2-4064-9b5f-b7c167db4c02" />

### 3.3 Aset Lab — Segmented Control (Daftar Barang | Mutasi Stok)

<img width="710" height="1542" alt="Daftar-Barang-Semua-Kategori" src="https://github.com/user-attachments/assets/08d73489-8ce6-4912-8477-636c980676ea" />

### 3.3.1 Aset Lab — Mutasi Stok 

<img width="710" height="1542" alt="Mutasi-Stok" src="https://github.com/user-attachments/assets/e3954e2a-3c22-41a8-9fc0-34d143f3a8db" />

Fitur ini **terpisah** dari perubahan stok akibat transaksi Peminjaman/Pengembalian — khusus penyesuaian manual (barang baru datang, rusak, hilang, dll), sesuai Flowchart System asli skripsi yang memisahkan menu "Kelola Stok Barang" dari "Kelola Barang".

### 3.4 Kelola User (dari grid Dashboard)

<img width="710" height="1542" alt="Kelola-User" src="https://github.com/user-attachments/assets/bbd95957-9f79-4fd8-a956-4a160b31465f" />

### 3.6 Data Peminjam (dari grid Dashboard) — Tampilan Tabel
```
┌────────────────────────────────────────────────────────────────────────┐
│ No │ Nama Peminjam    │ Identitas & Kelas          │ No HP       │ Aksi │
├────┼──────────────────┼────────────────────────────┼─────────────┼──────┤
│ 1  │ Raka Maulana     │ 0051234567 · XI RPL 2      │ 0812345678  │ ✎ 🗑  │
│ 2  │ Siti Aminah      │ -                          │ -           │ ✎ 🗑  │
└────────────────────────────────────────────────────────────────────────┘
```

### 3.7 Transaksi — Peminjaman (segmented control kiri)

<img width="742" height="1612" alt="Peminjaman" src="https://github.com/user-attachments/assets/fd870288-905a-4fa7-a3ce-1c6ccee47929" />

```
Bottom Nav → [Transaksi] → Segmented Control: [Peminjaman] | Pengembalian
   Search bar "Cari kode, nama peminjam, atau NIS..."
   Filter chip: Semua | Menunggu Verifikasi* | Dipinjam | Dikembalikan | Dibatalkan
   (*tab tambahan — dikonfirmasi klien, di luar 3 status dasar mockup asli)
        │
        ▼
   Tabel Data Peminjaman (Data Table): Kolom Kode, Peminjam, Identitas (NIS/NIP & Kelas),
   Status Pill, Total Unit, Tgl Pinjam, Tgl Kembali, Aksi (Detail)
        │
        ▼
   Tap Baris / Tombol Detail → Detail Peminjaman Sheet (lihat detail barang & status)
        │
        ▼
   FAB "+ Peminjaman Baru" → form multi-item (lihat §3.8)
```

### 3.8 Peminjaman Baru — Multi-Item (dibuka dari FAB + Peminjaman Baru)

<img width="742" height="1612" alt="Peminjaman-Baru" src="https://github.com/user-attachments/assets/8ff0bcdf-77ee-4699-b37b-0d022a3c0e91" />

### 3.9 Transaksi — Pengembalian (segmented control kanan)

<img width="742" height="1612" alt="Pengembalian" src="https://github.com/user-attachments/assets/4669611f-abd7-4853-9101-3e0cdac30110" />

### 3.10 Verifikasi Peminjaman (Kepala Program)

<img width="742" height="1612" alt="Verifikasi-Peminjaman" src="https://github.com/user-attachments/assets/b8b53c49-b5c3-41a8-b67b-f10dcd2c6928" />

### 3.11 Laporan (5 jenis dengan Category Switcher Chips)
```
Bottom Nav → [Laporan]
   Banner Deep Navy: "Laporan Inventaris — Buat dan cetak laporan data
   barang sesuai kebutuhan"
   Filter Periode: Tanggal Dari - Sampai
        │
        ▼
   Kategori Chips: [Semua] | [Data Barang] | [Peminjaman] | [Pengembalian] | [Stok Barang] | [Denda]
        │
        ▼
   Kartu Laporan Terpilih → Informasi Ringkas → 3 Tombol Export: **PDF** | **Word** | **Excel (Spreadsheet)**
```
Laboran: generate & unduh. Kepala Program: read-only, label "Mode Lihat Saja".
"Laporan Denda" ditambahkan hasil review Flowchart System asli skripsi — rekap seluruh denda keterlambatan pengembalian.

### 3.12 Pengaturan Denda (dari grid Dashboard)

<img width="742" height="1612" alt="Penganturan-Denda" src="https://github.com/user-attachments/assets/b1455add-4dfb-4fe3-861f-551d168da4b5" />

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
<img width="710" height="1542" alt="Tampilan-Login" src="https://github.com/user-attachments/assets/b41804f2-35b1-40fb-9e01-e6ce0e923d7e" />

### 5.2 Dashboard Laboran 
<img width="710" height="1542" alt="Dashboard-Laboran + Akses Cepat" src="https://github.com/user-attachments/assets/1a6630f4-615b-4626-9514-83821da5b63f" />



### 5.3 Transaksi — Peminjaman (segmented control)

<img width="742" height="1612" alt="Peminjaman" src="https://github.com/user-attachments/assets/3c231398-c9ac-484b-aaa6-cb23e8e5a712" />

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

<img width="742" height="1612" alt="Verifikasi-Peminjaman" src="https://github.com/user-attachments/assets/e90ddce2-c406-4621-ad4a-666779d1a899" />


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
