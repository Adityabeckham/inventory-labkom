<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Config;
use App\Core\Database;
use App\Core\Request;
use App\Core\Response;
use Throwable;

/** Endpoint pemeriksaan — dipakai untuk memastikan setup Sprint 0 benar. */
final class HealthController
{
    public function index(Request $request): void
    {
        $debug = (bool) Config::get('app.debug', false);

        try {
            Database::pdo()->query('SELECT 1');
            $db = 'connected';
        } catch (Throwable $e) {
            // Endpoint ini terbuka tanpa autentikasi. Pesan PDO mentah
            // membocorkan username DB, host, dan nama database — cukup untuk
            // memperpendek jalan penyerang. Detailnya hanya ke log.
            error_log('[inventory-labkom] health: ' . $e->getMessage());
            $db = $debug ? 'error: ' . $e->getMessage() : 'disconnected';
        }

        $data = [
            'app'      => Config::get('app.name'),
            'database' => $db,
            'time'     => date('c'),
        ];

        // Versi PHP dan nama environment mempersempit pencarian exploit —
        // hanya tampilkan saat debug.
        if ($debug) {
            $data['env'] = Config::get('app.env');
            $data['php'] = PHP_VERSION;
        }

        Response::success($data, 'API aktif.');
    }
}
