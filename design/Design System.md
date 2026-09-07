# **Design System Specification: Hyper-Minimal Utility**

> **Kategori:** Design System & UI Tokens

> **Gaya Desain:** Clean Modern Utility, Bento Grid, High-Contrast Electric Accent, Super-Rounded (iOS/Fintech Aesthetic).

> **Tujuan:** Panduan baku standarisasi visual, komponen, dan token desain.

## **1\. Design Principles**

1. **Glanceable Hierarchy (Hirarki Instan):**  
   * Informasi kuantitatif dan status utama harus dapat dibaca dalam kurun waktu \< 1 detik.  
   * Metrik numerik menggunakan bobot *Heavy/Black*, dipadukan label berwarna kontras rendah (*muted neutral*).  
2. **Card-Centric & Bento Modularity:**  
   * Seluruh konten dikelompokkan ke dalam unit kartu (*containers*) independen.  
   * Tidak ada garis pemisah kaku (*hard dividers*); pembagian konten mengandalkan batas permukaan kartu (*card boundary*) dan spasi (*whitespace*).  
3. **Intentional Saturation (Aksen Fokal Kuat):**  
   * Permukaan kanvas dan kartu didominasi palet netral (putih, abu-abu sangat muda).  
   * Warna jenuh (*Electric Blue*) digunakan secara selektif khusus untuk penarik fokus utama (*hero card*, *primary trigger*, dan *peak metrics*).  
4. **Soft-Edge Architecture (Super-Rounded Surfaces):**  
   * Menerapkan radius kelengkungan besar (*high corner radius*) dari 16px hingga 32px untuk menciptakan kesan modern, ergonomis, dan ramah sentuhan (*touch-friendly*).

## **2\. Color System & Tokens**

### **2.1 Core Brand (Electric Blue Series)**

Digunakan sebagai jangkar visual utama, elemen terpilih, grafik aktif, dan tombol penanda tindakan penting.

| Token Name | HEX | RGB | Penggunaan Utama |
| :---- | :---- | :---- | :---- |
| color-brand-primary | \#1622E5 | 22, 34, 229 | Kartu hero utama, tombol primer, titik aktif grafik |
| color-brand-hover | \#0C16B6 | 12, 22, 182 | Status *hover* / *pressed* pada komponen primer |
| color-brand-surface-tint | \#EBF1FE | 235, 241, 254 | Latar belakang kontainer ikon, track progress bar |
| color-brand-border-tint | \#BED3FF | 190, 211, 255 | Garis sekunder grafik tren, subtle active ring |
| color-brand-subtle | \#84ABFF | 132, 171, 255 | Label pendukung pada permukaan gelap, track sekunder |

### **2.2 Semantic & Status Tokens**

Digunakan untuk indikator status unit, peringatan ketersediaan, dan verifikasi kondisi.

| Token Name | HEX | Semantic Meaning | Penggunaan |
| :---- | :---- | :---- | :---- |
| color-status-success | \#10B981 | Normal / Operasional / Selesai | Badge status normal, dot aktif operasional |
| color-status-warning | \#F59E0B | Perhatian / Jadwal Dekat | Indikator butuh pengecekan, buffer stok menipis |
| color-status-danger | \#EF4444 | Kerusakan / Rusak / Kritis | Label peringatan darurat, penolakan permintaan |
| color-status-info | \#3B82F6 | Informasi Tambahan | Catatan status tertunda (*pending notification*) |

### **2.3 Neutral & Surface Tokens**

Struktur hierarki latar belakang untuk menciptakan kedalaman (*elevation layering*).

| Token Name | HEX | Peran UI | Keterangan |
| :---- | :---- | :---- | :---- |
| surface-canvas | \#F8F9FA | Latar belakang aplikasi | Abu-abu netral sangat terang (menghindari kelelahan mata) |
| surface-card-base | \#FFFFFF | Permukaan kartu layer 1 | Putih solid dengan border 1px |
| surface-card-subtle | \#F4F6F9 | Kartu sekunder / stack layer 2 | Memberi efek tumpukan di belakang kartu utama |
| surface-pill-inactive | \#F1F3F7 | Latar chip tidak aktif / track bar | Digunakan untuk kontainer pembungkus non-aktif |
| text-primary | \#111217 | Kontras utama (High Emphasis) | Nilai angka metrik besar, judul header, nama aset |
| text-secondary | \#374151 | Keterangan (Medium Emphasis) | Teks isi, deskripsi spesifikasi, label aktif |
| text-muted | \#8E93A4 | Keterangan pembantu (Low Emphasis) | Subjudul, satuan metrik, placeholder input |
| border-subtle | \#F0F1F5 | Pembatas kontur halus | Garis batas 1px pada seluruh kartu putih |

## **3\. Typography System**

**Rekomendasi Font Family:**

1. Plus Jakarta Sans (Prioritas Utama — geometric clean)  
2. Inter / SF Pro Display (Alternatif fallback)

### **3.1 Type Scale & Hierarchy**

| Role / Token | Size | Weight | Line Height | Letter Spacing | Kasus Penggunaan |
| :---- | :---- | :---- | :---- | :---- | :---- |
| display-number | 36px / 2.25rem | 900 (Black) | 1.1 | \-0.03em | Nominal kuantitas utama, total metrik kartu hero |
| title-screen | 24px / 1.5rem | 800 (Bold) | 1.2 | \-0.02em | Judul halaman/layar utama |
| title-section | 14px / 0.875rem | 700 (Bold) | 1.3 | \-0.01em | Judul grup Bento, sub-bagian (*Section Header*) |
| metric-card-val | 16px / 1rem | 800 (Bold) | 1.25 | \-0.01em | Nilai angka pada kartu statistik ringkas |
| body-medium | 13px / 0.8125rem | 500 (Medium) | 1.4 | 0 | Notifikasi ringkas, deskripsi status |
| caption-label | 11px / 0.6875rem | 500 (Medium) | 1.2 | \+0.01em | Label metrik penjelas (di atas/bawah angka) |
| badge-micro | 10px / 0.625rem | 700 (Bold) | 1.0 | \+0.02em | Label status mini (*Caps/Pill tags*, peak tooltip) |

## **4\. Spacing, Corner Radius & Shadows**

### **4.1 Spacing Scale (4px Base Grid)**

* space-1 \= 4px  
* space-2 \= 8px (Jarak antar elemen mikro: teks ke ikon kecil)  
* space-3 \= 12px (Padding internal tombol / kartu ringkas)  
* space-4 \= 16px (Padding standar kartu bento reguler)  
* space-5 \= 20px (Padding kartu besar / hero container)  
* space-6 \= 24px (Jarak vertikal antar section)  
* space-8 \= 32px (Margin layout / jarak blok besar)

### **4.2 Corner Radius Scale**

Sistem kelengkungan sudut dirancang konsisten bertingkat:

| Token Name | Nilai | Implementasi |
| :---- | :---- | :---- |
| radius-sm | 8px | Badge tag kecil, check indicator |
| radius-md | 12px | Input control, chip status, tombol reguler |
| radius-lg | 16px | Kartu baris riwayat/aktivitas, banner info |
| radius-xl | 24px | Kartu bento 2x2, kartu statistik ringkas |
| radius-2xl | 32px | Kartu hero utama, kartu tumpukan (*stacked deck*) |
| radius-full | 9999px | Tombol bulat aksi (Quick Action), pill progress, avatar bulat |

### **4.3 Elevation & Ambient Shadows**

Hindari bayangan hitam legam (*muddy shadow*). Gunakan bayangan berlapis yang sangat transparan:

/\* 1\. Subtle Ambient (Kartu putih standar) \*/  
box-shadow:   
  0 4px 20px \-2px rgba(17, 18, 23, 0.03),  
  0 2px 6px \-1px rgba(17, 18, 23, 0.02);

/\* 2\. Focused Lift (Kartu saat hover atau ditekan) \*/  
box-shadow:   
  0 10px 28px \-4px rgba(17, 18, 23, 0.06),  
  0 4px 10px \-2px rgba(17, 18, 23, 0.03);

/\* 3\. Electric Saturated Glow (Khusus untuk permukaan Brand Blue) \*/  
box-shadow:   
  0 16px 36px \-6px rgba(22, 34, 229, 0.35);

## **5\. Component Specifications & Anatomy**

### **5.1 Dual-Action Header Control**

Pola kontrol sudut kanan atas pada setiap header layar:

* **Button A (Add / Action Utama):**  
  * Bentuk: Lingkaran penuh 40x40px (radius-full).  
  * Latar: \#111217 (Hitam pekat solid).  
  * Ikon: Tanda tambah (+) warna putih, garis 2.5px.  
* **Button B (Open / Navigate / Export):**  
  * Bentuk: Lingkaran penuh 40x40px (radius-full).  
  * Latar: \#FFFFFF dengan border tipis 1px \#F0F1F5.  
  * Ikon: Panah diagonal serong (↗) warna \#111217, garis 2px.  
* **Spasi Antar Tombol:** 8px gap horizontal.

### **5.2 Bento Grid Cards (2x2 Structure)**

Spesifikasi untuk kartu modular penampil ringkasan:

* **Ukuran & Padding:** Min-height fleksibel, padding seragam 16px, radius 24px.  
* **Icon Container:**  
  * Bentuk: Kotak sudut membulat (radius-md / 12px s/d 16px) atau lingkaran.  
  * Ukuran: 36x36px atau 40x40px.  
  * Varian Warna: Pastel tint (\#EBF1FE dengan ikon biru) atau Dark/Brand solid.  
* **Urutan Konten:**  
  1. Ikon / Indikator grafis (Atas).  
  2. Judul / Teks metrik tebal (Tengah).  
  3. Keterangan status abu-abu kecil (Bawah).

### **5.3 Stacked Card Deck (Visual Hierarchy Tumpukan)**

Untuk menampilkan entitas data primer yang memiliki level prioritas:

* **Layer 3 (Kartu Paling Belakang):** Warna netral mendekati putih (\#F8FAFF), border 1px sangat lembut, offset vertikal ke atas.  
* **Layer 2 (Kartu Tengah):** Warna tinted pastel (\#C9E0FF), teks semi-kontras, sedikit mengintip di atas layer 1\.  
* **Layer 1 (Kartu Depan / Fokus):**  
  * Latar: color-brand-primary (\#1622E5).  
  * Teks: Putih bersih (\#FFFFFF).  
  * Radius: 32px.  
  * Bayangan: Electric Saturated Glow.  
  * Struktur isi: Nama/Identitas (atas), Angka Utama (tengah \- ukuran display 36px), Status/Pill informasi (bawah).

### **5.4 Checkpoint Progress Bar**

Progress bar berjenjang untuk pemantauan target/tahapan:

* **Tinggi Track:** 10px s/d 12px.  
* **Radius:** Penuh (radius-full).  
* **Warna Track Latar:** Biru pastel lembut (\#EBF1FE).  
* **Warna Track Aktif:** Biru solid (\#BED3FF atau \#1622E5).  
* **Marker / Checkpoint Nodes:**  
  * Lingkaran berdiameter 6px.  
  * Diletakkan pada persentase tertentu (misal: 25%, 50%, 75%).  
  * Warna: \#1622E5 saat tercapai, atau putih dengan bayangan saat posisi akhir.

### **5.5 Floating Pill Banner**

Banner penegas pencapaian atau peringatan di dalam kartu:

* **Tinggi / Padding:** Padding vertikal 12px, horizontal 16px.  
* **Radius:** 16px.  
* **Warna:** Solid color-brand-primary atau variasi status.  
* **Isi:** Teks pesan tebal di kiri \+ badge mini / emoji / tag interaktif di kanan dalam kapsul rgba(255, 255, 255, 0.2).

### **5.6 Data Viz Sparkline & Tooltip Marker**

Standar garis grafik tren minimalis:

* **Garis Latar:** Dashed line 1px \#F1F3F7 untuk panduan horizontal (gridline).  
* **Garis Sekunder:** Stroke 2px \#BED3FF (garis tren komparatif/periode sebelumnya).  
* **Garis Primer:** Stroke 2.5px solid \#1622E5 dengan sudut sambungan melengkung halus (*round join*).  
* **Peak Indicator Tag:**  
  * Garis penanda vertikal putus-putus (*dashed line*) mengarah ke titik tertinggi.  
  * Label pill melayang di atas titik: Kapsul biru \#1622E5 berisi teks tebal putih 10px (*e.g.*, 6.85t / nilai kuantitas puncak).

## **6\. Iconography & Media Guidelines**

1. **Gaya Ikon (Icon Style):**  
   * Garis (*Line/Outline*) dengan ketebalan konsisten **2.0px** atau **2.2px**.  
   * Sudut ujung garis berbentuk bulat (*stroke-linecap="round"*, *stroke-linejoin="round"*).  
   * Bentuk geometri proporsional dalam bounding-box 24x24px.  
2. **Avatar / Inisial Entitas:**  
   * Bentuk lingkaran 40x40px (radius-full).  
   * Latar: Abu-abu netral \#F3F4F6 dengan teks inisial 2 huruf tebal 12px \#4B5563.

## **7\. Interaction States**

| State | Perilaku Kartu Standar | Perilaku Tombol Primer | Perilaku Tombol Header Bulat |
| :---- | :---- | :---- | :---- |
| **Default** | Border 1px \#F0F1F5, bayangan subtle ambient | Background \#1622E5, teks putih | Background \#000 / \#FFF, border subtle |
| **Hover** | Transform translateY(-2px), bayangan lift naik | Background \#0C16B6 | Background menjadi lebih gelap / abu-abu muda |
| **Active / Pressed** | Transform scale(0.99) | Transform scale(0.97) | Transform scale(0.92) |
| **Focus-Visible** | Ring outline 2px \#1622E5 dengan offset 2px | Ring outline 2px \#1622E5 dengan offset 2px | Ring outline 2px \#111217 |

