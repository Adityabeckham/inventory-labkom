<?php
declare(strict_types=1);

namespace App\Core;

use Throwable;

/**
 * Router sederhana: cocokkan method + pola path, jalankan handler.
 * Pola mendukung parameter dalam kurung kurawal, mis. /api/peminjaman/{id}.
 */
final class Router
{
    /** @var list<array{method:string,pattern:string,handler:callable,middleware:list<callable>}> */
    private array $routes = [];

    /** @param list<callable> $middleware */
    public function get(string $pattern, callable $handler, array $middleware = []): void
    {
        $this->add('GET', $pattern, $handler, $middleware);
    }

    /** @param list<callable> $middleware */
    public function post(string $pattern, callable $handler, array $middleware = []): void
    {
        $this->add('POST', $pattern, $handler, $middleware);
    }

    /** @param list<callable> $middleware */
    public function put(string $pattern, callable $handler, array $middleware = []): void
    {
        $this->add('PUT', $pattern, $handler, $middleware);
    }

    /** @param list<callable> $middleware */
    public function patch(string $pattern, callable $handler, array $middleware = []): void
    {
        $this->add('PATCH', $pattern, $handler, $middleware);
    }

    /** @param list<callable> $middleware */
    public function delete(string $pattern, callable $handler, array $middleware = []): void
    {
        $this->add('DELETE', $pattern, $handler, $middleware);
    }

    /** @param list<callable> $middleware */
    private function add(string $method, string $pattern, callable $handler, array $middleware): void
    {
        $this->routes[] = [
            'method'     => $method,
            'pattern'    => '/' . trim($pattern, '/'),
            'handler'    => $handler,
            'middleware' => $middleware,
        ];
    }

    public function dispatch(Request $request): void
    {
        $pathMatched = false;

        foreach ($this->routes as $route) {
            $params = $this->match($route['pattern'], $request->path);
            if ($params === null) {
                continue;
            }

            $pathMatched = true;
            if ($route['method'] !== $request->method) {
                continue;
            }

            $request->setParams($params);

            try {
                foreach ($route['middleware'] as $middleware) {
                    $middleware($request);
                }
                ($route['handler'])($request);
            } catch (Throwable $e) {
                $this->handleException($e);
            }

            return;
        }

        // Path cocok tapi method salah → 405, bukan 404.
        $pathMatched
            ? Response::error('Method tidak diizinkan untuk endpoint ini.', 405)
            : Response::error('Endpoint tidak ditemukan.', 404);
    }

    /** @return array<string,string>|null null kalau tidak cocok */
    private function match(string $pattern, string $path): ?array
    {
        $regex = preg_replace('#\{([a-zA-Z_][a-zA-Z0-9_]*)\}#', '(?P<$1>[^/]+)', $pattern);
        if (preg_match('#^' . $regex . '$#', $path, $matches) !== 1) {
            return null;
        }

        return array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);
    }

    private function handleException(Throwable $e): never
    {
        $debug = (bool) Config::get('app.debug', false);

        if ($e instanceof HttpException) {
            Response::error($e->getMessage(), $e->getCode() ?: 400);
        }

        error_log('[inventory-labkom] ' . $e::class . ': ' . $e->getMessage());

        Response::error(
            $debug ? $e->getMessage() : 'Terjadi kesalahan pada server.',
            500
        );
    }
}
