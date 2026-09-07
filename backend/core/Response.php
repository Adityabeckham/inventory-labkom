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
}
