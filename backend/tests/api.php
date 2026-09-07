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
 * PERINGATAN: skrip ini menulis ke database. Sebagian data uji sengaja
 * ditinggalkan — barang yang sudah punya riwayat mutasi memang tidak boleh
 * dihapus, dan itu justru perilaku yang diuji. Jalankan HANYA pada database
 * development, lalu pulihkan keadaan bersih dengan:
 *
 *   mysql -u root < database/schema.sql && mysql -u root < database/seed.sql
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

// ── FR-03 Kelola Kategori ────────────────────────────────────────────
echo "\nFR-03 Kelola Kategori\n";

status('Kepala Program ditolak dari kategori',
    req('GET', '/api/kategori', null, $tokenKaprog), 403);

$r = req('GET', '/api/kategori', null, $tokenLaboran);
status('Laboran melihat daftar kategori', $r, 200);
ok('jumlah barang per kategori ikut dihitung',
   isset($r['json']['data'][0]['jumlah_barang']));

$namaKategori = 'Uji ' . substr(hash('sha256', (string) getmypid()), 0, 6);
$r = req('POST', '/api/kategori', ['nama_kategori' => $namaKategori], $tokenLaboran);
status('tambah kategori', $r, 201);
$idKategori = $r['json']['data']['id_kategori'] ?? null;

status('nama kategori duplikat ditolak',
    req('POST', '/api/kategori', ['nama_kategori' => $namaKategori], $tokenLaboran), 409);
status('nama kategori kosong ditolak',
    req('POST', '/api/kategori', ['nama_kategori' => '   '], $tokenLaboran), 422);
status('kategori yang masih dipakai barang tidak bisa dihapus',
    req('DELETE', '/api/kategori/1', null, $tokenLaboran), 409);

// ── FR-02 Kelola Barang ──────────────────────────────────────────────
echo "\nFR-02 Kelola Barang\n";

$r = req('GET', '/api/barang', null, $tokenLaboran);
status('daftar barang', $r, 200);
ok('nama kategori ikut di-join', isset($r['json']['data'][0]['nama_kategori']));

$r = req('GET', '/api/barang?id_kategori=1', null, $tokenLaboran);
status('filter kategori', $r, 200);
ok('semua hasil filter berasal dari kategori yang diminta',
   !array_filter($r['json']['data'] ?? [], static fn($b) => $b['id_kategori'] !== 1));

$r = req('GET', '/api/barang?cari=Lenovo', null, $tokenLaboran);
status('pencarian nama barang', $r, 200);
ok('pencarian "Lenovo" menemukan hasil', count($r['json']['data'] ?? []) > 0);

$r = req('GET', '/api/barang?cari=A05', null, $tokenLaboran);
ok('pencarian juga menjangkau kode barang',
   ($r['json']['data'][0]['kode_barang'] ?? '') === 'A05');

$r = req('GET', '/api/barang?cari=%', null, $tokenLaboran);
ok('wildcard "%" diperlakukan sebagai teks biasa, bukan cocok-semua',
   count($r['json']['data'] ?? []) === 0,
   'dapat ' . count($r['json']['data'] ?? []) . ' hasil');

status('filter kategori tidak valid ditolak',
    req('GET', '/api/barang?id_kategori=abc', null, $tokenLaboran), 400);

$kodeUji = 'UJI' . substr((string) getmypid(), -3);
$barangBaru = [
    'id_kategori'   => $idKategori,
    'kode_barang'   => $kodeUji,
    'nama_barang'   => 'Barang Uji Otomatis',
    'merk'          => 'Generik',
    'jumlah'        => 10,
    'kondisi'       => 'Baik',
    'stok'          => 10,
    'tanggal_input' => '2026-09-01',
    'serial_number' => 'SN-UJI-001',
];
$r = req('POST', '/api/barang', $barangBaru, $tokenLaboran);
status('tambah barang', $r, 201);
$idBarang = $r['json']['data']['id_barang'] ?? null;

status('kode barang duplikat ditolak',
    req('POST', '/api/barang', $barangBaru, $tokenLaboran), 409);
status('stok melebihi jumlah ditolak',
    req('POST', '/api/barang', array_merge($barangBaru, [
        'kode_barang' => $kodeUji . 'B', 'jumlah' => 5, 'stok' => 9,
    ]), $tokenLaboran), 422);
status('kategori tidak ada ditolak',
    req('POST', '/api/barang', array_merge($barangBaru, [
        'kode_barang' => $kodeUji . 'C', 'id_kategori' => 999999,
    ]), $tokenLaboran), 422);
status('jumlah negatif ditolak',
    req('POST', '/api/barang', array_merge($barangBaru, [
        'kode_barang' => $kodeUji . 'D', 'jumlah' => -1, 'stok' => 0,
    ]), $tokenLaboran), 422);
status('tanggal 30 Februari ditolak',
    req('POST', '/api/barang', array_merge($barangBaru, [
        'kode_barang' => $kodeUji . 'E', 'tanggal_input' => '2026-02-30',
    ]), $tokenLaboran), 422);

// ── FR-13 Mutasi Stok ────────────────────────────────────────────────
echo "\nFR-13 Mutasi Stok\n";

if (is_int($idBarang)) {
    $r = req('POST', '/api/stok-mutasi', [
        'id_barang'  => $idBarang,
        'jenis'      => 'masuk',
        'jumlah'     => 5,
        'keterangan' => 'Pengadaan uji otomatis',
    ], $tokenLaboran);
    status('catat mutasi masuk', $r, 201);
    ok('pencatat mutasi ikut tersimpan',
       ($r['json']['data']['dicatat_oleh'] ?? '') === 'laboran');

    $b = req('GET', "/api/barang/$idBarang", null, $tokenLaboran)['json']['data'] ?? [];
    ok('mutasi masuk menaikkan stok 10 -> 15', ($b['stok'] ?? 0) === 15,
       'stok = ' . ($b['stok'] ?? '?'));
    ok('mutasi masuk juga menaikkan jumlah 10 -> 15 (invarian stok <= jumlah)',
       ($b['jumlah'] ?? 0) === 15, 'jumlah = ' . ($b['jumlah'] ?? '?'));

    status('catat mutasi keluar', req('POST', '/api/stok-mutasi', [
        'id_barang' => $idBarang, 'jenis' => 'keluar', 'jumlah' => 3,
        'keterangan' => 'Rusak - dibuang',
    ], $tokenLaboran), 201);

    $b = req('GET', "/api/barang/$idBarang", null, $tokenLaboran)['json']['data'] ?? [];
    ok('mutasi keluar menurunkan stok 15 -> 12', ($b['stok'] ?? 0) === 12,
       'stok = ' . ($b['stok'] ?? '?'));

    status('mutasi keluar melebihi stok ditolak', req('POST', '/api/stok-mutasi', [
        'id_barang' => $idBarang, 'jenis' => 'keluar', 'jumlah' => 9999,
    ], $tokenLaboran), 422);

    $b = req('GET', "/api/barang/$idBarang", null, $tokenLaboran)['json']['data'] ?? [];
    ok('mutasi yang ditolak TIDAK mengubah stok (transaksi di-rollback)',
       ($b['stok'] ?? 0) === 12, 'stok = ' . ($b['stok'] ?? '?'));

    status('jenis mutasi ngawur ditolak', req('POST', '/api/stok-mutasi', [
        'id_barang' => $idBarang, 'jenis' => 'melayang', 'jumlah' => 1,
    ], $tokenLaboran), 422);
    status('jumlah mutasi 0 ditolak', req('POST', '/api/stok-mutasi', [
        'id_barang' => $idBarang, 'jenis' => 'masuk', 'jumlah' => 0,
    ], $tokenLaboran), 422);
    status('mutasi ke barang tidak ada ditolak', req('POST', '/api/stok-mutasi', [
        'id_barang' => 999999, 'jenis' => 'masuk', 'jumlah' => 1,
    ], $tokenLaboran), 422);

    $r = req('GET', "/api/stok-mutasi?id_barang=$idBarang", null, $tokenLaboran);
    status('riwayat mutasi per barang', $r, 200);
    ok('dua mutasi berhasil tercatat', count($r['json']['data'] ?? []) === 2,
       'dapat ' . count($r['json']['data'] ?? []));

    status('barang yang punya riwayat mutasi tidak bisa dihapus',
        req('DELETE', "/api/barang/$idBarang", null, $tokenLaboran), 409);
}

// ── FR-04 Kelola Peminjam ────────────────────────────────────────────
echo "\nFR-04 Kelola Peminjam\n";

$r = req('GET', '/api/peminjam', null, $tokenLaboran);
status('daftar peminjam', $r, 200);
ok('NIS/NIP dan kelas ikut terkirim',
   isset($r['json']['data'][0]['nis_nip'], $r['json']['data'][0]['kelas_jabatan']));

$r = req('GET', '/api/peminjam?cari=' . rawurlencode('XII TKJ 1'), null, $tokenLaboran);
ok('pencarian menjangkau kelas', count($r['json']['data'] ?? []) > 0);

$nisUji = '99' . substr((string) getmypid(), -4);
$r = req('POST', '/api/peminjam', [
    'nama_peminjam' => 'Peminjam Uji',
    'nis_nip'       => $nisUji,
    'kelas_jabatan' => 'XI TKJ 2',
    'no_hp'         => '081200000000',
], $tokenLaboran);
status('tambah peminjam', $r, 201);
$idPeminjam = $r['json']['data']['id_peminjam'] ?? null;

status('NIS duplikat ditolak', req('POST', '/api/peminjam', [
    'nama_peminjam' => 'Orang Lain', 'nis_nip' => $nisUji,
], $tokenLaboran), 409);
status('nama peminjam kosong ditolak',
    req('POST', '/api/peminjam', ['nama_peminjam' => ''], $tokenLaboran), 422);
// Pengaman "peminjam yang punya riwayat tidak bisa dihapus" baru bisa diuji
// setelah endpoint peminjaman ada di Sprint 3. Menguji sekarang dengan
// menghapus baris seed justru merusak data uji berikutnya.

if (is_int($idPeminjam)) {
    status('ubah data peminjam', req('PUT', "/api/peminjam/$idPeminjam", [
        'nama_peminjam' => 'Peminjam Uji Diubah',
        'nis_nip'       => $nisUji,
        'kelas_jabatan' => 'XII TKJ 3',
        'no_hp'         => '081211111111',
    ], $tokenLaboran), 200);
    status('hapus peminjam uji',
        req('DELETE', "/api/peminjam/$idPeminjam", null, $tokenLaboran), 200);
}

// ── Catatan data uji ─────────────────────────────────────────────────
echo "\n  Catatan: kategori dan barang uji sengaja ditinggalkan — barang yang\n"
   . "  punya riwayat mutasi memang tidak boleh dihapus. Untuk keadaan bersih:\n"
   . "    mysql -u root < database/schema.sql && mysql -u root < database/seed.sql\n";

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
