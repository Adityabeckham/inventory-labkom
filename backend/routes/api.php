<?php
declare(strict_types=1);

/**
 * Tabel route Inventory Labkom API.
 *
 * Kontrak endpoint lengkap: docs_project/Database_Final_dan_Arsitektur.md §4.1
 * Route ditambahkan bertahap mengikuti Sprint Planning — Sprint 0 baru health check.
 */

use App\Controllers\HealthController;
use App\Core\Router;

$router = new Router();

// ── Sprint 0 ─────────────────────────────────────────────────────────
$router->get('/api/health', [new HealthController(), 'index']);

// ── Sprint 1 — FR-01 Autentikasi, FR-12 Kelola User ──────────────────
// $router->post('/api/auth/login',  [new AuthController(), 'login']);
// $router->get ('/api/users',       [new UserController(), 'index'],   [Auth::role(Auth::LABORAN)]);
// $router->post('/api/users',       [new UserController(), 'store'],   [Auth::role(Auth::LABORAN)]);
// $router->put ('/api/users/{id}',  [new UserController(), 'update'],  [Auth::role(Auth::LABORAN)]);
// $router->delete('/api/users/{id}',[new UserController(), 'destroy'], [Auth::role(Auth::LABORAN)]);

// ── Sprint 2 — FR-02 Barang, FR-03 Kategori, FR-04 Peminjam, FR-13 Mutasi Stok
// ── Sprint 3 — FR-05 Peminjaman, FR-07 Verifikasi
// ── Sprint 4 — FR-06 Pengembalian, FR-11 Pengaturan Denda
// ── Sprint 5 — FR-08/FR-09 Laporan (5 jenis × 3 format)

return $router;
