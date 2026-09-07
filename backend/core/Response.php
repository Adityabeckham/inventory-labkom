<?php
declare(strict_types=1);

namespace App\Core;

final class Response
{
    /** @param array<string,mixed>|list<mixed>|null $data */
    public static function json(mixed $data, int $status = 200): never
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function success(mixed $data = null, string $message = 'OK', int $status = 200): never
    {
        self::json(['status' => 'success', 'message' => $message, 'data' => $data], $status);
    }

    /** @param array<string,string> $errors */
    public static function error(string $message, int $status = 400, array $errors = []): never
    {
        $body = ['status' => 'error', 'message' => $message];
        if ($errors !== []) {
            $body['errors'] = $errors;
        }
        self::json($body, $status);
    }

    /**
     * Mengirim berkas biner sebagai lampiran unduhan.
     *
     * Isinya harus SUDAH selesai dibuat di memori sebelum memanggil ini.
     * Kalau pembuatan laporan gagal setengah jalan, blok catch di front
     * controller akan membalas JSON — dan JSON yang menempel di belakang
     * byte yang sudah terkirim menghasilkan berkas rusak yang terlihat
     * seperti bug library, bukan seperti error server.
     *
     * Buffer keluaran yang masih terbuka dibuang lebih dulu. Notice atau
     * deprecation dari library (PHPWord 1.4 memancarkan satu di PHP 8.5)
     * akan menyusup ke dalam berkas kalau dibiarkan, dan `PK` di awal ZIP
     * berubah jadi teks peringatan.
     */
    public static function file(string $bytes, string $filename, string $mime): never
    {
        while (ob_get_level() > 0) {
            $sisa = (string) ob_get_clean();
            if ($sisa !== '') {
                error_log('[inventory-labkom] keluaran liar sebelum berkas: '
                    . substr($sisa, 0, 500));
            }
        }

        http_response_code(200);
        header('Content-Type: ' . $mime);
        // Nama berkas dikutip; koma dan spasi di dalamnya akan memotong
        // header ini kalau dibiarkan tanpa kutip.
        header('Content-Disposition: attachment; filename="' . $filename . '"');
        header('Content-Length: ' . strlen($bytes));
        header('X-Content-Type-Options: nosniff');
        header('Cache-Control: no-store');

        echo $bytes;
        exit;
    }
}
