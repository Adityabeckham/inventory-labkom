<?php
declare(strict_types=1);

namespace App\Core;

use RuntimeException;

final class Config
{
    /** @var array<string,mixed>|null */
    private static ?array $items = null;

    public static function load(string $path): void
    {
        if (!is_file($path)) {
            throw new RuntimeException(
                "config.php belum ada. Jalankan: cp config/config.example.php config/config.php"
            );
        }
        self::$items = require $path;
    }

    /** Ambil nilai konfigurasi, mendukung notasi titik: Config::get('db.host') */
    public static function get(string $key, mixed $default = null): mixed
    {
        if (self::$items === null) {
            throw new RuntimeException('Config belum di-load.');
        }

        $value = self::$items;
        foreach (explode('.', $key) as $segment) {
            if (!is_array($value) || !array_key_exists($segment, $value)) {
                return $default;
            }
            $value = $value[$segment];
        }

        return $value;
    }
}
