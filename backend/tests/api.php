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

// ── FR-05 Peminjaman Multi-Item ──────────────────────────────────────
echo "\nFR-05 Peminjaman Multi-Item\n";

/** Stok terkini satu barang, dibaca ulang dari API. */
function stokBarang(int $id, string $token): ?int
{
    $r = req('GET', "/api/barang/$id", null, $token);
    $v = $r['json']['data']['stok'] ?? null;
    return is_int($v) ? $v : null;
}

// Dua barang dari seed yang stoknya cukup untuk diuji. Dibaca dari API,
// bukan ditulis angkanya di sini — seed bisa berubah.
$semuaBarang = req('GET', '/api/barang', null, $tokenLaboran)['json']['data'] ?? [];
$layak = array_values(array_filter(
    $semuaBarang,
    static fn (array $b): bool => ($b['stok'] ?? 0) >= 3
));

ok('ada minimal dua barang berstok >= 3 untuk diuji', count($layak) >= 2,
   'impor ulang seed: mysql ... < database/seed.sql');

if (count($layak) >= 2) {
    $barangA = (int) $layak[0]['id_barang'];
    $barangB = (int) $layak[1]['id_barang'];
    $stokA0  = (int) $layak[0]['stok'];
    $stokB0  = (int) $layak[1]['stok'];

    // Peminjam khusus untuk blok ini, supaya pengujian "punya riwayat tidak
    // bisa dihapus" tidak menyentuh baris seed.
    $nisPinjam = '88' . substr((string) getmypid(), -4);
    $r = req('POST', '/api/peminjam', [
        'nama_peminjam' => 'Peminjam Transaksi Uji',
        'nis_nip'       => $nisPinjam,
        'kelas_jabatan' => 'XII RPL 1',
    ], $tokenLaboran);
    status('siapkan peminjam untuk transaksi', $r, 201);
    $idPinjamUji = $r['json']['data']['id_peminjam'] ?? null;

    $hariIni = date('Y-m-d');
    $jatuhTempo = date('Y-m-d', strtotime('+7 days'));

    $bodyValid = static fn (array $items, ?int $idp): array => [
        'id_peminjam'     => $idp,
        'tanggal_pinjam'  => $hariIni,
        'tanggal_kembali' => $jatuhTempo,
        'items'           => $items,
    ];

    // ── Otorisasi ────────────────────────────────────────────────────
    status('Kepala Program DITOLAK membuat peminjaman',
        req('POST', '/api/peminjaman',
            $bodyValid([['id_barang' => $barangA, 'jumlah' => 1]], $idPinjamUji),
            $tokenKaprog), 403);
    status('Kepala Program BOLEH membaca daftar peminjaman',
        req('GET', '/api/peminjaman', null, $tokenKaprog), 200);

    // ── Validasi masukan ─────────────────────────────────────────────
    status('items kosong ditolak',
        req('POST', '/api/peminjaman', $bodyValid([], $idPinjamUji), $tokenLaboran), 422);
    status('id_barang kembar ditolak, bukan dijumlahkan',
        req('POST', '/api/peminjaman', $bodyValid([
            ['id_barang' => $barangA, 'jumlah' => 1],
            ['id_barang' => $barangA, 'jumlah' => 2],
        ], $idPinjamUji), $tokenLaboran), 422);
    status('jumlah nol ditolak',
        req('POST', '/api/peminjaman', $bodyValid([
            ['id_barang' => $barangA, 'jumlah' => 0],
        ], $idPinjamUji), $tokenLaboran), 422);
    status('jatuh tempo lebih awal dari tanggal pinjam ditolak',
        req('POST', '/api/peminjaman', [
            'id_peminjam'     => $idPinjamUji,
            'tanggal_pinjam'  => $hariIni,
            'tanggal_kembali' => date('Y-m-d', strtotime('-1 day')),
            'items'           => [['id_barang' => $barangA, 'jumlah' => 1]],
        ], $tokenLaboran), 422);
    status('jumlah melebihi stok ditolak',
        req('POST', '/api/peminjaman', $bodyValid([
            ['id_barang' => $barangA, 'jumlah' => $stokA0 + 1],
        ], $idPinjamUji), $tokenLaboran), 422);
    status('peminjam tidak ada ditolak',
        req('POST', '/api/peminjaman', $bodyValid([
            ['id_barang' => $barangA, 'jumlah' => 1],
        ], 999999), $tokenLaboran), 422);

    ok('penolakan validasi tidak mengubah stok',
       stokBarang($barangA, $tokenLaboran) === $stokA0,
       'stok jadi ' . var_export(stokBarang($barangA, $tokenLaboran), true) . ", seharusnya $stokA0");

    // ── Transaksi sah, dua item ──────────────────────────────────────
    $r = req('POST', '/api/peminjaman', $bodyValid([
        ['id_barang' => $barangA, 'jumlah' => 2],
        ['id_barang' => $barangB, 'jumlah' => 1],
    ], $idPinjamUji), $tokenLaboran);
    status('buat peminjaman dua item', $r, 201);

    $pinjam1 = $r['json']['data'] ?? [];
    $idPinjaman1 = $pinjam1['id_peminjaman'] ?? null;

    ok('kode dibuat otomatis berformat PMJ-YYYY-NNN',
       preg_match('/^PMJ-\d{4}-\d{3,}$/', (string) ($pinjam1['kode_peminjaman'] ?? '')) === 1,
       'kode: ' . var_export($pinjam1['kode_peminjaman'] ?? null, true));
    ok('kode memakai tahun tanggal pinjam',
       str_starts_with((string) ($pinjam1['kode_peminjaman'] ?? ''), 'PMJ-' . date('Y') . '-'));
    ok('status awal menunggu_verifikasi',
       ($pinjam1['status'] ?? '') === 'menunggu_verifikasi');
    // ?? tidak bisa dipakai di sini: null dan "tidak ada" jadi sama.
    ok('alasan_dibatalkan masih kosong',
       array_key_exists('alasan_dibatalkan', $pinjam1)
       && $pinjam1['alasan_dibatalkan'] === null);
    ok('rincian berisi dua item', count($pinjam1['items'] ?? []) === 2);
    ok('jumlah_item dan total_unit dihitung benar',
       ($pinjam1['jumlah_item'] ?? 0) === 2 && ($pinjam1['total_unit'] ?? 0) === 3,
       'jumlah_item=' . var_export($pinjam1['jumlah_item'] ?? null, true)
       . ' total_unit=' . var_export($pinjam1['total_unit'] ?? null, true));
    ok('nama peminjam dan laboran pencatat ikut terkirim',
       ($pinjam1['nama_peminjam'] ?? '') === 'Peminjam Transaksi Uji'
       && ($pinjam1['dicatat_oleh'] ?? '') === 'laboran');

    ok('stok barang A langsung berkurang 2',
       stokBarang($barangA, $tokenLaboran) === $stokA0 - 2,
       'stok jadi ' . var_export(stokBarang($barangA, $tokenLaboran), true));
    ok('stok barang B langsung berkurang 1',
       stokBarang($barangB, $tokenLaboran) === $stokB0 - 1,
       'stok jadi ' . var_export(stokBarang($barangB, $tokenLaboran), true));

    // ── Baca dan filter ──────────────────────────────────────────────
    $r = req('GET', '/api/peminjaman?status=menunggu_verifikasi', null, $tokenKaprog);
    status('filter status menunggu_verifikasi', $r, 200);
    $kodeMenunggu = array_column($r['json']['data'] ?? [], 'kode_peminjaman');
    ok('transaksi baru muncul di daftar menunggu verifikasi',
       in_array($pinjam1['kode_peminjaman'] ?? '', $kodeMenunggu, true));

    $r = req('GET', '/api/peminjaman?status=ngawur', null, $tokenLaboran);
    status('filter status tidak dikenal ditolak', $r, 400);

    $r = req('GET', '/api/peminjaman?cari=' . rawurlencode((string) ($pinjam1['kode_peminjaman'] ?? '')),
             null, $tokenLaboran);
    ok('pencarian menjangkau kode peminjaman', count($r['json']['data'] ?? []) === 1);

    status('detail peminjaman yang tidak ada balas 404',
        req('GET', '/api/peminjaman/999999', null, $tokenLaboran), 404);

    // Pengaman yang tertunda dari Sprint 2 — sekarang bisa diuji dengan
    // peminjam yang dibuat sendiri, bukan baris seed.
    status('peminjam yang punya riwayat TIDAK bisa dihapus',
        req('DELETE', "/api/peminjam/$idPinjamUji", null, $tokenLaboran), 409);

    // ── FR-07 Verifikasi ─────────────────────────────────────────────
    echo "\nFR-07 Verifikasi\n";

    status('Laboran DITOLAK memverifikasi pengajuannya sendiri',
        req('PATCH', "/api/peminjaman/$idPinjaman1/verifikasi",
            ['aksi' => 'approve'], $tokenLaboran), 403);
    status('aksi tidak dikenal ditolak',
        req('PATCH', "/api/peminjaman/$idPinjaman1/verifikasi",
            ['aksi' => 'tunda'], $tokenKaprog), 422);
    status('reject tanpa alasan ditolak',
        req('PATCH', "/api/peminjaman/$idPinjaman1/verifikasi",
            ['aksi' => 'reject'], $tokenKaprog), 422);

    ok('penolakan verifikasi tidak mengubah stok',
       stokBarang($barangA, $tokenLaboran) === $stokA0 - 2);

    $r = req('PATCH', "/api/peminjaman/$idPinjaman1/verifikasi",
             ['aksi' => 'approve'], $tokenKaprog);
    status('Kepala Program menyetujui', $r, 200);
    ok('status jadi dipinjam', ($r['json']['data']['status'] ?? '') === 'dipinjam');
    ok('approve TIDAK mengubah stok lagi',
       stokBarang($barangA, $tokenLaboran) === $stokA0 - 2,
       'stok jadi ' . var_export(stokBarang($barangA, $tokenLaboran), true));

    status('verifikasi kedua kali ditolak',
        req('PATCH', "/api/peminjaman/$idPinjaman1/verifikasi",
            ['aksi' => 'reject', 'alasan' => 'coba lagi'], $tokenKaprog), 409);

    // ── Reject memulihkan stok ───────────────────────────────────────
    $stokA1 = stokBarang($barangA, $tokenLaboran);

    $r = req('POST', '/api/peminjaman', $bodyValid([
        ['id_barang' => $barangA, 'jumlah' => 1],
    ], $idPinjamUji), $tokenLaboran);
    status('buat peminjaman kedua untuk diuji penolakan', $r, 201);
    $idPinjaman2 = $r['json']['data']['id_peminjaman'] ?? null;

    ok('nomor urut kode bertambah',
       ($r['json']['data']['kode_peminjaman'] ?? '') !== ($pinjam1['kode_peminjaman'] ?? ''));
    ok('stok berkurang 1 saat diajukan',
       stokBarang($barangA, $tokenLaboran) === $stokA1 - 1);

    $alasan = 'Barang sedang dipakai praktik kelas XII.';
    $r = req('PATCH', "/api/peminjaman/$idPinjaman2/verifikasi",
             ['aksi' => 'reject', 'alasan' => $alasan], $tokenKaprog);
    status('Kepala Program menolak dengan alasan', $r, 200);
    ok('status jadi dibatalkan', ($r['json']['data']['status'] ?? '') === 'dibatalkan');
    ok('alasan penolakan tersimpan', ($r['json']['data']['alasan_dibatalkan'] ?? '') === $alasan);
    ok('stok dipulihkan persis ke angka sebelum pengajuan',
       stokBarang($barangA, $tokenLaboran) === $stokA1,
       'stok jadi ' . var_export(stokBarang($barangA, $tokenLaboran), true) . ", seharusnya $stokA1");

    // Inti pengaman kredit dobel: kalau penolakan kedua lolos, stok akan
    // bertambah untuk kedua kalinya dari unit yang sama.
    status('penolakan kedua kali ditolak',
        req('PATCH', "/api/peminjaman/$idPinjaman2/verifikasi",
            ['aksi' => 'reject', 'alasan' => 'sekali lagi'], $tokenKaprog), 409);
    ok('stok TIDAK bertambah dua kali dari transaksi yang sama',
       stokBarang($barangA, $tokenLaboran) === $stokA1,
       'stok jadi ' . var_export(stokBarang($barangA, $tokenLaboran), true) . ", seharusnya $stokA1");
}

// ── Catatan data uji ─────────────────────────────────────────────────
echo "\n  Catatan: kategori, barang, peminjam, dan peminjaman uji sengaja\n"
   . "  ditinggalkan — barang berriwayat mutasi dan peminjam berriwayat\n"
   . "  transaksi memang tidak boleh dihapus, dan itu justru yang diuji.\n"
   . "  Untuk keadaan bersih:\n"
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
