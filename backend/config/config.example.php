<?php
/**
 * Konfigurasi Inventory Labkom — SALIN file ini jadi config.php lalu sesuaikan.
 *   cp config/config.example.php config/config.php
 *
 * config.php di-gitignore supaya kredensial tidak ikut ter-commit.
 */

return [
    'app' => [
        'name'  => 'Inventory Labkom API',
        'env'   => 'development',      // development | production
        'debug' => true,               // WAJIB false di production

        // Origin browser yang boleh memanggil API. Biarkan kosong untuk
        // aplikasi Flutter native — CORS hanya relevan buat klien web.
        'cors_origins' => [],
    ],

    'db' => [
        'host'     => '127.0.0.1',
        'port'     => 3306,
        'database' => 'inventory_labkom',
        'username' => 'root',
        'password' => '',              // XAMPP default kosong
        'charset'  => 'utf8mb4',
    ],

    'jwt' => [
        // Ganti dengan string acak minimal 32 karakter. Contoh generate:
        //   php -r "echo bin2hex(random_bytes(32));"
        'secret'            => 'GANTI-DENGAN-SECRET-ACAK-MINIMAL-32-KARAKTER',
        'issuer'            => 'inventory-labkom',
        'ttl'               => 3600,        // 1 jam
        'ttl_remember_me'   => 2592000,     // 30 hari, dipakai saat "Ingat saya" dicentang
    ],

    'denda' => [
        // Nilai fallback kalau tabel pengaturan_denda kosong.
        'tarif_per_hari_default' => 5000.00,
    ],
];
