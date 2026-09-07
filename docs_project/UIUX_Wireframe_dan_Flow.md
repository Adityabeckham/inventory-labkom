# UI/UX Wireframe & User Flow
## Sistem Inventory Laboratorium Komputer Berbasis Mobile — "Inventory Labkom"

| | |
|---|---|
| **Versi** | 1.5 (Final — hasil review Flowchart/Use Case/Activity/Sequence Diagram skripsi asli) |
| **Rujukan** | PRD v1.4, Database_Final_dan_Arsitektur.md v1.3, `DESIGN.md` (design system resmi klien) |

> Struktur layar & flow mengikuti mockup asli skripsi (Gambar 3.19–3.25). Gaya visual (warna, tipografi, shape, elevation, komponen) sekarang mengikuti **`DESIGN.md`** yang disediakan klien — klien konfirmasi warna boleh beda dari mockup skripsi. Navigasi memakai struktur **hybrid**: Bottom Navigation Bar untuk 4 menu utama + Dashboard grid untuk fitur sekunder.

---

## 1. Struktur Navigasi (Hybrid — dikonfirmasi klien)

### Laboran — Bottom Navigation Bar (5 tab)
| Tab | Isi |
|---|---|
| **Dashboard** | Ringkasan + grid akses fitur sekunder: Kategori, Kelola User, Data Peminjam, Pengaturan Denda |
| **Aset Lab** | Segmented control internal "Daftar Barang \| Mutasi Stok" — Daftar Barang (list, tambah, ubah, hapus); Mutasi Stok (riwayat + catat mutasi masuk/keluar, FR-13) |
| **Transaksi** | Segmented control internal "Peminjaman \| Pengembalian" (masing-masing dengan filter tab status sendiri) |
| **Laporan** | 5 jenis laporan |
| **Settings** | Edit Profile, Ubah Password, Logout |

**FAB (Floating Action Button)**: shortcut global **"+ Peminjaman Baru"**, muncul di atas Bottom Nav pada tab Dashboard & Transaksi. Warna Crimson Red (`#D8232A`) sesuai DESIGN.md, ikon "+" polos (bukan barcode scanner — barcode scanning tetap di luar scope Fase 1). Didesain future-proof: kalau fase 2 menambah fitur scan barcode, FAB bisa diperluas jadi Extended/Speed-dial FAB dengan 2 opsi ("Scan Barcode" & "Tambah Manual") tanpa mengubah struktur navigasi.

### Kepala Program — Bottom Navigation Bar (4 tab)
| Tab | Isi |
|---|---|
| **Dashboard** | Ringkasan pengawasan |
| **Verifikasi** | Daftar pengajuan `menunggu_verifikasi` → Setuju/Tolak |
| **Laporan** | Read-only, 5 jenis sama seperti Laboran |
| **Settings** | Edit Profile, Ubah Password, Logout |

> Menu Verifikasi **tidak** muncul di Bottom Nav Laboran — kalau Laboran perlu lihat status pengajuan, aksesnya lewat grid Dashboard (read-only, tanpa tombol approve/reject; otorisasi tetap ditegakkan di backend).

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
9. Laporan (4 jenis)
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
[Splash: logo "INVENTORY LABKOM"] → [Form Login]
   Username, Password (toggle show/hide)
   ☐ Ingat saya          Lupa Password?
        │
        ▼
   Tombol "Masuk" (Deep Navy, full-width, 48px height, radius 12px)
        │
   ┌────┴────┐
   ▼         ▼
 Sukses    Gagal → pesan error, tetap di form
   │
   ▼
"Ingat saya" dicentang → refresh token disimpan lebih lama
   │
   ▼
Redirect sesuai role → Dashboard Laboran (Bottom Nav 5 tab) /
                        Dashboard Kepala Program (Bottom Nav 4 tab)

[Lupa Password?] → instruksi: "Hubungi Laboran/Admin untuk reset password
akun Anda" (reset manual lewat menu Kelola User)
```

### 3.2 Dashboard (tab pertama di Bottom Nav)
```
[App bar Deep Navy #384C9D, sudut bawah melengkung 24px]
  "Dashboard" + "Halo Laboran, Selamat Datang Kembali"
[Search bar "Cari Produk"]
[Grid 2x2 — fitur sekunder]: Kategori | Kelola User
                              Data Peminjam | Pengaturan Denda
[Ringkasan angka]: Total Barang, Sedang Dipinjam, Perlu Verifikasi
[FAB "+ Peminjaman Baru" mengambang kanan bawah, warna Crimson #D8232A]
[Bottom Nav]: Dashboard(aktif) | Aset Lab | Transaksi | Laporan
```
Dashboard Kepala Program: app bar sama, tanpa grid sekunder (karena tidak ada fitur kelola), langsung ringkasan pengajuan menunggu + Bottom Nav 3 tab.

### 3.3 Aset Lab — Segmented Control (Daftar Barang | Mutasi Stok)
```
Bottom Nav → [Aset Lab] → Segmented Control: [Daftar Barang] | Mutasi Stok
   Search bar "Cari nama barang...."
   Filter chip kategori (pill): Semua | Komputer | Jaringan | Elektronik
   Tombol "+ Tambah Barang" (full-width, atau via FAB kontekstual di tab ini)
        │
        ▼
   List card: nama barang (title-md), kode & stok (body-sm, #64748B),
   badge status pill kanan (Nominal/In-Service hijau = "Tersedia")
        │
        ▼
   Tap → Detail/Edit Barang → Simpan / Hapus (konfirmasi dialog)
```

### 3.3b Aset Lab — Mutasi Stok (BARU, FR-13, hasil review Flowchart System asli)
```
Bottom Nav → [Aset Lab] → Segmented Control: Daftar Barang | [Mutasi Stok]
   Tombol "+ Catat Mutasi"
        │
        ▼
   Form: pilih Barang, jenis (toggle Masuk/Keluar), jumlah, keterangan
   (contoh: "Pengadaan APBD 2026" / "Rusak — dibuang"), tanggal → Simpan
        │
        ▼
   Sistem: update `barang.stok` otomatis (+jumlah masuk / -jumlah keluar,
   validasi tidak boleh negatif) + catat ke riwayat
        │
        ▼
   Riwayat Mutasi — list: nama barang, jenis (badge hijau Masuk / merah
   Keluar), jumlah, keterangan, tanggal, siapa yang mencatat
```
Fitur ini **terpisah** dari perubahan stok akibat transaksi Peminjaman/Pengembalian — khusus penyesuaian manual (barang baru datang, rusak, hilang, dll), sesuai Flowchart System asli skripsi yang memisahkan menu "Kelola Stok Barang" dari "Kelola Barang".

### 3.4 Kategori (dari grid Dashboard)
```
Dashboard → [Kategori] → List kategori → (+) Tambah Kategori (nama_kategori)
```

### 3.5 Kelola User (dari grid Dashboard)
```
Dashboard → [Kelola User]
   List akun: username, badge level (Laboran = navy tint / Kepala Program =
   gold tint), ikon edit & hapus
        │
        ▼
   (+) Tambah User → form: username, password, level (dropdown) → Simpan
```

### 3.6 Data Peminjam (dari grid Dashboard) — tampilan tabel
```
Dashboard → [Data Peminjam]
   Search bar + tombol "+ Tambah Peminjam"
        │
        ▼
   Tabel: No | Nama Peminjam | NIS/NIP | Kelas/Jabatan | No. HP | Aksi
        │
        ▼
   Form tambah/edit: Nama, NIS/NIP, Kelas/Jabatan, No. HP → Simpan
```

### 3.7 Transaksi — Peminjaman (segmented control kiri)
```
Bottom Nav → [Transaksi] → Segmented Control: [Peminjaman] | Pengembalian
   Search bar "Cari peminjaman....'
   Filter chip: Semua | Menunggu Verifikasi* | Dipinjam | Dikembalikan | Dibatalkan
   (*tab tambahan — dikonfirmasi klien, di luar 3 status dasar mockup asli)
        │
        ▼
   List card: kode PMJ-2026-001, badge status pill kanan atas, nama peminjam,
   tgl pinjam, jatuh tempo
        │
        ▼
   FAB "+ Peminjaman Baru" → form multi-item (lihat §3.8)
```

### 3.8 Peminjaman Baru — Multi-Item (dibuka dari FAB)
```
Pilih Peminjam (cari/tambah baru)
     │
     ▼
[Keranjang Barang] — tambah barang satu per satu (cari, pilih, isi jumlah),
     ulangi untuk barang berikutnya
     │
     ▼
Tanggal Pinjam & Jatuh Tempo
     │
     ▼
Review → Simpan
     │
     ▼
Sistem: buat header `peminjaman` (status = menunggu_verifikasi, kode
PMJ-otomatis) + N baris `peminjaman_detail` + kurangi stok tiap barang
```

### 3.9 Transaksi — Pengembalian (segmented control kanan)
```
Bottom Nav → [Transaksi] → Segmented Control: Peminjaman | [Pengembalian]
   Search bar "Cari pengembalian...."
   Filter chip: Semua | Belum Kembali | Sebagian Kembali* | Sudah Kembali | Terlambat
   (*tab tambahan — dikonfirmasi klien)
        │
        ▼
   List card (per PMJ-code) → tap → Detail Pengembalian (status per-item:
   ✅ Sudah kembali / ⏳ Masih dipinjam)
        │
        ▼
   Tap salah satu barang → Form Pengembalian: tanggal, kondisi (toggle
   Baik/Rusak), info denda otomatis (read-only) → Konfirmasi
```

### 3.10 Verifikasi Peminjaman (Kepala Program)
```
Bottom Nav → [Verifikasi]
   List pengajuan menunggu_verifikasi (peminjam, laboran pencatat, jumlah
   barang, waktu pengajuan)
        │
        ▼
   Tap → Detail Pengajuan (daftar barang, tanggal pinjam & jatuh tempo)
        │
        ▼
   ┌─────────┴─────────┐
   ▼                   ▼
 Setujui            Tolak (isi Alasan Dibatalkan)
   │                   │
   ▼                   ▼
status → dipinjam   status → dibatalkan
                     + stok semua barang di transaksi ini
                       OTOMATIS dikembalikan
```

### 3.11 Laporan (5 jenis)
```
Bottom Nav → [Laporan]
   Banner Deep Navy: "Laporan Inventaris — Buat dan cetak laporan data
   barang sesuai kebutuhan"
   5 card: Laporan Data Barang | Laporan Peminjaman | Laporan Pengembalian
   | Laporan Stok Barang | Laporan Denda
        │
        ▼
   Tap → filter tanggal (opsional) → pilih format **PDF / Word / Excel** → Export & Unduh
```
Laboran: generate & unduh. Kepala Program: read-only, label "Mode Lihat Saja".
"Laporan Denda" ditambahkan hasil review Flowchart System asli skripsi — rekap seluruh denda keterlambatan pengembalian.

### 3.12 Pengaturan Denda (dari grid Dashboard)
```
Dashboard → [Pengaturan Denda] → input Tarif Denda per Hari (Rp) → Simpan
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
<img width="1024" height="2322" alt="LOGIN-Laboran" src="https://github.com/user-attachments/assets/dc1aebb7-e322-4d24-aaf9-c08b7b587d18" />

### 5.2 Dashboard Laboran (dengan Bottom Nav + FAB)
<img width="390" height="1447" alt="2 2 Dashboard Laboran" src="https://github.com/user-attachments/assets/9ea70120-e18b-4a97-89f9-7ae39e084210" />


### 5.3 Transaksi — Peminjaman (segmented control)
```
┌─────────────────────────────┐
│ ←   Transaksi                  │
├─────────────────────────────┤
│ [ Peminjaman ][ Pengembalian ] │ ← segmented control, aktif = putih+shadow
│ 🔍 Cari peminjaman....          │
│ [Semua][Menunggu][Dipinjam]    │
│ [Dikembalikan][Dibatalkan]     │
├─────────────────────────────┤
│ PMJ-2026-001      🟡 Dipinjam  │
│ Ahmad — Tgl Pinjam 04 Mei      │
│ Jatuh Tempo: 09 Mei             │
├─────────────────────────────┤
│ PMJ-2026-002    ⚪ Menunggu     │
│ Sari — Tgl Pinjam 05 Mei        │
│                          ⊕FAB  │
├─────────────────────────────┤
│ [Dashboard][Aset Lab][Transaksi][Laporan] │
└─────────────────────────────┘
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
┌─────────────────────────────┐
│ ← Detail Pengajuan            │
├─────────────────────────────┤
│ Peminjam: Ahmad                │
│ Dicatat oleh: Laboran Rina     │
│ Jatuh Tempo: 09 Mei 2026       │
│ 3 barang — lihat detail ▾     │
├─────────────────────────────┤
│  [Tolak, outline merah]        │
│  [Setujui, navy solid]         │
├─────────────────────────────┤
│ [Dashboard][Verifikasi][Laporan] │ ← Bottom Nav 3 tab
└─────────────────────────────┘
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
Lanjut ke **Sprint Planning / Task Breakdown** — pecah FR-01 s/d FR-12 jadi task teknis per sprint dengan estimasi.
