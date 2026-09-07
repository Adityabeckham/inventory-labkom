<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Config;
use App\Core\Database;
use App\Core\HttpException;
use App\Core\Jwt;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;
use App\Middleware\Auth;

/** FR-01 — Autentikasi. */
final class AuthController
{
    public function login(Request $request): void
    {
        $username = Validator::requiredString($request, 'username', 50);
        $password = $request->input('password');
        $remember = Validator::bool($request, 'remember_me');

        if (!is_string($password) || $password === '') {
            throw HttpException::unprocessable('Password wajib diisi.');
        }

        $user = Database::selectOne(
            'SELECT id_user, username, password, level, nip FROM users WHERE username = :u',
            ['u' => $username]
        );

        // Pesan yang sama untuk "user tidak ada" dan "password salah" — kalau
        // dibedakan, endpoint ini jadi alat menebak username yang valid.
        // password_verify tetap dijalankan atas hash palsu supaya waktu balasan
        // tidak membocorkan apakah username-nya ada.
        $hash  = $user['password'] ?? '$2y$10$invalidinvalidinvalidinvalidinvalidinvalidinvalidinvalidinv';
        $valid = password_verify($password, $hash);

        if ($user === null || !$valid) {
            throw HttpException::unauthorized('Username atau password salah.');
        }

        $ttl = $remember
            ? (int) Config::get('jwt.ttl_remember_me', 2592000)
            : (int) Config::get('jwt.ttl', 3600);

        $token = Jwt::encode([
            'sub'      => (int) $user['id_user'],
            'username' => $user['username'],
            'level'    => $user['level'],
        ], $ttl);

        Response::success([
            'token'      => $token,
            'token_type' => 'Bearer',
            'expires_in' => $ttl,
            'user'       => self::publicUser($user),
        ], 'Login berhasil.');
    }

    /** Data akun yang sedang login — dipakai Flutter untuk memulihkan sesi. */
    public function me(Request $request): void
    {
        $current = Auth::user();

        $user = Database::selectOne(
            'SELECT id_user, username, level, nip FROM users WHERE id_user = :id',
            ['id' => $current['id_user']]
        );

        // Token masih sah tapi akunnya sudah dihapus lewat Kelola User.
        if ($user === null) {
            throw HttpException::unauthorized('Akun sudah tidak tersedia.');
        }

        Response::success(self::publicUser($user), 'Profil pengguna.');
    }

    /** Memperbarui profil akun sendiri (username, nip). */
    public function updateProfile(Request $request): void
    {
        $current  = Auth::user();
        $idUser   = (int) $current['id_user'];
        $username = Validator::requiredString($request, 'username', 50);
        $nip      = $request->input('nip');
        $nip      = is_string($nip) && trim($nip) !== '' ? trim($nip) : null;

        $exists = Database::selectOne(
            'SELECT id_user FROM users WHERE username = :u AND id_user != :id',
            ['u' => $username, 'id' => $idUser]
        );
        if ($exists !== null) {
            throw HttpException::conflict('Username sudah digunakan oleh akun lain.');
        }

        Database::execute(
            'UPDATE users SET username = :u, nip = :n WHERE id_user = :id',
            ['u' => $username, 'n' => $nip, 'id' => $idUser]
        );

        $user = Database::selectOne(
            'SELECT id_user, username, level, nip FROM users WHERE id_user = :id',
            ['id' => $idUser]
        );

        Response::success(self::publicUser($user), 'Profil berhasil diperbarui.');
    }

    /** Memperbarui password akun sendiri. */
    public function changePassword(Request $request): void
    {
        $current     = Auth::user();
        $idUser      = (int) $current['id_user'];
        $oldPassword = $request->input('old_password');
        $newPassword = $request->input('new_password');

        if (!is_string($oldPassword) || $oldPassword === '') {
            throw HttpException::unprocessable('Password lama wajib diisi.');
        }
        if (!is_string($newPassword) || strlen($newPassword) < 6) {
            throw HttpException::unprocessable('Password baru minimal 6 karakter.');
        }

        $user = Database::selectOne(
            'SELECT password FROM users WHERE id_user = :id',
            ['id' => $idUser]
        );
        if ($user === null || !password_verify($oldPassword, $user['password'])) {
            throw HttpException::unauthorized('Password lama tidak sesuai.');
        }

        $hash = password_hash($newPassword, PASSWORD_BCRYPT);
        Database::execute(
            'UPDATE users SET password = :p WHERE id_user = :id',
            ['p' => $hash, 'id' => $idUser]
        );

        Response::success(null, 'Password berhasil diperbarui.');
    }

    /**
     * @param array<string,mixed> $row
     * @return array<string,mixed>
     */
    public static function publicUser(array $row): array
    {
        return [
            'id_user'  => (int) $row['id_user'],
            'username' => $row['username'],
            'level'    => $row['level'],
            // Nama peran sesuai istilah skripsi, supaya UI tidak perlu memetakan sendiri.
            'peran'    => $row['level'] === Auth::LABORAN ? 'Laboran' : 'Kepala Program',
            'nip'      => $row['nip'] ?? null,
        ];
    }
}
