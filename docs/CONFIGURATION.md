# Panduan Konfigurasi — Inventory Labkom

Seluruh konfigurasi backend ada di satu file: `backend/config/config.php`. File ini **di-gitignore** supaya kredensial tidak ikut ter-commit — yang masuk repo hanya `config.example.php` sebagai template.

```bash
cp backend/config/config.example.php backend/config/config.php
```

---

## `app` — Aplikasi

| Opsi | Nilai | Keterangan |
|---|---|---|
| `name` | string | Nama aplikasi, muncul di respons `/api/health` |
| `env` | `development` \| `production` | Penanda lingkungan |
| `cors_origins` | array | Daftar origin browser yang boleh memanggil API. **Biarkan kosong** untuk aplikasi Flutter native — CORS hanya relevan kalau nanti ada klien web. Jangan pakai `*` |
| `debug` | bool | **Wajib `false` di production.** Saat `true`, pesan error asli dikirim ke klien dan `/api/health` ikut menampilkan versi PHP serta nama environment. Saat `false`, semua jalur respons menutupnya dan detail hanya masuk log |

---

## `db` — Database

| Opsi | Default XAMPP | Keterangan |
|---|---|---|
| `host` | `127.0.0.1` | Pakai `127.0.0.1`, bukan `localhost` — menghindari koneksi lewat unix socket |
| `port` | `3306` | |
| `database` | `inventory_labkom` | Sesuai `database/schema.sql` |
| `username` | `root` | |
| `password` | *(kosong)* | XAMPP default tanpa password |
| `charset` | `utf8mb4` | Jangan diubah — skema memakai `utf8mb4_unicode_ci` |

> Untuk production, **jangan** pakai `root`. Buat user MySQL khusus dengan hak akses terbatas ke database `inventory_labkom` saja.

---

## `jwt` — Token Autentikasi

| Opsi | Default | Keterangan |
|---|---|---|
| `secret` | *(placeholder)* | **Wajib diganti.** Kunci penanda tangan token. Backend gagal-cepat saat startup (`bootstrap.php`) selama nilainya masih placeholder atau kosong — seluruh endpoint membalas HTTP 500, termasuk `/api/health` |
| `issuer` | `inventory-labkom` | Klaim `iss` di dalam token |
| `ttl` | `3600` (1 jam) | Masa berlaku token normal |
| `ttl_remember_me` | `2592000` (30 hari) | Masa berlaku saat "Ingat saya" dicentang di layar Login (FR-01) |

Generate secret:

```bash
php -r "echo bin2hex(random_bytes(32));"
```

Mengganti `secret` membuat **semua token yang beredar langsung tidak berlaku** — semua pengguna terpaksa login ulang. Itu justru yang diinginkan kalau secret pernah bocor.

---

## `denda` — Perhitungan Denda

| Opsi | Default | Keterangan |
|---|---|---|
| `tarif_per_hari_default` | `5000.00` | Nilai cadangan kalau tabel `pengaturan_denda` kosong |

Tarif yang sebenarnya dipakai dibaca dari tabel `pengaturan_denda` dan bisa diubah Laboran lewat menu Pengaturan Denda (FR-11) tanpa menyentuh file konfigurasi. Rumusnya:

```
denda = jumlah_hari_telat × tarif_per_hari
```

`jumlah_hari_telat` dihitung dari selisih `pengembalian.tanggal_pengembalian` dengan `peminjaman.tanggal_kembali`, dan bernilai 0 kalau tidak terlambat.

---

## Konfigurasi Sisi Flutter

Alamat backend disimpan di aplikasi Flutter, bukan di file ini. Lihat [INSTALLATION.md §5](INSTALLATION.md) untuk pemetaan alamat emulator vs HP fisik.

---

## Checklist Sebelum Production

- [ ] `app.debug` = `false`
- [ ] `jwt.secret` diganti dengan string acak, tidak pernah di-commit
- [ ] User MySQL khusus, bukan `root`, dengan hak akses terbatas
- [ ] Password akun bawaan (`laboran123`, `kaprog123`) sudah diganti lewat Kelola User
- [ ] Backend dilayani lewat HTTPS — JWT dikirim di header setiap request
