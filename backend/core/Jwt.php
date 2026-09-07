<?php
declare(strict_types=1);

namespace App\Core;

use InvalidArgumentException;
use RuntimeException;

/**
 * JWT HS256 minimal — tanpa dependensi Composer.
 *
 * Dipakai untuk autentikasi API (FR-01). Token dikirim Flutter di header
 * `Authorization: Bearer <token>` pada setiap request.
 */
final class Jwt
{
    private const ALGO = 'HS256';

    /**
     * @param array<string,mixed> $claims payload tambahan (sub, username, level)
     */
    public static function encode(array $claims, int $ttlSeconds): string
    {
        $now = time();
        $payload = array_merge($claims, [
            'iss' => Config::get('jwt.issuer'),
            'iat' => $now,
            'nbf' => $now,
            'exp' => $now + $ttlSeconds,
        ]);

        $segments = [
            self::base64UrlEncode(json_encode(['typ' => 'JWT', 'alg' => self::ALGO], JSON_THROW_ON_ERROR)),
            self::base64UrlEncode(json_encode($payload, JSON_THROW_ON_ERROR)),
        ];

        $signature = hash_hmac('sha256', implode('.', $segments), self::secret(), true);
        $segments[] = self::base64UrlEncode($signature);

        return implode('.', $segments);
    }

    /**
     * Verifikasi tanda tangan + masa berlaku.
     *
     * @return array<string,mixed> payload
     * @throws InvalidArgumentException kalau token tidak sah atau kedaluwarsa
     */
    public static function decode(string $token): array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            throw new InvalidArgumentException('Format token tidak valid.');
        }

        [$headerB64, $payloadB64, $signatureB64] = $parts;

        $expected = hash_hmac('sha256', $headerB64 . '.' . $payloadB64, self::secret(), true);
        $actual   = self::base64UrlDecode($signatureB64);

        // hash_equals mencegah timing attack saat membandingkan tanda tangan.
        if (!hash_equals($expected, $actual)) {
            throw new InvalidArgumentException('Tanda tangan token tidak cocok.');
        }

        $header = json_decode(self::base64UrlDecode($headerB64), true);
        if (!is_array($header) || ($header['alg'] ?? null) !== self::ALGO) {
            throw new InvalidArgumentException('Algoritma token tidak didukung.');
        }

        $payload = json_decode(self::base64UrlDecode($payloadB64), true);
        if (!is_array($payload)) {
            throw new InvalidArgumentException('Payload token tidak terbaca.');
        }

        // `iss` wajib cocok — token dari penerbit lain yang kebetulan memakai
        // secret sama tidak boleh diterima di sini.
        if (($payload['iss'] ?? null) !== Config::get('jwt.issuer')) {
            throw new InvalidArgumentException('Penerbit token tidak dikenali.');
        }

        // `exp` WAJIB ada. Tanpa pemeriksaan ini, token yang dirakit tanpa klaim
        // exp akan berlaku selamanya — logout dan rotasi sesi jadi tidak berarti.
        if (!isset($payload['exp'])) {
            throw new InvalidArgumentException('Token tidak punya masa berlaku.');
        }

        $now = time();
        if (isset($payload['nbf']) && $now < (int) $payload['nbf']) {
            throw new InvalidArgumentException('Token belum berlaku.');
        }
        if ($now >= (int) $payload['exp']) {
            throw new InvalidArgumentException('Token sudah kedaluwarsa.');
        }

        return $payload;
    }

    /** Dipakai bootstrap untuk gagal-cepat sebelum request diproses. */
    public static function assertSecretConfigured(): void
    {
        self::secret();
    }

    private static function secret(): string
    {
        $secret = (string) Config::get('jwt.secret', '');
        if ($secret === '' || str_starts_with($secret, 'GANTI-DENGAN')) {
            // RuntimeException, BUKAN InvalidArgumentException: yang terakhir
            // ditangkap Auth middleware dan diubah jadi 401, sehingga salah
            // konfigurasi server akan terlihat seperti kredensial pengguna salah.
            throw new RuntimeException(
                'jwt.secret belum diisi di config/config.php.'
            );
        }
        return $secret;
    }

    private static function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64UrlDecode(string $data): string
    {
        return (string) base64_decode(strtr($data, '-_', '+/'), true);
    }
}
