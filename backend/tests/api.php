<?php
declare(strict_types=1);

/**
 * Black Box Testing — menguji API lewat HTTP, tanpa melihat isi kodenya.
 * Metode ini yang dipakai skripsi (BAB II: pengujian black box).
 *
 * Prasyarat: server backend jalan dan database sudah di-import.
 *
 *   php -S 127.0.0.1:8080 -t backend/public &
 *   php backend/tests/api.php [base-url]
 *
 * Skrip ini membuat lalu menghapus akun uji. Jalankan pada database
 * development, bukan data sungguhan.
 */

$BASE = rtrim($argv[1] ?? 'http://127.0.0.1:8080', '/');

$pass = 0;
$fail = 0;

/**
 * @param array<string,mixed>|null $body
 * @return array{status:int,json:array<string,mixed>|null,raw:string}
 */
function req(string $method, string $path, ?array $body = null, ?string $token = null): array
{
    global $BASE;

    $headers = ['Accept: application/json'];
    if ($body !== null)  { $headers[] = 'Content-Type: application/json'; }
    if ($token !== null) { $headers[] = "Authorization: Bearer $token"; }

    $ch = curl_init($BASE . $path);
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST  => $method,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER     => $headers,
        CURLOPT_TIMEOUT        => 10,
    ]);
    if ($body !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body, JSON_THROW_ON_ERROR));
    }

    // Handle ditutup otomatis saat $ch keluar dari scope (PHP 8.0+).
    $raw    = (string) curl_exec($ch);
    $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err    = curl_error($ch);

    if ($err !== '') {
        fwrite(STDERR, "\n  Tidak bisa menghubungi $BASE — apakah servernya jalan?\n  $err\n\n");
        exit(1);
    }

    $json = json_decode($raw, true);

    return ['status' => $status, 'json' => is_array($json) ? $json : null, 'raw' => $raw];
}

function ok(string $name, bool $cond, string $note = ''): void
{
    global $pass, $fail;
    if ($cond) { $pass++; echo "  \033[32mok\033[0m    $name\n"; return; }
    $fail++;
    echo "  \033[31mFAIL\033[0m  $name" . ($note !== '' ? "\n         $note" : '') . "\n";
}

/** @param array{status:int,json:array<string,mixed>|null,raw:string} $res */
function status(string $name, array $res, int $expected): void
{
    ok($name, $res['status'] === $expected, "dapat HTTP {$res['status']}: " . substr($res['raw'], 0, 160));
}

echo "\nBlack Box Testing — $BASE\n";

// ── FR-01 Autentikasi ────────────────────────────────────────────────
echo "\nFR-01 Autentikasi\n";

$r = req('GET', '/api/health');
status('health endpoint hidup', $r, 200);
ok('database terhubung', ($r['json']['data']['database'] ?? '') === 'connected',
   'seed database belum di-import, atau kredensial config.php salah');

$r = req('POST', '/api/auth/login', ['username' => 'laboran', 'password' => 'laboran123']);
status('login Laboran berhasil', $r, 200);
$tokenLaboran = $r['json']['data']['token'] ?? null;
ok('token diterbitkan', is_string($tokenLaboran) && substr_count((string) $tokenLaboran, '.') === 2);
ok('level dipetakan ke peran "Laboran"', ($r['json']['data']['user']['peran'] ?? '') === 'Laboran');
ok('hash password tidak ikut terkirim', !str_contains($r['raw'], '$2y$'));

$r = req('POST', '/api/auth/login', ['username' => 'kaprog', 'password' => 'kaprog123']);
status('login Kepala Program berhasil', $r, 200);
$tokenKaprog = $r['json']['data']['token'] ?? null;
ok('level dipetakan ke peran "Kepala Program"', ($r['json']['data']['user']['peran'] ?? '') === 'Kepala Program');

$salah = req('POST', '/api/auth/login', ['username' => 'laboran', 'password' => 'password-salah']);
$hantu = req('POST', '/api/auth/login', ['username' => 'akun-tidak-ada', 'password' => 'apa saja']);
status('password salah ditolak', $salah, 401);
status('username tidak dikenal ditolak', $hantu, 401);
ok('pesan penolakan identik (tidak bisa dipakai menebak username)',
   ($salah['json']['message'] ?? 'a') === ($hantu['json']['message'] ?? 'b'));

status('login tanpa password ditolak', req('POST', '/api/auth/login', ['username' => 'laboran']), 422);

$r = req('POST', '/api/auth/login', ['username' => 'laboran', 'password' => 'laboran123', 'remember_me' => true]);
ok('"Ingat saya" memperpanjang masa berlaku token',
   ($r['json']['data']['expires_in'] ?? 0) > 86400,
   'expires_in = ' . ($r['json']['data']['expires_in'] ?? '?'));

status('/api/auth/me perlu token', req('GET', '/api/auth/me'), 401);
status('/api/auth/me dengan token sah', req('GET', '/api/auth/me', null, $tokenLaboran), 200);

// ── Otorisasi berbasis peran ─────────────────────────────────────────
echo "\nOtorisasi (Tabel 3.1 Use Case)\n";

status('Laboran boleh lihat daftar akun',  req('GET', '/api/users', null, $tokenLaboran), 200);
status('Kepala Program DITOLAK kelola user', req('GET', '/api/users', null, $tokenKaprog), 403);
status('tanpa token ditolak',               req('GET', '/api/users'), 401);
status('token karangan ditolak',            req('GET', '/api/users', null, 'bukan.token.asli'), 401);

// ── FR-12 Kelola User ────────────────────────────────────────────────
echo "\nFR-12 Kelola User\n";

$uji = 'uji_' . substr(hash('sha256', (string) getmypid()), 0, 8);

$r = req('POST', '/api/users', ['username' => $uji, 'password' => 'rahasia123', 'level' => 'admin'], $tokenLaboran);
status('buat akun baru', $r, 201);
$idUji = $r['json']['data']['id_user'] ?? null;

status('username duplikat ditolak',
    req('POST', '/api/users', ['username' => $uji, 'password' => 'rahasia123', 'level' => 'admin'], $tokenLaboran), 409);
status('password terlalu pendek ditolak',
    req('POST', '/api/users', ['username' => $uji . 'b', 'password' => 'abc', 'level' => 'admin'], $tokenLaboran), 422);
status('level tidak dikenal ditolak',
    req('POST', '/api/users', ['username' => $uji . 'c', 'password' => 'rahasia123', 'level' => 'dewa'], $tokenLaboran), 422);
status('ID bukan angka ditolak', req('GET', '/api/users/abc', null, $tokenLaboran), 400);
status('ID tidak ada -> 404',    req('GET', '/api/users/99999999', null, $tokenLaboran), 404);

if (is_int($idUji)) {
    status('reset password oleh Laboran (alur "Lupa Password")',
        req('PUT', "/api/users/$idUji", ['password' => 'passwordbaru123'], $tokenLaboran), 200);
    status('login dengan password baru berhasil',
        req('POST', '/api/auth/login', ['username' => $uji, 'password' => 'passwordbaru123']), 200);
    status('password lama sudah tidak berlaku',
        req('POST', '/api/auth/login', ['username' => $uji, 'password' => 'rahasia123']), 401);
    status('hapus akun uji', req('DELETE', "/api/users/$idUji", null, $tokenLaboran), 200);
    status('akun uji benar-benar hilang', req('GET', "/api/users/$idUji", null, $tokenLaboran), 404);
} else {
    ok('akun uji dibuat (langkah lanjutan dilewati)', false, 'id_user tidak terbaca dari respons');
}

// ── Pengaman yang mencegah aplikasi terkunci ─────────────────────────
echo "\nPengaman\n";

$me = req('GET', '/api/auth/me', null, $tokenLaboran)['json']['data']['id_user'] ?? null;
if (is_int($me)) {
    status('tidak bisa menghapus akun sendiri',
        req('DELETE', "/api/users/$me", null, $tokenLaboran), 409);
    status('tidak bisa menurunkan level Laboran terakhir',
        req('PUT', "/api/users/$me", ['level' => 'super_admin'], $tokenLaboran), 409);
}

// ── Hasil ────────────────────────────────────────────────────────────
$total = $pass + $fail;
echo "\n  $pass/$total lolos\n\n";

exit($fail === 0 ? 0 : 1);
