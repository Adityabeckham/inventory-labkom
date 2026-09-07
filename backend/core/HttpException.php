<?php
declare(strict_types=1);

namespace App\Core;

use RuntimeException;

/** Error yang memang dimaksudkan untuk dikirim ke klien dengan status HTTP tertentu. */
final class HttpException extends RuntimeException
{
    public static function badRequest(string $message): self
    {
        return new self($message, 400);
    }

    public static function unauthorized(string $message = 'Autentikasi diperlukan.'): self
    {
        return new self($message, 401);
    }

    public static function forbidden(string $message = 'Anda tidak punya akses ke sumber daya ini.'): self
    {
        return new self($message, 403);
    }

    public static function notFound(string $message = 'Data tidak ditemukan.'): self
    {
        return new self($message, 404);
    }

    public static function conflict(string $message): self
    {
        return new self($message, 409);
    }

    public static function unprocessable(string $message): self
    {
        return new self($message, 422);
    }
}
