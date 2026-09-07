<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Database;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;

/**
 * FR-04 — Kelola Peminjam.
 *
 * Peminjam adalah siswa/guru/staf yang meminjam barang. Mereka TIDAK punya
 * akun untuk masuk ke aplikasi — itu tabel `users` (FR-12 Kelola User).
 */
final class PeminjamController
{
    public function index(Request $request): void
    {
        $sql    = 'SELECT * FROM peminjam';
        $params = [];

        $cari = trim((string) ($request->query('cari') ?? ''));
        if ($cari !== '') {
            // Placeholder terpisah per kolom — lihat catatan yang sama di
            // BarangController: named placeholder tidak boleh diulang.
            $sql .= ' WHERE nama_peminjam LIKE :cari1 OR nis_nip LIKE :cari2 '
                  . 'OR kelas_jabatan LIKE :cari3';
            $pola = '%' . str_replace(['\\', '%', '_'], ['\\\\', '\\%', '\\_'], $cari) . '%';
            $params += ['cari1' => $pola, 'cari2' => $pola, 'cari3' => $pola];
        }

        $sql .= ' ORDER BY nama_peminjam';

        Response::success(
            array_map(self::present(...), Database::select($sql, $params)),
            'Daftar peminjam.'
        );
    }

    public function show(Request $request): void
    {
        Response::success(self::findOrFail(Validator::id($request)), 'Detail peminjam.');
    }

    public function store(Request $request): void
    {
        $data = self::validated($request);
        self::assertNisNipFree($data['nis_nip']);

        Database::execute(
            'INSERT INTO peminjam (nama_peminjam, nis_nip, kelas_jabatan, no_hp)
             VALUES (:nama_peminjam, :nis_nip, :kelas_jabatan, :no_hp)',
            $data
        );

        Response::success(self::findOrFail(Database::lastInsertId()), 'Peminjam ditambahkan.', 201);
    }

    public function update(Request $request): void
    {
        $id = Validator::id($request);
        self::findOrFail($id);

        $data = self::validated($request);
        self::assertNisNipFree($data['nis_nip'], $id);
        $data['id'] = $id;

        Database::execute(
            'UPDATE peminjam SET
                nama_peminjam = :nama_peminjam,
                nis_nip       = :nis_nip,
                kelas_jabatan = :kelas_jabatan,
                no_hp         = :no_hp
             WHERE id_peminjam = :id',
            $data
        );

        Response::success(self::findOrFail($id), 'Data peminjam diperbarui.');
    }

    public function destroy(Request $request): void
    {
        $id = Validator::id($request);
        self::findOrFail($id);

        $row = Database::selectOne(
            'SELECT COUNT(*) AS n FROM peminjaman WHERE id_peminjam = :id',
            ['id' => $id]
        );
        $jumlah = (int) ($row['n'] ?? 0);

        if ($jumlah > 0) {
            throw HttpException::conflict(
                "Peminjam ini punya $jumlah riwayat peminjaman, jadi tidak bisa dihapus. "
                . 'Menghapusnya akan membuat riwayat transaksi kehilangan acuan.'
            );
        }

        Database::execute('DELETE FROM peminjam WHERE id_peminjam = :id', ['id' => $id]);

        Response::success(null, 'Peminjam dihapus.');
    }

    /** @return array<string,mixed> */
    private static function validated(Request $request): array
    {
        return [
            'nama_peminjam' => Validator::requiredString($request, 'nama_peminjam', 100),
            'nis_nip'       => Validator::optionalString($request, 'nis_nip', 30),
            'kelas_jabatan' => Validator::optionalString($request, 'kelas_jabatan', 50),
            'no_hp'         => Validator::optionalString($request, 'no_hp', 20),
        ];
    }

    /** @param array<string,mixed> $row */
    private static function present(array $row): array
    {
        return [
            'id_peminjam'   => (int) $row['id_peminjam'],
            'nama_peminjam' => $row['nama_peminjam'],
            'nis_nip'       => $row['nis_nip'],
            'kelas_jabatan' => $row['kelas_jabatan'],
            'no_hp'         => $row['no_hp'],
        ];
    }

    /** @return array<string,mixed> */
    private static function findOrFail(int $id): array
    {
        $row = Database::selectOne(
            'SELECT * FROM peminjam WHERE id_peminjam = :id',
            ['id' => $id]
        );

        if ($row === null) {
            throw HttpException::notFound('Peminjam tidak ditemukan.');
        }

        return self::present($row);
    }

    /**
     * NIS/NIP tidak diberi UNIQUE di skema (mengikuti Database_Final v1.5),
     * tapi duplikatnya dicegah di sini — dua siswa dengan NIS sama hampir
     * pasti salah input, dan akan menyulitkan saat menelusuri peminjaman.
     */
    private static function assertNisNipFree(?string $nisNip, ?int $exceptId = null): void
    {
        if ($nisNip === null || $nisNip === '') {
            return;
        }

        $sql    = 'SELECT id_peminjam FROM peminjam WHERE nis_nip = :nis';
        $params = ['nis' => $nisNip];

        if ($exceptId !== null) {
            $sql .= ' AND id_peminjam <> :id';
            $params['id'] = $exceptId;
        }

        if (Database::selectOne($sql, $params) !== null) {
            throw HttpException::conflict("NIS/NIP '$nisNip' sudah terdaftar atas nama lain.");
        }
    }
}
