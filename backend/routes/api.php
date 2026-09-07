<?php
declare(strict_types=1);

/**
 * Tabel route Inventory Labkom API.
 *
 * Kontrak endpoint lengkap: docs_project/Database_Final_dan_Arsitektur.md §4.1
 * Route ditambahkan bertahap mengikuti Sprint Planning.
 *
 * Otorisasi ditegakkan di sini, bukan cuma di UI. Sesuai Tabel 3.1 Use Case,
 * Kepala Program hanya boleh Login, Verifikasi, dan Lihat Laporan — endpoint
 * kelola apa pun dibatasi ke Laboran lewat Auth::role(Auth::LABORAN).
 */

use App\Controllers\AuthController;
use App\Controllers\HealthController;
use App\Controllers\UserController;
use App\Core\Router;
use App\Middleware\Auth;

$router = new Router();

$health = new HealthController();
$auth   = new AuthController();
$user   = new UserController();

$laboran   = [Auth::role(Auth::LABORAN)];
$terdaftar = [Auth::required()];

// ── Sprint 0 ─────────────────────────────────────────────────────────
$router->get('/api/health', [$health, 'index']);

// ── Sprint 1 — FR-01 Autentikasi ─────────────────────────────────────
$router->post('/api/auth/login', [$auth, 'login']);
$router->get ('/api/auth/me',    [$auth, 'me'], $terdaftar);

// ── Sprint 1 — FR-12 Kelola User (khusus Laboran) ────────────────────
$router->get   ('/api/users',      [$user, 'index'],   $laboran);
$router->post  ('/api/users',      [$user, 'store'],   $laboran);
$router->get   ('/api/users/{id}', [$user, 'show'],    $laboran);
$router->put   ('/api/users/{id}', [$user, 'update'],  $laboran);
$router->delete('/api/users/{id}', [$user, 'destroy'], $laboran);

// ── Sprint 2 — FR-02 Barang, FR-03 Kategori, FR-04 Peminjam, FR-13 Mutasi Stok
// ── Sprint 3 — FR-05 Peminjaman, FR-07 Verifikasi
// ── Sprint 4 — FR-06 Pengembalian, FR-11 Pengaturan Denda
// ── Sprint 5 — FR-08/FR-09 Laporan (5 jenis × 3 format)

return $router;
