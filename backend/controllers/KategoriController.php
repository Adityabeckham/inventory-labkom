<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Database;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;

/** FR-03 — Kelola Kategori. */
final class KategoriController
{
    public function index(Request $request): void
    {
        // Sekalian bawa jumlah barang per kategori supaya UI bisa menampilkan
        // "Komputer (12)" tanpa perlu request tambahan per baris.
        $rows = Database::select(
            'SELECT k.id_kategori, k.nama_kategori, COUNT(b.id_barang) AS jumlah_barang
               FROM kategori k
          LEFT JOIN barang b ON b.id_kategori = k.id_kategori
           GROUP BY k.id_kategori, k.nama_kategori
           ORDER BY k.nama_kategori'
        );

        Response::success(array_map(self::present(...), $rows), 'Daftar kategori.');
    }

    public function store(Request $request): void
    {
        $nama = Validator::requiredString($request, 'nama_kategori', 100);
        self::assertNamaFree($nama);

        Database::execute(
            'INSERT INTO kategori (nama_kategori) VALUES (:nama)',
            ['nama' => $nama]
        );

        Response::success(self::findOrFail(Database::lastInsertId()), 'Kategori ditambahkan.', 201);
    }

    public function update(Request $request): void
    {
        $id = Validator::id($request);
        self::findOrFail($id);

        $nama = Validator::requiredString($request, 'nama_kategori', 100);
        self::assertNamaFree($nama, $id);

        Database::execute(
            'UPDATE kategori SET nama_kategori = :nama WHERE id_kategori = :id',
            ['nama' => $nama, 'id' => $id]
        );

        Response::success(self::findOrFail($id), 'Kategori diperbarui.');
    }

    public function destroy(Request $request): void
    {
        $id = Validator::id($request);
        self::findOrFail($id);

        // barang.id_kategori memakai ON DELETE RESTRICT. Dicek lebih dulu
        // supaya pengguna dapat penjelasan, bukan error SQL.
        $row = Database::selectOne(
            'SELECT COUNT(*) AS n FROM barang WHERE id_kategori = :id',
            ['id' => $id]
        );
        $jumlah = (int) ($row['n'] ?? 0);

        if ($jumlah > 0) {
            throw HttpException::conflict(
                "Kategori ini masih dipakai $jumlah barang. "
                . 'Pindahkan barangnya ke kategori lain dulu.'
            );
        }

        Database::execute('DELETE FROM kategori WHERE id_kategori = :id', ['id' => $id]);

        Response::success(null, 'Kategori dihapus.');
    }

    /** @param array<string,mixed> $row */
    private static function present(array $row): array
    {
        return [
            'id_kategori'   => (int) $row['id_kategori'],
            'nama_kategori' => $row['nama_kategori'],
            'jumlah_barang' => (int) ($row['jumlah_barang'] ?? 0),
        ];
    }

    /** @return array<string,mixed> */
    private static function findOrFail(int $id): array
    {
        $row = Database::selectOne(
            'SELECT k.id_kategori, k.nama_kategori, COUNT(b.id_barang) AS jumlah_barang
               FROM kategori k
          LEFT JOIN barang b ON b.id_kategori = k.id_kategori
              WHERE k.id_kategori = :id
           GROUP BY k.id_kategori, k.nama_kategori',
            ['id' => $id]
        );

        if ($row === null) {
            throw HttpException::notFound('Kategori tidak ditemukan.');
        }

        return self::present($row);
    }

    private static function assertNamaFree(string $nama, ?int $exceptId = null): void
    {
        $sql    = 'SELECT id_kategori FROM kategori WHERE nama_kategori = :nama';
        $params = ['nama' => $nama];

        if ($exceptId !== null) {
            $sql .= ' AND id_kategori <> :id';
            $params['id'] = $exceptId;
        }

        if (Database::selectOne($sql, $params) !== null) {
            throw HttpException::conflict("Kategori '$nama' sudah ada.");
        }
    }
}
