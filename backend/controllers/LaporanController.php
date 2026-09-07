<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Database;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;
use App\Reports\Laporan;
use App\Reports\LaporanRenderer;

/**
 * FR-08 Cetak Laporan dan FR-09 Lihat Laporan — 5 jenis × 3 format.
 *
 * Keduanya endpoint yang sama: Laboran mencetak, Kepala Program membaca.
 * Tidak ada perbedaan hak di sini karena keduanya sama-sama hanya membaca —
 * pembedaan "Mode Lihat Saja" ada di UI, bukan di data.
 *
 * Filter periode `dari` dan `sampai` opsional dan berlaku pada tanggal yang
 * masuk akal untuk tiap jenis: tanggal input untuk barang, tanggal pinjam
 * untuk peminjaman, tanggal pengembalian untuk pengembalian dan denda.
 * Laporan Stok tidak punya periode karena isinya keadaan saat ini.
 */
final class LaporanController
{
    private const FORMAT = [
        'pdf'  => ['pdf',  'application/pdf'],
        'docx' => ['docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
        'xlsx' => ['xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
    ];

    // ── FR-08 · 1. Data Barang ───────────────────────────────────────

    public function barang(Request $request): void
    {
        [$dari, $sampai] = self::periode($request);
        [$where, $params] = self::rentang('b.tanggal_input', $dari, $sampai);

        $baris = Database::select(
            "SELECT b.kode_barang, b.nama_barang, k.nama_kategori, b.merk,
                    b.kondisi, b.serial_number, b.jumlah, b.stok, b.tanggal_input
               FROM barang b
               JOIN kategori k ON k.id_kategori = b.id_kategori
              $where
              ORDER BY k.nama_kategori, b.nama_barang",
            $params
        );

        self::kirim($request, 'barang', new Laporan(
            judul: 'Laporan Data Barang',
            periode: self::labelPeriode($dari, $sampai, 'Tanggal input'),
            kolom: ['Kode', 'Nama Barang', 'Kategori', 'Merk', 'Kondisi',
                    'Serial Number', 'Jumlah', 'Stok', 'Tgl Input'],
            baris: array_map(static fn (array $r): array => [
                $r['kode_barang'],
                $r['nama_barang'],
                $r['nama_kategori'],
                $r['merk'] ?? '-',
                $r['kondisi'] ?? '-',
                $r['serial_number'] ?? '-',
                (int) $r['jumlah'],
                (int) $r['stok'],
                $r['tanggal_input'] ?? '-',
            ], $baris),
            ringkasan: ['Jumlah jenis barang' => (string) count($baris)],
            kolomAngka: [6, 7],
        ));
    }

    // ── FR-08 · 2. Peminjaman ────────────────────────────────────────

    public function peminjaman(Request $request): void
    {
        [$dari, $sampai] = self::periode($request);
        [$where, $params] = self::rentang('p.tanggal_pinjam', $dari, $sampai);

        $baris = Database::select(
            "SELECT p.kode_peminjaman, pm.nama_peminjam, pm.nis_nip, pm.kelas_jabatan,
                    p.tanggal_pinjam, p.tanggal_kembali, p.status, u.username,
                    COUNT(d.id_detail) AS jumlah_item,
                    COALESCE(SUM(d.jumlah_pinjam), 0) AS total_unit
               FROM peminjaman p
               JOIN peminjam pm ON pm.id_peminjam = p.id_peminjam
               JOIN users    u  ON u.id_user      = p.id_user
               LEFT JOIN peminjaman_detail d ON d.id_peminjaman = p.id_peminjaman
              $where
              GROUP BY p.id_peminjaman, p.kode_peminjaman, pm.nama_peminjam,
                       pm.nis_nip, pm.kelas_jabatan, p.tanggal_pinjam,
                       p.tanggal_kembali, p.status, u.username
              ORDER BY p.tanggal_pinjam DESC, p.id_peminjaman DESC",
            $params
        );

        self::kirim($request, 'peminjaman', new Laporan(
            judul: 'Laporan Peminjaman',
            periode: self::labelPeriode($dari, $sampai, 'Tanggal pinjam'),
            kolom: ['Kode', 'Peminjam', 'NIS/NIP', 'Kelas/Jabatan', 'Tgl Pinjam',
                    'Jatuh Tempo', 'Status', 'Jenis', 'Unit', 'Dicatat Oleh'],
            baris: array_map(static fn (array $r): array => [
                $r['kode_peminjaman'],
                $r['nama_peminjam'],
                $r['nis_nip'] ?? '-',
                $r['kelas_jabatan'] ?? '-',
                $r['tanggal_pinjam'],
                $r['tanggal_kembali'],
                self::labelStatus((string) $r['status']),
                (int) $r['jumlah_item'],
                (int) $r['total_unit'],
                $r['username'],
            ], $baris),
            ringkasan: ['Jumlah transaksi' => (string) count($baris)],
            kolomAngka: [7, 8],
        ));
    }

    // ── FR-08 · 3. Pengembalian ──────────────────────────────────────

    public function pengembalian(Request $request): void
    {
        [$dari, $sampai] = self::periode($request);
        [$where, $params] = self::rentang('pg.tanggal_pengembalian', $dari, $sampai);

        $baris = Database::select(
            "SELECT p.kode_peminjaman, pm.nama_peminjam,
                    b.kode_barang, b.nama_barang, d.jumlah_pinjam,
                    p.tanggal_kembali, pg.tanggal_pengembalian,
                    pg.kondisi, pg.jumlah_hari_telat, pg.denda
               FROM pengembalian pg
               JOIN peminjaman_detail d ON d.id_detail     = pg.id_detail
               JOIN peminjaman        p ON p.id_peminjaman = d.id_peminjaman
               JOIN peminjam         pm ON pm.id_peminjam  = p.id_peminjam
               JOIN barang            b ON b.id_barang     = d.id_barang
              $where
              ORDER BY pg.tanggal_pengembalian DESC, pg.id_pengembalian DESC",
            $params
        );

        $totalDenda = array_sum(array_map(
            static fn (array $r): float => (float) $r['denda'],
            $baris
        ));

        self::kirim($request, 'pengembalian', new Laporan(
            judul: 'Laporan Pengembalian',
            periode: self::labelPeriode($dari, $sampai, 'Tanggal pengembalian'),
            kolom: ['Kode Pinjam', 'Peminjam', 'Kode Barang', 'Nama Barang', 'Unit',
                    'Jatuh Tempo', 'Tgl Kembali', 'Kondisi', 'Telat (hari)', 'Denda'],
            baris: array_map(static fn (array $r): array => [
                $r['kode_peminjaman'],
                $r['nama_peminjam'],
                $r['kode_barang'],
                $r['nama_barang'],
                (int) $r['jumlah_pinjam'],
                $r['tanggal_kembali'],
                $r['tanggal_pengembalian'],
                ucfirst((string) $r['kondisi']),
                (int) $r['jumlah_hari_telat'],
                (float) $r['denda'],
            ], $baris),
            ringkasan: [
                'Jumlah item dikembalikan' => (string) count($baris),
                'Total denda'              => Laporan::rupiah($totalDenda),
            ],
            kolomAngka: [4, 8],
            kolomRupiah: [9],
        ));
    }

    // ── FR-08 · 4. Stok Barang ───────────────────────────────────────

    public function stok(Request $request): void
    {
        // Tanpa periode: isinya keadaan stok SAAT INI, bukan rentang waktu.
        $baris = Database::select(
            'SELECT b.kode_barang, b.nama_barang, k.nama_kategori,
                    b.jumlah, b.stok, (b.jumlah - b.stok) AS tidak_di_rak
               FROM barang b
               JOIN kategori k ON k.id_kategori = b.id_kategori
              ORDER BY (b.jumlah - b.stok) DESC, k.nama_kategori, b.nama_barang'
        );

        $totalUnit = array_sum(array_map(static fn (array $r): int => (int) $r['jumlah'], $baris));
        $totalStok = array_sum(array_map(static fn (array $r): int => (int) $r['stok'], $baris));

        self::kirim($request, 'stok', new Laporan(
            judul: 'Laporan Stok Barang',
            periode: 'Keadaan pada ' . date('d-m-Y H:i'),
            kolom: ['Kode', 'Nama Barang', 'Kategori', 'Total Unit',
                    'Tersedia', 'Dipinjam/Diajukan', 'Keterangan'],
            baris: array_map(static fn (array $r): array => [
                $r['kode_barang'],
                $r['nama_barang'],
                $r['nama_kategori'],
                (int) $r['jumlah'],
                (int) $r['stok'],
                (int) $r['tidak_di_rak'],
                (int) $r['stok'] === 0 ? 'Habis' : 'Tersedia',
            ], $baris),
            ringkasan: [
                'Total unit dimiliki'  => (string) $totalUnit,
                'Total unit tersedia'  => (string) $totalStok,
                'Sedang di luar rak'   => (string) ($totalUnit - $totalStok),
            ],
            kolomAngka: [3, 4, 5],
        ));
    }

    // ── FR-08 · 5. Denda ─────────────────────────────────────────────

    public function denda(Request $request): void
    {
        [$dari, $sampai] = self::periode($request);
        [$where, $params] = self::rentang('pg.tanggal_pengembalian', $dari, $sampai);

        // Denda dibaca APA ADANYA dari baris pengembalian, tidak pernah
        // dihitung ulang dari tarif yang berlaku sekarang. Itu jaminan D-08:
        // angka di laporan harus sama dengan yang tercatat saat kejadian,
        // walaupun tarifnya sudah pernah diubah sejak itu.
        $rentangDenda = $where === '' ? 'WHERE pg.denda > 0' : $where . ' AND pg.denda > 0';

        $baris = Database::select(
            "SELECT p.kode_peminjaman, pm.nama_peminjam, pm.nis_nip, pm.kelas_jabatan,
                    b.nama_barang, p.tanggal_kembali, pg.tanggal_pengembalian,
                    pg.jumlah_hari_telat, pg.denda
               FROM pengembalian pg
               JOIN peminjaman_detail d ON d.id_detail     = pg.id_detail
               JOIN peminjaman        p ON p.id_peminjaman = d.id_peminjaman
               JOIN peminjam         pm ON pm.id_peminjam  = p.id_peminjam
               JOIN barang            b ON b.id_barang     = d.id_barang
              $rentangDenda
              ORDER BY pg.denda DESC, pg.tanggal_pengembalian DESC",
            $params
        );

        $total = array_sum(array_map(static fn (array $r): float => (float) $r['denda'], $baris));
        $hari  = array_sum(array_map(static fn (array $r): int => (int) $r['jumlah_hari_telat'], $baris));

        self::kirim($request, 'denda', new Laporan(
            judul: 'Laporan Denda Keterlambatan',
            periode: self::labelPeriode($dari, $sampai, 'Tanggal pengembalian'),
            kolom: ['Kode Pinjam', 'Peminjam', 'NIS/NIP', 'Kelas/Jabatan', 'Barang',
                    'Jatuh Tempo', 'Tgl Kembali', 'Telat (hari)', 'Denda'],
            baris: array_map(static fn (array $r): array => [
                $r['kode_peminjaman'],
                $r['nama_peminjam'],
                $r['nis_nip'] ?? '-',
                $r['kelas_jabatan'] ?? '-',
                $r['nama_barang'],
                $r['tanggal_kembali'],
                $r['tanggal_pengembalian'],
                (int) $r['jumlah_hari_telat'],
                (float) $r['denda'],
            ], $baris),
            ringkasan: [
                'Jumlah kasus keterlambatan' => (string) count($baris),
                'Total hari keterlambatan'   => (string) $hari,
                'Total denda'                => Laporan::rupiah($total),
            ],
            kolomAngka: [7],
            kolomRupiah: [8],
        ));
    }

    // ── Pembantu ─────────────────────────────────────────────────────

    /**
     * Membuat berkas lalu mengirimnya sebagai lampiran.
     *
     * Seluruh isi berkas selesai dibuat di memori sebelum satu byte pun
     * dikirim. Kalau pembuatannya gagal, front controller masih bisa membalas
     * JSON error yang utuh — bukan JSON yang menempel di ekor berkas
     * setengah jadi.
     */
    private static function kirim(Request $request, string $slug, Laporan $laporan): void
    {
        $format = (string) ($request->query('format') ?? 'pdf');

        if (!isset(self::FORMAT[$format])) {
            throw HttpException::badRequest(
                'Format harus salah satu dari: ' . implode(', ', array_keys(self::FORMAT)) . '.'
            );
        }

        self::pastikanLibraryTerpasang();

        [$ekstensi, $mime] = self::FORMAT[$format];

        $isi = match ($format) {
            'pdf'  => LaporanRenderer::pdf($laporan),
            'docx' => LaporanRenderer::docx($laporan),
            'xlsx' => LaporanRenderer::xlsx($laporan),
        };

        Response::file($isi, $laporan->namaBerkas($slug, $ekstensi), $mime);
    }

    /**
     * Library laporan datang dari Composer, sementara endpoint lain tidak
     * membutuhkannya. Tanpa pemeriksaan ini, `composer install` yang terlupa
     * memunculkan "Class not found" yang tidak menjelaskan apa pun.
     */
    private static function pastikanLibraryTerpasang(): void
    {
        foreach ([
            \Mpdf\Mpdf::class                             => 'mpdf/mpdf',
            \PhpOffice\PhpWord\PhpWord::class             => 'phpoffice/phpword',
            \PhpOffice\PhpSpreadsheet\Spreadsheet::class  => 'phpoffice/phpspreadsheet',
        ] as $kelas => $paket) {
            if (!class_exists($kelas)) {
                // 503, bukan RuntimeException: pesan ini harus sampai ke
                // klien walaupun app.debug mati, karena justru di produksi
                // `composer install` yang terlupa paling mungkin terjadi.
                throw HttpException::unavailable(
                    "Library laporan belum terpasang ($paket). "
                    . 'Jalankan `composer install` di direktori backend.'
                );
            }
        }
    }

    /** @return array{0:?string,1:?string} */
    private static function periode(Request $request): array
    {
        return [self::tanggal($request, 'dari'), self::tanggal($request, 'sampai')];
    }

    private static function tanggal(Request $request, string $param): ?string
    {
        $nilai = $request->query($param);
        if ($nilai === null || $nilai === '') {
            return null;
        }

        $nilai = trim((string) $nilai);
        if (preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $nilai, $m) !== 1
            || !checkdate((int) $m[2], (int) $m[3], (int) $m[1])) {
            throw HttpException::badRequest(
                "Parameter '$param' harus tanggal sah berformat YYYY-MM-DD."
            );
        }

        return $nilai;
    }

    /**
     * Klausa WHERE untuk rentang tanggal.
     *
     * @return array{0:string,1:array<string,mixed>}
     */
    private static function rentang(string $kolom, ?string $dari, ?string $sampai): array
    {
        if ($dari !== null && $sampai !== null && $dari > $sampai) {
            throw HttpException::badRequest(
                'Tanggal "dari" tidak boleh lebih akhir dari "sampai".'
            );
        }

        $syarat = [];
        $params = [];

        if ($dari !== null) {
            $syarat[] = "$kolom >= :dari";
            $params['dari'] = $dari;
        }
        if ($sampai !== null) {
            $syarat[] = "$kolom <= :sampai";
            $params['sampai'] = $sampai;
        }

        return [$syarat === [] ? '' : 'WHERE ' . implode(' AND ', $syarat), $params];
    }

    private static function labelPeriode(?string $dari, ?string $sampai, string $dasar): string
    {
        return match (true) {
            $dari !== null && $sampai !== null => "$dasar $dari sampai $sampai",
            $dari !== null                     => "$dasar sejak $dari",
            $sampai !== null                   => "$dasar sampai $sampai",
            default                            => "$dasar — seluruh periode",
        };
    }

    private static function labelStatus(string $status): string
    {
        return match ($status) {
            'menunggu_verifikasi' => 'Menunggu Verifikasi',
            'dipinjam'            => 'Dipinjam',
            'sebagian_kembali'    => 'Sebagian Kembali',
            'dikembalikan'        => 'Dikembalikan',
            'dibatalkan'          => 'Dibatalkan',
            default               => $status,
        };
    }
}
