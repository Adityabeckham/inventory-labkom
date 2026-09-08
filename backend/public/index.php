<?php
declare(strict_types=1);

/**
 * Front controller — semua request API masuk lewat sini.
 *
 * Dev (tanpa XAMPP):  php -S localhost:8080 -t backend/public
 * XAMPP:              arahkan DocumentRoot / VirtualHost ke backend/public
 */

use App\Core\Config;
use App\Core\Request;
use App\Core\Response;
use App\Core\Router;

// Dimuat lebih dulu tanpa autoloader: kalau bootstrap sendiri yang gagal,
// blok catch di bawah tetap punya cara membalas JSON.
require_once dirname(__DIR__) . '/core/Response.php';

$debug = false;

try {
    require_once dirname(__DIR__) . '/bootstrap.php';
    $debug = (bool) Config::get('app.debug', false);

    // CORS support for web clients (e.g. Flutter Web)
    $origin = (string) ($_SERVER['HTTP_ORIGIN'] ?? '');
    header('Access-Control-Allow-Origin: ' . ($origin !== '' ? $origin : '*'));
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept');
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Credentials: true');
    header('Vary: Origin');

    if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
        http_response_code(200);
        exit;
    }

    /** @var Router $router */
    $router = require dirname(__DIR__) . '/routes/api.php';
    $router->dispatch(Request::fromGlobals());
} catch (Throwable $e) {
    // Pesan asli hanya ke log — jangan pernah ke klien kecuali debug menyala.
    // Tanpa ini, path filesystem lengkap ikut terkirim saat config.php belum ada.
    error_log('[inventory-labkom] ' . $e::class . ': ' . $e->getMessage());

    Response::error(
        $debug ? $e->getMessage() : 'Terjadi kesalahan pada server.',
        500
    );
}
