<?php
declare(strict_types=1);

namespace App\Reports;

/**
 * Isi satu laporan, bebas dari format keluarannya.
 *
 * Kelima jenis laporan (FR-08) bentuknya tabel dengan judul dan periode,
 * jadi keduanya cukup satu bentuk data dan satu renderer — bukan lima belas
 * jalur terpisah untuk tiap kombinasi jenis × format.
 */
final class Laporan
{
    /**
     * @param list<string>                    $kolom     judul kolom tabel
     * @param list<list<string|int|float>>    $baris     isi tabel, urutannya mengikuti $kolom
     * @param array<string,string>            $ringkasan label => nilai, dicetak di bawah tabel
     * @param list<int>                       $kolomAngka indeks kolom yang diratakan ke kanan
     * @param list<int>                       $kolomRupiah indeks kolom nominal rupiah
     *
     * Kolom rupiah dibedakan dari kolom angka biasa karena penanganannya
     * berbeda per format: PDF dan Word mencetaknya sebagai "Rp 15.000",
     * sedangkan Excel menyimpannya tetap sebagai angka dengan format sel —
     * laporan Excel memang dipakai untuk dijumlah ulang, dan teks tidak bisa.
     */
    public function __construct(
        public readonly string $judul,
        public readonly string $periode,
        public readonly array $kolom,
        public readonly array $baris,
        public readonly array $ringkasan = [],
        public readonly array $kolomAngka = [],
        public readonly array $kolomRupiah = [],
    ) {
    }

    /** Kolom yang diratakan ke kanan: angka biasa maupun nominal rupiah. */
    public function kolomKanan(): array
    {
        return array_values(array_unique([...$this->kolomAngka, ...$this->kolomRupiah]));
    }

    public static function rupiah(string|int|float $nilai): string
    {
        return 'Rp ' . number_format((float) $nilai, 0, ',', '.');
    }

    /** Nama berkas unduhan, mis. `laporan-barang-2026-09-07.pdf`. */
    public function namaBerkas(string $slug, string $ekstensi): string
    {
        return sprintf('laporan-%s-%s.%s', $slug, date('Y-m-d'), $ekstensi);
    }

    public function jumlahBaris(): int
    {
        return count($this->baris);
    }

    /** Identitas sekolah, dicetak sebagai kepala tiap laporan. */
    public const SEKOLAH = 'SMK Al-Madani Jampangkulon';
    public const UNIT    = 'Laboratorium Komputer';
}
