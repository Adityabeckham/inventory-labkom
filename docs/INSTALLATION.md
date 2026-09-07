# Panduan Instalasi — Inventory Labkom

Panduan menyiapkan lingkungan pengembangan dari nol.

---

## 1. Prasyarat

| Kebutuhan | Versi | Untuk |
|---|---|---|
| **XAMPP** | PHP 8.1+ / MariaDB 10.4+ | Backend & database |
| **Flutter SDK** | 3.x (stable) | Aplikasi mobile |
| **Android Studio** | terbaru | Android SDK, emulator, build APK |
| **Git** | mana saja | Version control |
| **Composer** | 2.x | Library laporan (mPDF, PHPWord, PhpSpreadsheet) |

> Backend butuh PHP **8.1 ke atas** — kode memakai `readonly` properties (`core/Request.php`) dan tipe kembalian `never` (`core/Response.php`, `core/Router.php`), keduanya fitur 8.1. XAMPP versi lama dengan PHP 7.x atau 8.0 tidak akan jalan.
>
> Composer hanya dibutuhkan fitur **Laporan** (FR-08/FR-09). Seluruh endpoint lain — autentikasi, barang, peminjaman, pengembalian — jalan tanpanya. Kalau `composer install` belum dijalankan, `/api/laporan/*` membalas pesan yang menyebut paket mana yang belum ada, bukan "Class not found".
>
> Ekstensi PHP yang dibutuhkan library laporan: **mbstring**, **gd**, **zip**, dan **dom**. Semuanya sudah aktif di XAMPP bawaan; kalau salah satu mati, kegagalannya muncul di dalam library dengan pesan yang sulit dilacak. Periksa dengan `php -m`.

---

## 2. Clone Repository

```bash
git clone https://github.com/Adityabeckham/inventory-labkom.git
cd inventory-labkom
```

---

## 3. Setup Database

Jalankan MySQL lewat XAMPP Control Panel, lalu dari **folder root repository**:

```bash
mysql -u root < database/schema.sql
mysql -u root < database/seed.sql
```

> **`schema.sql` menghapus data.** File ini memulai tiap tabel dengan `DROP TABLE IF EXISTS`, dan `seed.sql` menjalankan `TRUNCATE`. Aman dijalankan berulang saat development, tapi kalau database `inventory_labkom` sudah berisi data sungguhan, keduanya akan menghapusnya tanpa konfirmasi. Backup dulu.

Kalau lebih nyaman lewat phpMyAdmin (`http://localhost/phpmyadmin`): buka tab **Import**, unggah `database/schema.sql` dulu, baru `database/seed.sql`.

Setelah berhasil akan ada database `inventory_labkom` dengan 9 tabel dan data awal.

### Akun bawaan

| Username | Password | Level | Peran |
|---|---|---|---|
| `laboran` | `laboran123` | `admin` | Laboran |
| `kaprog` | `kaprog123` | `super_admin` | Kepala Program |

> Password ini **hanya untuk development**. Ganti lewat menu Kelola User sebelum aplikasi dipakai sungguhan.

---

## 4. Setup Backend

```bash
cp backend/config/config.example.php backend/config/config.php
```

Buka `backend/config/config.php`, lalu isi minimal dua hal:
1. Kredensial database (`db.username`, `db.password`) — XAMPP default: user `root`, password kosong.
2. `jwt.secret` — **wajib diganti**. Generate string acak:

   ```bash
   php -r "echo bin2hex(random_bytes(32));"
   ```

Detail tiap opsi ada di [CONFIGURATION.md](CONFIGURATION.md).

### Library laporan

```bash
composer install -d backend
```

Mengunduh mPDF, PHPWord, dan PhpSpreadsheet ke `backend/vendor/` (sekitar 100 MB, tidak ikut di repository). Lewati langkah ini kalau fitur Laporan belum diperlukan — endpoint lain tetap berfungsi.

`composer.json` mematok platform ke PHP 8.1.0, jadi versi library yang di-resolve tetap sesuai target minimum di atas walaupun mesin Anda memakai PHP yang lebih baru.

### Jalankan backend

**Opsi A — server bawaan PHP (paling cepat untuk development):**

```bash
php -S localhost:8080 -t backend/public
```

**Opsi B — lewat Apache XAMPP:** arahkan DocumentRoot/VirtualHost, atau buat Alias, ke folder `backend/public`. Pastikan `mod_rewrite` aktif dan direktorinya `AllowOverride All` (keduanya dibutuhkan `public/.htaccess`).

Deploy di sub-path juga didukung — router membuang prefix pemasangan secara otomatis, jadi `Alias /inventory` membuat endpoint tersedia di `http://localhost/inventory/api/health` tanpa perlu mengubah kode.

### Verifikasi

```bash
curl http://localhost:8080/api/health
```

Balasan yang benar:

```json
{
  "status": "success",
  "message": "API aktif.",
  "data": {
    "app": "Inventory Labkom API",
    "database": "connected",
    "time": "2026-09-07T10:00:00+07:00",
    "env": "development",
    "php": "8.1.x"
  }
}
```

`env` dan `php` hanya muncul saat `app.debug` bernilai `true` — endpoint ini terbuka tanpa autentikasi, jadi detail lingkungan sengaja disembunyikan di production.

Kalau `database` berisi `"disconnected"`, kredensial di `config.php` belum cocok atau MySQL belum jalan. Pesan error aslinya ada di log PHP, bukan di respons.

---

## 5. Setup Aplikasi Flutter

> Bagian ini menunggu Sprint 0 tuntas — project Flutter di `mobile/` belum dibuat.

Setelah Flutter SDK terpasang:

```bash
flutter doctor          # pastikan tidak ada masalah Android toolchain
cd mobile
flutter pub get
flutter run
```

### Alamat backend dari perangkat

`localhost` di emulator/HP menunjuk ke perangkat itu sendiri, bukan ke komputer Anda:

| Menjalankan di | Alamat backend |
|---|---|
| Emulator Android | `http://10.0.2.2:8080` |
| HP fisik (satu WiFi) | `http://<IP-komputer>:8080`, mis. `http://192.168.1.10:8080` |

---

## 6. Masalah Umum

Semua endpoint membalas JSON, termasuk saat gagal. Pesan yang dikirim ke klien sengaja tidak detail — **penyebab sebenarnya selalu ada di log error PHP** (XAMPP: `xampp/apache/logs/error_log`; server bawaan PHP: keluaran terminal). Cari baris berawalan `[inventory-labkom]`.

| Gejala | Penyebab & solusi |
|---|---|
| Semua endpoint balas HTTP 500 `Terjadi kesalahan pada server.` | Cek log. Tiga penyebab paling umum: `config.php` belum disalin dari `config.example.php`, `jwt.secret` masih placeholder (backend sengaja menolak jalan), atau file config-nya rusak sintaks. |
| `"database": "disconnected"` di `/api/health` | MySQL belum jalan, kredensial di `config.php` salah, atau database `inventory_labkom` belum di-import. Set `app.debug` ke `true` untuk melihat pesan PDO aslinya. |
| `Access denied` padahal user & password benar | Kalau MySQL-nya bukan XAMPP (mis. MariaDB dari Homebrew), akun `root` sering memakai autentikasi `unix_socket` yang hanya bekerja lewat soket lokal — sedangkan `db.host` di config memakai `127.0.0.1`, yang memaksa koneksi TCP. Buat user berpassword: `CREATE USER 'labkom'@'127.0.0.1' IDENTIFIED BY '...'; GRANT ALL ON inventory_labkom.* TO 'labkom'@'127.0.0.1';` |
| Semua endpoint balas 404 | `mod_rewrite` Apache belum aktif, atau direktorinya belum `AllowOverride All` sehingga `public/.htaccess` diabaikan. Deploy di sub-path sendiri sudah didukung dan bukan penyebab 404. |
| Login selalu 401 padahal password benar | Apache memotong header `Authorization`. Pastikan blok `RewriteCond %{HTTP:Authorization}` di `public/.htaccess` ikut terbaca (`AllowOverride All`). |
| HP fisik tidak bisa konek | Firewall komputer memblokir port 8080, atau HP dan komputer beda jaringan. |
