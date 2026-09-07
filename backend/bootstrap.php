<?php
declare(strict_types=1);

/**
 * Bootstrap Inventory Labkom API.
 * Autoloader manual — belum butuh Composer sampai Sprint 5 (library laporan).
 */

use App\Core\Config;
use App\Core\Jwt;

const BASE_PATH = __DIR__;

spl_autoload_register(static function (string $class): void {
    $prefixes = [
        'App\\Core\\'        => BASE_PATH . '/core/',
        'App\\Middleware\\'  => BASE_PATH . '/middleware/',
        'App\\Controllers\\' => BASE_PATH . '/controllers/',
    ];

    foreach ($prefixes as $prefix => $dir) {
        if (!str_starts_with($class, $prefix)) {
            continue;
        }
        $file = $dir . str_replace('\\', '/', substr($class, strlen($prefix))) . '.php';
        if (is_file($file)) {
            require_once $file;
            return;
        }
    }
});

// Composer autoload dipakai kalau sudah di-install (mPDF, PHPWord, PhpSpreadsheet).
if (is_file(BASE_PATH . '/vendor/autoload.php')) {
    require_once BASE_PATH . '/vendor/autoload.php';
}

Config::load(BASE_PATH . '/config/config.php');

// Gagal-cepat: lebih baik seluruh backend menolak jalan daripada baru
// ketahuan saat pengguna pertama mencoba login.
Jwt::assertSecretConfigured();

$debug = (bool) Config::get('app.debug', false);
ini_set('display_errors', $debug ? '1' : '0');
error_reporting($debug ? E_ALL : E_ALL & ~E_DEPRECATED);

date_default_timezone_set('Asia/Jakarta');
