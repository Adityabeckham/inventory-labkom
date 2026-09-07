<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Database;
use App\Core\Request;
use App\Core\Response;

/**
 * FR-10 — angka ringkasan Dashboard.
 *
 * Dibuka untuk kedua level. Kepala Program memang perlu melihat berapa
 * pengajuan yang menunggu keputusannya, dan Laboran perlu tahu berapa yang
 * sedang menggantung — keduanya membaca angka yang sama.
 *
 * "Unit di luar rak" sengaja DIPECAH jadi dua angka. Ada dua makna yang
 * sama-sama masuk akal untuk "sedang dipinjam":
 *
 *   1. `barang.jumlah - barang.stok` — semua unit yang tidak ada di rak,
 *      termasuk yang masih menunggu verifikasi (stok berkurang sejak
 *      diajukan, lihat §3.5.1).
 *   2. Unit pada transaksi yang SUDAH disetujui dan belum kembali.
 *
 * Selisih keduanya persis sebesar unit yang menunggu verifikasi. Kalau
 * disatukan jadi satu angka berlabel "Sedang Dipinjam", angkanya akan
 * berbeda dari jumlah kartu di layar Verifikasi dan terbaca seperti bug.
 */
final class DashboardController
{
    public function index(Request $request): void
    {
        $barang = Database::selectOne(
            'SELECT COUNT(*)                       AS jenis,
                    COALESCE(SUM(jumlah), 0)       AS total_unit,
                    COALESCE(SUM(stok), 0)         AS unit_tersedia,
                    SUM(CASE WHEN stok = 0 THEN 1 ELSE 0 END) AS jenis_habis
               FROM barang'
        ) ?? [];

        // Unit pada transaksi yang sudah disetujui dan belum dikembalikan.
        // LEFT JOIN ke pengembalian: baris detail yang sudah punya catatan
        // pengembalian tidak lagi dihitung.
        $dipinjam = Database::selectOne(
            "SELECT COALESCE(SUM(d.jumlah_pinjam), 0) AS unit,
                    COUNT(DISTINCT p.id_peminjaman)   AS transaksi
               FROM peminjaman p
               JOIN peminjaman_detail d ON d.id_peminjaman = p.id_peminjaman
               LEFT JOIN pengembalian pg ON pg.id_detail = d.id_detail
              WHERE p.status IN ('dipinjam', 'sebagian_kembali')
                AND pg.id_pengembalian IS NULL"
        ) ?? [];

        $menunggu = Database::selectOne(
            "SELECT COUNT(DISTINCT p.id_peminjaman)   AS transaksi,
                    COALESCE(SUM(d.jumlah_pinjam), 0) AS unit
               FROM peminjaman p
               JOIN peminjaman_detail d ON d.id_peminjaman = p.id_peminjaman
              WHERE p.status = 'menunggu_verifikasi'"
        ) ?? [];

        // Lewat jatuh tempo dan masih ada item yang belum kembali.
        $terlambat = Database::selectOne(
            "SELECT COUNT(DISTINCT p.id_peminjaman) AS transaksi
               FROM peminjaman p
               JOIN peminjaman_detail d ON d.id_peminjaman = p.id_peminjaman
               LEFT JOIN pengembalian pg ON pg.id_detail = d.id_detail
              WHERE p.status IN ('dipinjam', 'sebagian_kembali')
                AND pg.id_pengembalian IS NULL
                AND p.tanggal_kembali < :hari_ini",
            ['hari_ini' => date('Y-m-d')]
        ) ?? [];

        $denda = Database::selectOne(
            'SELECT COALESCE(SUM(denda), 0) AS total FROM pengembalian'
        ) ?? [];

        Response::success([
            'barang' => [
                'jenis'         => (int) ($barang['jenis'] ?? 0),
                'total_unit'    => (int) ($barang['total_unit'] ?? 0),
                'unit_tersedia' => (int) ($barang['unit_tersedia'] ?? 0),
                'jenis_habis'   => (int) ($barang['jenis_habis'] ?? 0),
            ],
            'peminjaman' => [
                'unit_dipinjam'      => (int) ($dipinjam['unit'] ?? 0),
                'transaksi_dipinjam' => (int) ($dipinjam['transaksi'] ?? 0),
                'unit_diajukan'      => (int) ($menunggu['unit'] ?? 0),
                'menunggu_verifikasi' => (int) ($menunggu['transaksi'] ?? 0),
                'terlambat'          => (int) ($terlambat['transaksi'] ?? 0),
            ],
            'denda' => [
                'total_tercatat' => (float) ($denda['total'] ?? 0),
            ],
        ], 'Ringkasan dashboard.');
    }
}
