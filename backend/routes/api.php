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
use App\Controllers\BarangController;
use App\Controllers\HealthController;
use App\Controllers\KategoriController;
use App\Controllers\PeminjamController;
use App\Controllers\PeminjamanController;
use App\Controllers\StokMutasiController;
use App\Controllers\UserController;
use App\Core\Router;
use App\Middleware\Auth;

$router = new Router();

$health   = new HealthController();
$auth     = new AuthController();
$user     = new UserController();
$kategori = new KategoriController();
$barang   = new BarangController();
$peminjam = new PeminjamController();
$mutasi   = new StokMutasiController();
$pinjam   = new PeminjamanController();

$laboran   = [Auth::role(Auth::LABORAN)];
$kaprog    = [Auth::role(Auth::KEPALA_PROGRAM)];
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

// ── Sprint 2 — FR-03 Kelola Kategori ─────────────────────────────────
$router->get   ('/api/kategori',      [$kategori, 'index'],   $laboran);
$router->post  ('/api/kategori',      [$kategori, 'store'],   $laboran);
$router->put   ('/api/kategori/{id}', [$kategori, 'update'],  $laboran);
$router->delete('/api/kategori/{id}', [$kategori, 'destroy'], $laboran);

// ── Sprint 2 — FR-02 Kelola Barang ───────────────────────────────────
$router->get   ('/api/barang',      [$barang, 'index'],   $laboran);
$router->post  ('/api/barang',      [$barang, 'store'],   $laboran);
$router->get   ('/api/barang/{id}', [$barang, 'show'],    $laboran);
$router->put   ('/api/barang/{id}', [$barang, 'update'],  $laboran);
$router->delete('/api/barang/{id}', [$barang, 'destroy'], $laboran);

// ── Sprint 2 — FR-04 Kelola Peminjam ─────────────────────────────────
$router->get   ('/api/peminjam',      [$peminjam, 'index'],   $laboran);
$router->post  ('/api/peminjam',      [$peminjam, 'store'],   $laboran);
$router->get   ('/api/peminjam/{id}', [$peminjam, 'show'],    $laboran);
$router->put   ('/api/peminjam/{id}', [$peminjam, 'update'],  $laboran);
$router->delete('/api/peminjam/{id}', [$peminjam, 'destroy'], $laboran);

// ── Sprint 2 — FR-13 Kelola Stok Barang (mutasi) ─────────────────────
$router->get ('/api/stok-mutasi', [$mutasi, 'index'], $laboran);
$router->post('/api/stok-mutasi', [$mutasi, 'store'], $laboran);

// ── Sprint 3 — FR-05 Peminjaman Multi-Item ───────────────────────────
//
// GET dibuka untuk kedua level: Kepala Program perlu membaca daftar dan
// detail pengajuan untuk bisa memverifikasinya (bagian dari use case
// Verifikasi, Tabel 3.1). Yang MEMBUAT transaksi tetap hanya Laboran.
$router->get ('/api/peminjaman',      [$pinjam, 'index'], $terdaftar);
$router->get ('/api/peminjaman/{id}', [$pinjam, 'show'],  $terdaftar);
$router->post('/api/peminjaman',      [$pinjam, 'store'], $laboran);

// ── Sprint 3 — FR-07 Verifikasi (khusus Kepala Program) ──────────────
//
// Laboran sengaja TIDAK diberi akses: memisahkan yang mengajukan dari yang
// menyetujui adalah inti kontrol fitur ini. Kalau Laboran bisa menyetujui
// pengajuannya sendiri, verifikasinya kehilangan makna.
$router->patch('/api/peminjaman/{id}/verifikasi', [$pinjam, 'verifikasi'], $kaprog);

// ── Sprint 4 — FR-06 Pengembalian, FR-11 Pengaturan Denda
// ── Sprint 5 — FR-08/FR-09 Laporan (5 jenis × 3 format)

return $router;
