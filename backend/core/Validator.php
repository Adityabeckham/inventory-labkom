<?php
declare(strict_types=1);

namespace App\Core;

/**
 * Validasi input request. Setiap kegagalan langsung dilempar sebagai
 * HttpException 422 supaya controller tidak perlu memeriksa ulang.
 */
final class Validator
{
    /** Ambil string wajib yang tidak boleh kosong setelah di-trim. */
    public static function requiredString(Request $r, string $field, int $max = 255): string
    {
        $value = $r->input($field);

        if (!is_scalar($value)) {
            throw HttpException::unprocessable("Field '$field' wajib diisi.");
        }

        $value = trim((string) $value);
        if ($value === '') {
            throw HttpException::unprocessable("Field '$field' wajib diisi.");
        }
        if (mb_strlen($value) > $max) {
            throw HttpException::unprocessable("Field '$field' maksimal $max karakter.");
        }

        return $value;
    }

    /** String opsional — mengembalikan null kalau tidak dikirim atau kosong. */
    public static function optionalString(Request $r, string $field, int $max = 255): ?string
    {
        $value = $r->input($field);
        if ($value === null || (is_string($value) && trim($value) === '')) {
            return null;
        }
        if (!is_scalar($value)) {
            throw HttpException::unprocessable("Field '$field' tidak valid.");
        }

        $value = trim((string) $value);
        if (mb_strlen($value) > $max) {
            throw HttpException::unprocessable("Field '$field' maksimal $max karakter.");
        }

        return $value;
    }

    /** @param list<string> $allowed */
    public static function enum(Request $r, string $field, array $allowed): string
    {
        $value = self::requiredString($r, $field);
        if (!in_array($value, $allowed, true)) {
            throw HttpException::unprocessable(
                "Field '$field' harus salah satu dari: " . implode(', ', $allowed) . '.'
            );
        }

        return $value;
    }

    public static function password(Request $r, string $field = 'password'): string
    {
        $value = $r->input($field);
        if (!is_string($value) || $value === '') {
            throw HttpException::unprocessable('Password wajib diisi.');
        }
        if (mb_strlen($value) < 8) {
            throw HttpException::unprocessable('Password minimal 8 karakter.');
        }
        // Batas bcrypt: byte ke-73 dan seterusnya diabaikan diam-diam.
        if (strlen($value) > 72) {
            throw HttpException::unprocessable('Password maksimal 72 karakter.');
        }

        return $value;
    }

    public static function bool(Request $r, string $field, bool $default = false): bool
    {
        $value = $r->input($field, $default);

        return filter_var($value, FILTER_VALIDATE_BOOL, FILTER_NULL_ON_FAILURE) ?? $default;
    }

    /** ID dari parameter route, harus bilangan bulat positif. */
    public static function id(Request $r, string $param = 'id'): int
    {
        $value = $r->param($param);
        if ($value === null || preg_match('/^\d+$/', $value) !== 1 || (int) $value < 1) {
            throw HttpException::badRequest('ID tidak valid.');
        }

        return (int) $value;
    }
}
