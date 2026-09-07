<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Database;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;

/** FR-02 — Kelola Barang. */
final class BarangController
{
    public function index(Request $request): void
    {
        $where  = [];
        $params = [];

        // Filter chip kategori di layar Aset Lab.
        $kategori = $request->query('id_kategori');
        if ($kategori !== null && $kategori !== '' && $kategori !== 'semua') {
            if (preg_match('/^\d+$/', (string) $kategori) !== 1) {
                throw HttpException::badRequest('Filter kategori tidak valid.');
            }
            $where[]              = 'b.id_kategori = :id_kategori';
            $params['id_kategori'] = (int) $kategori;
        }

        // Pencarian menyasar nama, kode, merk, dan serial number sekaligus —
        // laboran di depan rak biasanya hanya pegang salah satunya.
        $cari = trim((string) ($request->query('cari') ?? ''));
        if ($cari !== '') {
            // Tiap kolom perlu placeholder sendiri: prepared statement asli
            // (ATTR_EMULATE_PREPARES = false) tidak mengizinkan satu nama
            // placeholder dipakai berulang dalam satu query.
            $where[] = '(b.nama_barang LIKE :cari1 OR b.kode_barang LIKE :cari2 '
                     . 'OR b.merk LIKE :cari3 OR b.serial_number LIKE :cari4)';
            $pola = '%' . self::escapeLike($cari) . '%';
            $params += ['cari1' => $pola, 'cari2' => $pola, 'cari3' => $pola, 'cari4' => $pola];
        }

        $sql = 'SELECT b.*, k.nama_kategori
                  FROM barang b
                  JOIN kategori k ON k.id_kategori = b.id_kategori';
        if ($where !== []) {
            $sql .= ' WHERE ' . implode(' AND ', $where);
        }
        $sql .= ' ORDER BY b.kode_barang';

        $rows = Database::select($sql, $params);

        Response::success(array_map(self::present(...), $rows), 'Daftar barang.');
    }

    public function show(Request $request): void
    {
        Response::success(self::findOrFail(Validator::id($request)), 'Detail barang.');
    }

    public function store(Request $request): void
    {
        $data = self::validated($request);
        self::assertKategoriExists($data['id_kategori']);
        self::assertKodeFree($data['kode_barang']);

        Database::execute(
            'INSERT INTO barang
                (id_kategori, kode_barang, nama_barang, merk, jumlah, kondisi, stok, tanggal_input, serial_number)
             VALUES
                (:id_kategori, :kode_barang, :nama_barang, :merk, :jumlah, :kondisi, :stok, :tanggal_input, :serial_number)',
            $data
        );

        Response::success(self::findOrFail(Database::lastInsertId()), 'Barang ditambahkan.', 201);
    }

    public function update(Request $request): void
    {
        $id = Validator::id($request);
        self::findOrFail($id);

        $data = self::validated($request);
        self::assertKategoriExists($data['id_kategori']);
        self::assertKodeFree($data['kode_barang'], $id);

        $data['id'] = $id;

        Database::execute(
            'UPDATE barang SET
                id_kategori   = :id_kategori,
                kode_barang   = :kode_barang,
                nama_barang   = :nama_barang,
                merk          = :merk,
                jumlah        = :jumlah,
                kondisi       = :kondisi,
                stok          = :stok,
                tanggal_input = :tanggal_input,
                serial_number = :serial_number
             WHERE id_barang = :id',
            $data
        );

        Response::success(self::findOrFail($id), 'Barang diperbarui.');
    }

    public function destroy(Request $request): void
    {
        $id = Validator::id($request);
        self::findOrFail($id);

        // peminjaman_detail dan stok_mutasi memakai ON DELETE RESTRICT —
        // riwayat transaksi tidak boleh kehilangan barang acuannya.
        $dipinjam = Database::selectOne(
            'SELECT COUNT(*) AS n FROM peminjaman_detail WHERE id_barang = :id',
            ['id' => $id]
        );
        $mutasi = Database::selectOne(
            'SELECT COUNT(*) AS n FROM stok_mutasi WHERE id_barang = :id',
            ['id' => $id]
        );

        $jumlah = (int) ($dipinjam['n'] ?? 0) + (int) ($mutasi['n'] ?? 0);
        if ($jumlah > 0) {
            throw HttpException::conflict(
                "Barang ini tercatat pada $jumlah transaksi, jadi tidak bisa dihapus. "
                . 'Catat mutasi keluar kalau barangnya sudah tidak ada.'
            );
        }

        Database::execute('DELETE FROM barang WHERE id_barang = :id', ['id' => $id]);

        Response::success(null, 'Barang dihapus.');
    }

    /** @return array<string,mixed> */
    private static function validated(Request $request): array
    {
        $jumlah = Validator::nonNegativeInt($request, 'jumlah');
        $stok   = Validator::nonNegativeInt($request, 'stok');

        // stok = unit yang sedang tersedia, jumlah = total unit dimiliki.
        // Tersedia melebihi yang dimiliki berarti datanya salah input.
        if ($stok > $jumlah) {
            throw HttpException::unprocessable(
                'Stok tersedia tidak boleh melebihi jumlah total barang.'
            );
        }

        return [
            'id_kategori'   => Validator::positiveInt($request, 'id_kategori'),
            'kode_barang'   => Validator::requiredString($request, 'kode_barang', 30),
            'nama_barang'   => Validator::requiredString($request, 'nama_barang', 100),
            'merk'          => Validator::optionalString($request, 'merk', 100),
            'jumlah'        => $jumlah,
            'kondisi'       => Validator::optionalString($request, 'kondisi', 50),
            'stok'          => $stok,
            'tanggal_input' => Validator::date($request, 'tanggal_input'),
            'serial_number' => Validator::optionalString($request, 'serial_number', 50),
        ];
    }

    /** @param array<string,mixed> $row */
    private static function present(array $row): array
    {
        return [
            'id_barang'     => (int) $row['id_barang'],
            'id_kategori'   => (int) $row['id_kategori'],
            'nama_kategori' => $row['nama_kategori'],
            'kode_barang'   => $row['kode_barang'],
            'nama_barang'   => $row['nama_barang'],
            'merk'          => $row['merk'],
            'jumlah'        => (int) $row['jumlah'],
            'kondisi'       => $row['kondisi'],
            'stok'          => (int) $row['stok'],
            'tanggal_input' => $row['tanggal_input'],
            'serial_number' => $row['serial_number'],
        ];
    }

    /** @return array<string,mixed> */
    private static function findOrFail(int $id): array
    {
        $row = Database::selectOne(
            'SELECT b.*, k.nama_kategori
               FROM barang b
               JOIN kategori k ON k.id_kategori = b.id_kategori
              WHERE b.id_barang = :id',
            ['id' => $id]
        );

        if ($row === null) {
            throw HttpException::notFound('Barang tidak ditemukan.');
        }

        return self::present($row);
    }

    private static function assertKategoriExists(int $id): void
    {
        $row = Database::selectOne(
            'SELECT id_kategori FROM kategori WHERE id_kategori = :id',
            ['id' => $id]
        );

        if ($row === null) {
            throw HttpException::unprocessable('Kategori yang dipilih tidak ada.');
        }
    }

    private static function assertKodeFree(string $kode, ?int $exceptId = null): void
    {
        $sql    = 'SELECT id_barang FROM barang WHERE kode_barang = :kode';
        $params = ['kode' => $kode];

        if ($exceptId !== null) {
            $sql .= ' AND id_barang <> :id';
            $params['id'] = $exceptId;
        }

        if (Database::selectOne($sql, $params) !== null) {
            throw HttpException::conflict("Kode barang '$kode' sudah dipakai.");
        }
    }

    /** Netralkan wildcard supaya pencarian "100%" tidak jadi cocok semua. */
    private static function escapeLike(string $value): string
    {
        return str_replace(['\\', '%', '_'], ['\\\\', '\\%', '\\_'], $value);
    }
}
