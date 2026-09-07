<?php
declare(strict_types=1);

/**
 * Pengujian kerangka backend — tanpa dependensi, tanpa database.
 *
 *   php backend/tests/run.php
 *
 * Menguji dua bagian yang paling rawan salah dan tidak kelihatan dari UI:
 * implementasi JWT tulis tangan, dan pencocokan route.
 */

require_once dirname(__DIR__) . '/bootstrap.php';

use App\Core\Config;
use App\Core\Jwt;
use App\Core\Request;
use App\Core\Router;

final class T
{
    public static int $pass = 0;
    public static int $fail = 0;

    public static function ok(string $name, bool $condition, string $note = ''): void
    {
        if ($condition) {
            self::$pass++;
            echo "  \033[32mok\033[0m    $name\n";
            return;
        }
        self::$fail++;
        echo "  \033[31mFAIL\033[0m  $name" . ($note !== '' ? " — $note" : '') . "\n";
    }

    /** Benar kalau $fn melempar exception. */
    public static function throws(string $name, callable $fn): void
    {
        try {
            $fn();
            self::ok($name, false, 'seharusnya ditolak, tapi diterima');
        } catch (Throwable) {
            self::ok($name, true);
        }
    }
}

/** Rakit JWT manual dengan secret yang benar — mensimulasikan penyerang yang tahu secret-nya bocor sebagian. */
function forge(array $header, array $payload): string
{
    $secret = (string) Config::get('jwt.secret');
    $b64 = static fn(string $s): string => rtrim(strtr(base64_encode($s), '+/', '-_'), '=');

    $h = $b64(json_encode($header, JSON_THROW_ON_ERROR));
    $p = $b64(json_encode($payload, JSON_THROW_ON_ERROR));
    $s = $b64(hash_hmac('sha256', "$h.$p", $secret, true));

    return "$h.$p.$s";
}

// ─── JWT ─────────────────────────────────────────────────────────────
echo "\nJWT\n";

$token = Jwt::encode(['sub' => 1, 'username' => 'laboran', 'level' => 'admin'], 3600);
$claims = Jwt::decode($token);

T::ok('round-trip mempertahankan klaim', $claims['sub'] === 1 && $claims['level'] === 'admin');
T::ok('klaim iss/iat/nbf/exp terisi otomatis', isset($claims['iss'], $claims['iat'], $claims['nbf'], $claims['exp']));

// Payload diubah tanpa menandatangani ulang — kenaikan hak akses paling umum.
$parts = explode('.', $token);
$tampered = json_decode(base64_decode(strtr($parts[1], '-_', '+/')), true);
$tampered['level'] = 'super_admin';
$parts[1] = rtrim(strtr(base64_encode(json_encode($tampered)), '+/', '-_'), '=');
T::throws('payload yang diubah ditolak', static fn() => Jwt::decode(implode('.', $parts)));

T::throws('serangan alg:none ditolak', static function (): void {
    $b64 = static fn(string $s): string => rtrim(strtr(base64_encode($s), '+/', '-_'), '=');
    Jwt::decode(
        $b64(json_encode(['typ' => 'JWT', 'alg' => 'none'])) . '.' .
        $b64(json_encode(['sub' => 1, 'level' => 'admin', 'exp' => time() + 3600])) . '.'
    );
});

T::throws('token kedaluwarsa ditolak', static fn() => Jwt::decode(Jwt::encode(['sub' => 1], -10)));

T::throws('token tanpa klaim exp ditolak', static fn() => Jwt::decode(
    forge(['typ' => 'JWT', 'alg' => 'HS256'], ['sub' => 1, 'level' => 'admin', 'iss' => Config::get('jwt.issuer')])
));

T::throws('token dari penerbit asing ditolak', static fn() => Jwt::decode(
    forge(['typ' => 'JWT', 'alg' => 'HS256'], ['sub' => 1, 'level' => 'admin', 'iss' => 'penyerang', 'exp' => time() + 3600])
));

T::throws('token belum berlaku (nbf masa depan) ditolak', static fn() => Jwt::decode(
    forge(['typ' => 'JWT', 'alg' => 'HS256'], [
        'sub' => 1, 'iss' => Config::get('jwt.issuer'),
        'nbf' => time() + 3600, 'exp' => time() + 7200,
    ])
));

foreach (['', 'abc', 'a.b', 'a.b.c.d'] as $junk) {
    T::throws("format sampah ditolak: '$junk'", static fn() => Jwt::decode($junk));
}

// ─── Router ──────────────────────────────────────────────────────────
echo "\nRouter\n";

/** Panggil Router::match() yang privat lewat reflection. */
function matchRoute(string $pattern, string $path): ?array
{
    // Sejak PHP 8.1 method privat sudah bisa langsung di-invoke lewat reflection.
    return (new ReflectionMethod(Router::class, 'match'))->invoke(new Router(), $pattern, $path);
}

T::ok('path statis cocok', matchRoute('/api/health', '/api/health') === []);
T::ok('path statis yang beda tidak cocok', matchRoute('/api/health', '/api/lain') === null);
T::ok('parameter tunggal terambil', matchRoute('/api/peminjaman/{id}', '/api/peminjaman/42') === ['id' => '42']);
T::ok('parameter tidak melewati garis miring', matchRoute('/api/peminjaman/{id}', '/api/peminjaman/42/verifikasi') === null);
T::ok(
    'dua parameter terambil',
    matchRoute('/api/{a}/{b}', '/api/x/y') === ['a' => 'x', 'b' => 'y']
);
T::ok(
    'sub-path bernama terambil (pola verifikasi)',
    matchRoute('/api/peminjaman/{id}/verifikasi', '/api/peminjaman/7/verifikasi') === ['id' => '7']
);
T::ok('prefix saja tidak dianggap cocok', matchRoute('/api/barang', '/api/barang/1') === null);

// ─── Request ─────────────────────────────────────────────────────────
echo "\nRequest\n";

$req = new Request('GET', '/api/health');
T::ok('param yang tidak ada mengembalikan default', $req->param('id', 'kosong') === 'kosong');
$req->setParams(['id' => '9']);
T::ok('param yang di-set terbaca', $req->param('id') === '9');

$_SERVER['HTTP_AUTHORIZATION'] = 'Bearer abc.def.ghi';
T::ok('bearer token terbaca dari header', (new Request('GET', '/'))->bearerToken() === 'abc.def.ghi');
$_SERVER['HTTP_AUTHORIZATION'] = 'Basic dXNlcjpwYXNz';
T::ok('skema Basic tidak dianggap bearer', (new Request('GET', '/'))->bearerToken() === null);
unset($_SERVER['HTTP_AUTHORIZATION']);

// Pola route ditulis absolut (/api/health), jadi prefix tempat aplikasi
// dipasang harus dibuang — kalau tidak, deploy lewat Alias membalas 404 total.
echo "\nRequest — normalisasi path per mode deploy\n";

/** @return string path hasil normalisasi */
function pathUntuk(string $scriptName, string $requestUri): string
{
    $_SERVER['SCRIPT_NAME']    = $scriptName;
    $_SERVER['REQUEST_URI']    = $requestUri;
    $_SERVER['REQUEST_METHOD'] = 'GET';

    return Request::fromGlobals()->path;
}

T::ok(
    'php -S / DocumentRoot: path dibiarkan apa adanya',
    pathUntuk('/index.php', '/api/health') === '/api/health'
);
T::ok(
    'Alias /inventory: prefix dibuang',
    pathUntuk('/inventory/index.php', '/inventory/api/health') === '/api/health'
);
T::ok(
    'sub-folder htdocs: prefix panjang dibuang, parameter utuh',
    pathUntuk('/labkom/backend/public/index.php', '/labkom/backend/public/api/peminjaman/42') === '/api/peminjaman/42'
);
T::ok(
    'query string tidak ikut masuk path',
    pathUntuk('/index.php', '/api/laporan/barang?format=pdf') === '/api/laporan/barang'
);
T::ok(
    'root tetap "/" bukan string kosong',
    pathUntuk('/index.php', '/') === '/'
);

// ─── Hasil ───────────────────────────────────────────────────────────
$total = T::$pass + T::$fail;
echo "\n" . ($total > 0 ? sprintf("  %d/%d lolos", T::$pass, $total) : '  tidak ada tes') . "\n\n";

exit(T::$fail === 0 ? 0 : 1);
