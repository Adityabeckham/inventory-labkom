<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Database;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;

/**
 * FR-11 — Pengaturan Denda (khusus Laboran).
 *
 * Tabelnya menyimpan satu baris konfigurasi. `seed.sql` sudah mengisinya,
 * tapi GET dan PUT tetap dibuat tahan terhadap database yang barisnya belum
 * ada: GET membalas tarif 0 dan PUT menyisipkan barisnya. Tanpa ini, satu
 * database tanpa seed akan membuat seluruh alur pengembalian gagal hanya
 * karena baris konfigurasi hilang.
 *
 * Baris yang dipakai selalu `id_pengaturan` terkecil. Ini keputusan
 * implementasi — dokumen tidak menyebut apa yang terjadi kalau ada lebih dari
 * satu baris; dicatat di docs/deviasi-dari-spesifikasi.md.
 */
final class PengaturanDendaController
{
    /** Batas atas yang masuk akal untuk denda harian di lingkungan sekolah. */
    private const TARIF_MAKS = 1000000.0;

    public function show(Request $request): void
    {
        Response::success(self::baca(), 'Pengaturan denda.');
    }

    public function update(Request $request): void
    {
        $tarif = self::tarif($request);

        $adaBaris = Database::selectOne(
            'SELECT id_pengaturan FROM pengaturan_denda ORDER BY id_pengaturan LIMIT 1'
        );

        if ($adaBaris === null) {
            Database::execute(
                'INSERT INTO pengaturan_denda (tarif_per_hari) VALUES (:tarif)',
                ['tarif' => $tarif]
            );
        } else {
            Database::execute(
                'UPDATE pengaturan_denda SET tarif_per_hari = :tarif WHERE id_pengaturan = :id',
                ['tarif' => $tarif, 'id' => (int) $adaBaris['id_pengaturan']]
            );
        }

        Response::success(self::baca(), 'Tarif denda diperbarui.');
    }

    /**
     * Tarif yang berlaku sekarang.
     *
     * Dipakai PengembalianController saat menghitung denda. Nilainya dibaca
     * pada saat pengembalian dicatat lalu DISIMPAN di baris `pengembalian`,
     * jadi mengubah tarif tidak pernah mengubah denda yang sudah tercatat.
     */
    public static function tarifBerlaku(): float
    {
        return (float) self::baca()['tarif_per_hari'];
    }

    /** @return array<string,mixed> */
    private static function baca(): array
    {
        $row = Database::selectOne(
            'SELECT id_pengaturan, tarif_per_hari, updated_at
               FROM pengaturan_denda
              ORDER BY id_pengaturan
              LIMIT 1'
        );

        if ($row === null) {
            return [
                'id_pengaturan'  => null,
                'tarif_per_hari' => 0.0,
                'updated_at'     => null,
                'terkonfigurasi' => false,
            ];
        }

        return [
            'id_pengaturan'  => (int) $row['id_pengaturan'],
            'tarif_per_hari' => (float) $row['tarif_per_hari'],
            'updated_at'     => $row['updated_at'],
            'terkonfigurasi' => true,
        ];
    }

    /** Nominal rupiah: boleh 0 (bebas denda), tidak boleh negatif. */
    private static function tarif(Request $request): float
    {
        $value = $request->input('tarif_per_hari');

        if (is_int($value) || is_float($value)) {
            $tarif = (float) $value;
        } elseif (is_string($value) && preg_match('/^\d+(\.\d{1,2})?$/', trim($value)) === 1) {
            $tarif = (float) trim($value);
        } else {
            throw HttpException::unprocessable(
                "Field 'tarif_per_hari' harus angka tanpa tanda minus, maksimal dua desimal."
            );
        }

        if ($tarif < 0) {
            throw HttpException::unprocessable('Tarif denda tidak boleh negatif.');
        }
        if ($tarif > self::TARIF_MAKS) {
            throw HttpException::unprocessable(
                'Tarif denda per hari maksimal ' . number_format(self::TARIF_MAKS, 0, ',', '.') . '.'
            );
        }

        return $tarif;
    }
}
