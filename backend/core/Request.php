<?php
declare(strict_types=1);

namespace App\Core;

final class Request
{
    /** @var array<string,mixed> */
    private array $body;
    /** @var array<string,string> */
    private array $params = [];

    public function __construct(
        public readonly string $method,
        public readonly string $path,
    ) {
        $raw = file_get_contents('php://input') ?: '';
        $decoded = json_decode($raw, true);
        $this->body = is_array($decoded) ? $decoded : $_POST;
    }

    public static function fromGlobals(): self
    {
        $method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
        $path   = (string) (parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/');

        // Buang prefix tempat aplikasi dipasang, supaya pola route tetap
        // ditulis absolut (/api/health) di mana pun backend di-deploy.
        //
        //   php -S / DocumentRoot -> SCRIPT_NAME /index.php            -> prefix '' (tidak dipotong)
        //   Alias /inventory      -> SCRIPT_NAME /inventory/index.php  -> prefix '/inventory'
        $base = rtrim(str_replace('\\', '/', dirname((string) ($_SERVER['SCRIPT_NAME'] ?? ''))), '/');

        if ($base !== '' && $base !== '/' && str_starts_with($path, $base)) {
            $path = substr($path, strlen($base));
        }

        return new self($method, '/' . trim($path, '/'));
    }

    public function input(string $key, mixed $default = null): mixed
    {
        return $this->body[$key] ?? $default;
    }

    /** @return array<string,mixed> */
    public function all(): array
    {
        return $this->body;
    }

    public function query(string $key, mixed $default = null): mixed
    {
        return $_GET[$key] ?? $default;
    }

    /** Parameter dari pola route, mis. /api/peminjaman/{id} */
    public function param(string $key, ?string $default = null): ?string
    {
        return $this->params[$key] ?? $default;
    }

    /** @param array<string,string> $params */
    public function setParams(array $params): void
    {
        $this->params = $params;
    }

    public function bearerToken(): ?string
    {
        $header = $_SERVER['HTTP_AUTHORIZATION']
            ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
            ?? '';

        if ($header === '' && function_exists('apache_request_headers')) {
            $headers = array_change_key_case(apache_request_headers(), CASE_LOWER);
            $header  = $headers['authorization'] ?? '';
        }

        if (preg_match('/^Bearer\s+(\S+)$/i', (string) $header, $m) === 1) {
            return $m[1];
        }

        return null;
    }
}
