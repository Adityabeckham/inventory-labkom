<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Database;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;
use App\Middleware\Auth;

/**
 * FR-12 — Kelola User (akun login Laboran & Kepala Program).
 *
 * Berbeda dari Data Peminjam (FR-04): peminjam adalah siswa/guru yang
 * meminjam barang dan tidak punya akun untuk masuk ke aplikasi.
 *
 * Seluruh endpoint di sini dibatasi ke Laboran lewat Auth::role() di routes.
 */
final class UserController
{
    private const LEVELS = [Auth::LABORAN, Auth::KEPALA_PROGRAM];

    public function index(Request $request): void
    {
        $users = Database::select(
            'SELECT id_user, username, level, nip, created_at FROM users ORDER BY username'
        );

        Response::success(
            array_map(static fn(array $u): array => AuthController::publicUser($u) + [
                'created_at' => $u['created_at'],
            ], $users),
            'Daftar akun pengguna.'
        );
    }

    public function show(Request $request): void
    {
        Response::success(self::findOrFail(Validator::id($request)), 'Detail akun.');
    }

    public function store(Request $request): void
    {
        $username = Validator::requiredString($request, 'username', 50);
        $password = Validator::password($request);
        $level    = Validator::enum($request, 'level', self::LEVELS);
        $nip      = Validator::optionalString($request, 'nip', 30);

        self::assertUsernameFree($username);

        Database::execute(
            'INSERT INTO users (username, password, level, nip)
             VALUES (:username, :password, :level, :nip)',
            [
                'username' => $username,
                'password' => password_hash($password, PASSWORD_BCRYPT),
                'level'    => $level,
                'nip'      => $nip,
            ]
        );

        Response::success(self::findOrFail(Database::lastInsertId()), 'Akun berhasil dibuat.', 201);
    }

    public function update(Request $request): void
    {
        $id = Validator::id($request);
        self::findOrFail($id);

        $fields = [];
        $params = ['id' => $id];

        if ($request->input('username') !== null) {
            $username = Validator::requiredString($request, 'username', 50);
            self::assertUsernameFree($username, $id);
            $fields[] = 'username = :username';
            $params['username'] = $username;
        }

        // Password opsional: dikirim hanya kalau memang diganti. Ini juga jalur
        // reset password manual oleh Laboran ("Lupa Password" di layar Login).
        if ($request->input('password') !== null) {
            $fields[] = 'password = :password';
            $params['password'] = password_hash(Validator::password($request), PASSWORD_BCRYPT);
        }

        if ($request->input('level') !== null) {
            $level = Validator::enum($request, 'level', self::LEVELS);
            // Menurunkan level Laboran terakhir mengunci semua orang keluar dari
            // fitur kelola — tidak akan ada lagi yang bisa membuat akun baru.
            if ($level !== Auth::LABORAN) {
                self::assertNotLastLaboran($id, 'menurunkan level');
            }
            $fields[] = 'level = :level';
            $params['level'] = $level;
        }

        if (array_key_exists('nip', $request->all())) {
            $fields[] = 'nip = :nip';
            $params['nip'] = Validator::optionalString($request, 'nip', 30);
        }

        if ($fields === []) {
            throw HttpException::unprocessable('Tidak ada field yang diubah.');
        }

        Database::execute('UPDATE users SET ' . implode(', ', $fields) . ' WHERE id_user = :id', $params);

        Response::success(self::findOrFail($id), 'Akun berhasil diperbarui.');
    }

    public function destroy(Request $request): void
    {
        $id = Validator::id($request);
        self::findOrFail($id);

        if ($id === Auth::user()['id_user']) {
            throw HttpException::conflict('Tidak bisa menghapus akun yang sedang dipakai login.');
        }

        self::assertNotLastLaboran($id, 'menghapus');

        // peminjaman.id_user memakai ON DELETE RESTRICT — akun yang pernah
        // mencatat transaksi tidak boleh hilang, supaya jejak audit tetap utuh.
        $terpakai = Database::selectOne(
            'SELECT COUNT(*) AS n FROM peminjaman WHERE id_user = :id',
            ['id' => $id]
        );
        $mutasi = Database::selectOne(
            'SELECT COUNT(*) AS n FROM stok_mutasi WHERE id_user = :id',
            ['id' => $id]
        );

        $jumlah = (int) ($terpakai['n'] ?? 0) + (int) ($mutasi['n'] ?? 0);
        if ($jumlah > 0) {
            throw HttpException::conflict(
                "Akun ini tercatat pada $jumlah transaksi, jadi tidak bisa dihapus. "
                . 'Ubah passwordnya kalau akses perlu dicabut.'
            );
        }

        Database::execute('DELETE FROM users WHERE id_user = :id', ['id' => $id]);

        Response::success(null, 'Akun berhasil dihapus.');
    }

    /** @return array<string,mixed> */
    private static function findOrFail(int $id): array
    {
        $user = Database::selectOne(
            'SELECT id_user, username, level, nip, created_at FROM users WHERE id_user = :id',
            ['id' => $id]
        );

        if ($user === null) {
            throw HttpException::notFound('Akun tidak ditemukan.');
        }

        return AuthController::publicUser($user) + ['created_at' => $user['created_at']];
    }

    private static function assertUsernameFree(string $username, ?int $exceptId = null): void
    {
        $sql    = 'SELECT id_user FROM users WHERE username = :u';
        $params = ['u' => $username];

        if ($exceptId !== null) {
            $sql .= ' AND id_user <> :id';
            $params['id'] = $exceptId;
        }

        if (Database::selectOne($sql, $params) !== null) {
            throw HttpException::conflict("Username '$username' sudah dipakai.");
        }
    }

    private static function assertNotLastLaboran(int $id, string $aksi): void
    {
        $row = Database::selectOne(
            'SELECT COUNT(*) AS n FROM users WHERE level = :level AND id_user <> :id',
            ['level' => Auth::LABORAN, 'id' => $id]
        );

        if ((int) ($row['n'] ?? 0) === 0) {
            throw HttpException::conflict(
                "Ini satu-satunya akun Laboran yang tersisa — $aksi akan membuat "
                . 'tidak ada lagi yang bisa mengelola data.'
            );
        }
    }
}
