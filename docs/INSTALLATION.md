# Panduan Instalasi — Inventory Labkom

Panduan lengkap menyiapkan lingkungan pengembangan dari nol di laptop lokal, mulai dari instalasi PHP/XAMPP, Composer, Flutter SDK, hingga database dan aplikasi.

---

## 1. Prasyarat & Perangkat Lunak Utama

Jika laptop Anda belum memiliki perangkat lunak pendukung, lakukan instalasi sesuai daftar berikut:

| Perangkat Lunak | Versi Minimum | Fungsi / Untuk | Link Download Resmi |
|---|---|---|---|
| **XAMPP / PHP** | PHP 8.1+ & MariaDB 10.4+ | Server Backend & Database MySQL | [apachefriends.org](https://www.apachefriends.org) |
| **Composer** | 2.x | Dependency Manager PHP (Library Laporan) | [getcomposer.org](https://getcomposer.org) |
| **Flutter SDK** | 3.x (stable) | Framework Aplikasi Mobile | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| **Android Studio** | Terbaru | Android SDK, Emulator, Build APK | [developer.android.com](https://developer.android.com/studio) |
| **Git** | 2.x+ | Version Control System | [git-scm.com](https://git-scm.com) |

---

## 2. Langkah Instalasi Tools (Jika Belum Ada di Laptop)

### 2.1 Instalasi XAMPP & Konfigurasi PHP 8.1+
1. Unduh installer **XAMPP for Windows** dengan PHP 8.1 ke atas dari [Apache Friends](https://www.apachefriends.org).
2. Jalankan installer dan selesaikan proses instalasi (default: `C:\xampp`).
3. **Tambahkan PHP & MySQL ke Environment Variable (PATH)**:
   - Buka *System Properties* → *Environment Variables*.
   - Pada *System Variables*, edit `Path` lalu tambahkan: `C:\xampp\php` dan `C:\xampp\mysql\bin`.
4. **Aktifkan Ekstensi PHP di `php.ini`**:
   - Buka file `C:\xampp\php\php.ini` menggunakan text editor.
   - Pastikan baris ekstensi berikut tidak diawali tanda koma titik `;` (jika ada `;`, hapus tanda tersebut):
     ```ini
     extension=gd
     extension=zip
     extension=mbstring
     extension=pdo_mysql
     ```
   - Simpan file `php.ini`.

### 2.2 Instalasi Composer
1. Unduh dan jalankan **`Composer-Setup.exe`** dari [getcomposer.org](https://getcomposer.org).
2. Saat installer meminta lokasi `php.exe`, arahkan ke `C:\xampp\php\php.exe`.
3. Selesaikan instalasi. Buka terminal baru dan ketik `composer --version` untuk memastikan Composer aktif.

### 2.3 Instalasi Flutter SDK & Android Studio
1. Unduh paket **Flutter SDK** (zip) untuk Windows dari [docs.flutter.dev](https://docs.flutter.dev/get-started/install).
2. Ekstrak file zip tersebut ke folder lokal, contohnya: `C:\src\flutter`. (Jangan ekstrak di `Program Files` untuk menghindari masalah hak akses).
3. **Tambahkan Flutter ke PATH**:
   - Edit `Path` di Environment Variables, lalu tambahkan: `C:\src\flutter\bin`.
4. Install **Android Studio**:
   - Unduh dan install Android Studio.
   - Buka Android Studio → *More Actions* → *SDK Manager* → *SDK Tools*.
   - Centang **Android SDK Build-Tools** dan **Android SDK Command-line Tools (latest)**, lalu klik *Apply* untuk menginstall.
5. **Verifikasi Instalasi**:
   - Buka Command Prompt / PowerShell baru, lalu jalankan:
     ```bash
     flutter doctor
     ```
   - Pastikan Flutter SDK dan Android Toolchain sudah berstatus centang hijau (jika ada lisensi Android yang belum disetujui, jalankan `flutter doctor --android-licenses`).

---

## 3. Clone Repository

Buka terminal dan clone repository dari GitHub:

```bash
git clone https://github.com/Adityabeckham/inventory-labkom.git
cd inventory-labkom
```

---

## 4. Setup Database MySQL

1. Buka **XAMPP Control Panel** lalu jalankan service **MySQL**.
2. Dari root direktori proyek `inventory-labkom`, jalankan impor database via terminal:

   **Menggunakan Windows Command Prompt (cmd):**
   ```cmd
   cmd /c "C:\xampp\mysql\bin\mysql.exe -u root inventory_labkom < database\schema.sql"
   cmd /c "C:\xampp\mysql\bin\mysql.exe -u root inventory_labkom < database\seed.sql"
   ```

   **Atau via phpMyAdmin (`http://localhost/phpmyadmin`):**
   - Buka browser ke `http://localhost/phpmyadmin`.
   - Buat database baru bernama `inventory_labkom`.
   - Buka tab **Import**, unggah file `database/schema.sql` terlebih dahulu, lalu klik *Go*.
   - Buka tab **Import** kembali, unggah file `database/seed.sql`, lalu klik *Go*.

### Akun Bawaan Development:

| Username | Password | Level | Peran |
|---|---|---|---|
| `laboran` | `laboran123` | `admin` | Laboran |
| `kaprog` | `kaprog123` | `super_admin` | Kepala Program |

---

## 5. Setup Backend PHP

### 5.1 Konfigurasi File Environment
Salin template konfigurasi:
```bash
copy backend\config\config.example.php backend\config\config.php
```

Buka `backend/config/config.php` dan sesuaikan kredensial:
- Kredensial database (`db.username`: `root`, `db.password`: `""`).
- Kredensial JWT secret (`jwt.secret` wajib diganti dengan string acak 32+ karakter).

### 5.2 Install Library Laporan (Composer)
Jalankan Composer di dalam direktori `backend/`:
```bash
cd backend
composer install
cd ..
```
*Langkah ini mengunduh library mPDF, PHPWord, dan PhpSpreadsheet ke `backend/vendor/` untuk fitur pencetakan laporan.*

### 5.3 Jalankan Server Backend PHP
Jalankan development server PHP dengan document root mengarah ke folder `public/`:

```bash
cd backend
php -S 127.0.0.1:8080 -t public public/index.php
```

### 5.4 Verifikasi Endpoint API
Buka browser atau jalankan curl ke `http://127.0.0.1:8080/api/health`:

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

---

## 6. Setup Aplikasi Mobile Flutter

Seluruh source code aplikasi Flutter berada di direktori `mobile/`.

### 6.1 Install Dependencies
Masuk ke direktori `mobile/` dan unduh paket Flutter:
```bash
cd mobile
flutter pub get
```

### 6.2 Konfigurasi Alamat API Backend
Alamat API dipetakan di file `mobile/lib/core/config/app_config.dart`. Secara default, aplikasi sudah terkonfigurasi untuk emulator Android (`http://10.0.2.2:8080`).

| Penggunaan | Alamat Backend API |
|---|---|
| **Emulator Android** | `http://10.0.2.2:8080` *(default)* |
| **HP Fisik Android** | `http://<IP-Laptop-Anda>:8080` (misal `http://192.168.1.10:8080`) |
| **Flutter Web / Chrome** | `http://127.0.0.1:8080` |

### 6.3 Jalankan Aplikasi Mobile
- **Di Emulator / Perangkat Android Connected**:
  ```bash
  flutter run
  ```
- **Build APK Release**:
  ```bash
  flutter build apk --release
  ```
  *File APK hasil build akan berada di `mobile/build/app/outputs/flutter-apk/app-release.apk`.*

---

## 7. Masalah Umum & Pertanyaan Frequent (FAQ)

| Gejala | Penyebab & Solusi |
|---|---|
| `flutter` atau `php` tidak dikenali di terminal | Path variabel environment belum ditambahkan ke System PATH. Tambahkan `C:\xampp\php` dan `C:\src\flutter\bin` ke System PATH, lalu buka terminal baru. |
| Error `ext-gd` / `ext-zip` saat `composer install` | Ekstensi PHP belum diaktifkan di `php.ini`. Edit `C:\xampp\php\php.ini`, buang tanda `;` pada `extension=gd` dan `extension=zip`, lalu simpan. |
| API membalas `"database": "disconnected"` | Service MySQL di XAMPP belum di-start atau nama database/kredensial di `backend/config/config.php` salah. |
| Aplikasi mobile di HP fisik tidak bisa login | HP dan Laptop tidak berada di satu jaringan Wi-Fi yang sama, atau firewall Windows memblokir port 8080. Gunakan IP lokal laptop Anda pada `app_config.dart`. |

