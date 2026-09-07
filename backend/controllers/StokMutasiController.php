<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Database;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;
use App\Middleware\Auth;
use PDO;

/**
 * FR-13 — Kelola Stok Barang (mutasi masuk/keluar).
 *
 * Terpisah dari perubahan stok akibat Peminjaman/Pengembalian. Ini khusus
 * penyesuaian manual: pengadaan baru, barang rusak, hilang, dan sejenisnya.
 *
 * DEVIASI dari Database_Final_dan_Arsitektur.md §3.9 — dicatat di
 * docs/deviasi-dari-spesifikasi.md. Spesifikasi hanya menyebut `barang.stok`
 * yang diperbarui, tapi `jumlah` didefinisikan sebagai "total unit dimiliki".
 * Kalau hanya stok yang berubah, mutasi masuk 10 unit pada barang berjumlah 40
 * menghasilkan stok 50 dari total 40 — mustahil. Jadi keduanya disesuaikan.
 */
final class StokMutasiController
{
    public function index(Request $request): void
    {
        $sql = 'SELECT m.*, b.kode_barang, b.nama_barang, u.username
                  FROM stok_mutasi m
                  JOIN barang b ON b.id_barang = m.id_barang
                  JOIN users  u ON u.id_user   = m.id_user';
        $params = [];

        $idBarang = $request->query('id_barang');
        if ($idBarang !== null && $idBarang !== '') {
            if (preg_match('/^\d+$/', (string) $idBarang) !== 1) {
                throw HttpException::badRequest('Filter barang tidak valid.');
            }
            $sql .= ' WHERE m.id_barang = :id_barang';
            $params['id_barang'] = (int) $idBarang;
        }

        // Terbaru di atas. id_mutasi jadi pemecah seri karena tanggal_mutasi
        // hanya berpresisi hari — beberapa mutasi di hari yang sama harus
        // tetap tampil dalam urutan pencatatannya.
        $sql .= ' ORDER BY m.tanggal_mutasi DESC, m.id_mutasi DESC';

        Response::success(
            array_map(self::present(...), Database::select($sql, $params)),
            'Riwayat mutasi stok.'
        );
    }

    public function store(Request $request): void
    {
        $idBarang  = Validator::positiveInt($request, 'id_barang');
        $jenis     = Validator::enum($request, 'jenis', ['masuk', 'keluar']);
        $jumlah    = Validator::positiveInt($request, 'jumlah');
        $keterangan = Validator::optionalString($request, 'keterangan', 255);
        $tanggal   = Validator::optionalDate($request, 'tanggal_mutasi') ?? date('Y-m-d');
        $idUser    = Auth::user()['id_user'];

        // Pembacaan stok dan penulisannya harus satu kesatuan. Tanpa
        // transaksi + penguncian baris, dua laboran yang mencatat mutasi
        // bersamaan bisa sama-sama membaca stok lama lalu saling menimpa.
        $idMutasi = Database::transaction(
            function (PDO $pdo) use ($idBarang, $jenis, $jumlah, $keterangan, $tanggal, $idUser): int {
                $stmt = $pdo->prepare(
                    'SELECT jumlah, stok FROM barang WHERE id_barang = :id FOR UPDATE'
                );
                $stmt->execute(['id' => $idBarang]);
                $barang = $stmt->fetch();

                if ($barang === false) {
                    throw HttpException::unprocessable('Barang yang dipilih tidak ada.');
                }

                $delta        = $jenis === 'masuk' ? $jumlah : -$jumlah;
                $jumlahBaru   = (int) $barang['jumlah'] + $delta;
                $stokBaru     = (int) $barang['stok'] + $delta;

                if ($stokBaru < 0) {
                    throw HttpException::unprocessable(
                        sprintf(
                            'Stok tersedia tinggal %d, tidak cukup untuk mutasi keluar %d.',
                            (int) $barang['stok'],
                            $jumlah
                        )
                    );
                }

                // Bisa terjadi kalau sebagian unit sedang dipinjam: stok 2 dari
                // jumlah 5, lalu keluar 4 unit. Stok jadi -2 sudah tertangkap
                // di atas, tapi cek ini menjaga invarian kalau logikanya berubah.
                if ($jumlahBaru < 0) {
                    throw HttpException::unprocessable(
                        'Jumlah total barang tidak boleh menjadi negatif.'
                    );
                }

                $pdo->prepare(
                    'UPDATE barang SET jumlah = :jumlah, stok = :stok WHERE id_barang = :id'
                )->execute([
                    'jumlah' => $jumlahBaru,
                    'stok'   => $stokBaru,
                    'id'     => $idBarang,
                ]);

                $pdo->prepare(
                    'INSERT INTO stok_mutasi (id_barang, id_user, jenis, jumlah, keterangan, tanggal_mutasi)
                     VALUES (:id_barang, :id_user, :jenis, :jumlah, :keterangan, :tanggal_mutasi)'
                )->execute([
                    'id_barang'      => $idBarang,
                    'id_user'        => $idUser,
                    'jenis'          => $jenis,
                    'jumlah'         => $jumlah,
                    'keterangan'     => $keterangan,
                    'tanggal_mutasi' => $tanggal,
                ]);

                return (int) $pdo->lastInsertId();
            }
        );

        Response::success(self::findOrFail($idMutasi), 'Mutasi stok dicatat.', 201);
    }

    /** @param array<string,mixed> $row */
    private static function present(array $row): array
    {
        return [
            'id_mutasi'      => (int) $row['id_mutasi'],
            'id_barang'      => (int) $row['id_barang'],
            'kode_barang'    => $row['kode_barang'],
            'nama_barang'    => $row['nama_barang'],
            'jenis'          => $row['jenis'],
            'jumlah'         => (int) $row['jumlah'],
            'keterangan'     => $row['keterangan'],
            'tanggal_mutasi' => $row['tanggal_mutasi'],
            'dicatat_oleh'   => $row['username'],
        ];
    }

    /** @return array<string,mixed> */
    private static function findOrFail(int $id): array
    {
        $row = Database::selectOne(
            'SELECT m.*, b.kode_barang, b.nama_barang, u.username
               FROM stok_mutasi m
               JOIN barang b ON b.id_barang = m.id_barang
               JOIN users  u ON u.id_user   = m.id_user
              WHERE m.id_mutasi = :id',
            ['id' => $id]
        );

        if ($row === null) {
            throw HttpException::notFound('Mutasi tidak ditemukan.');
        }

        return self::present($row);
    }
}
