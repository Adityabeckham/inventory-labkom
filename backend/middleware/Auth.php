<?php
declare(strict_types=1);

namespace App\Middleware;

use App\Core\HttpException;
use App\Core\Jwt;
use App\Core\Request;
use InvalidArgumentException;

/**
 * Otorisasi berbasis role — ditegakkan di backend, bukan cuma disembunyikan di UI.
 *
 * Sesuai Tabel 3.1 Use Case skripsi, Kepala Program (super_admin) hanya boleh
 * Login, Verifikasi, dan Lihat Laporan. Endpoint kelola barang/peminjam/user/
 * pengaturan harus dibatasi ke Laboran (admin) walaupun URL-nya diketahui.
 */
final class Auth
{
    public const LABORAN        = 'admin';
    public const KEPALA_PROGRAM = 'super_admin';

    /** Pengguna terautentikasi pada request yang sedang berjalan. */
    private static ?array $user = null;

    /** Wajib login, level apa pun. */
    public static function required(): callable
    {
        return static function (Request $request): void {
            self::$user = self::authenticate($request);
        };
    }

    /**
     * Wajib login DAN level tertentu.
     *
     * @param string ...$levels satu atau lebih dari Auth::LABORAN / Auth::KEPALA_PROGRAM
     */
    public static function role(string ...$levels): callable
    {
        return static function (Request $request) use ($levels): void {
            $user = self::authenticate($request);

            if (!in_array($user['level'] ?? '', $levels, true)) {
                throw HttpException::forbidden(
                    'Level akun Anda tidak diizinkan mengakses endpoint ini.'
                );
            }

            self::$user = $user;
        };
    }

    /** @return array{id_user:int,username:string,level:string} */
    public static function user(): array
    {
        if (self::$user === null) {
            throw HttpException::unauthorized();
        }

        return [
            'id_user'  => (int) self::$user['sub'],
            'username' => (string) self::$user['username'],
            'level'    => (string) self::$user['level'],
        ];
    }

    /** @return array<string,mixed> payload token */
    private static function authenticate(Request $request): array
    {
        $token = $request->bearerToken();
        if ($token === null) {
            throw HttpException::unauthorized('Header Authorization: Bearer <token> tidak ditemukan.');
        }

        try {
            return Jwt::decode($token);
        } catch (InvalidArgumentException $e) {
            throw HttpException::unauthorized($e->getMessage());
        }
    }
}
