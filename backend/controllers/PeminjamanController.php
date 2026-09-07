<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Database;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;
use App\Middleware\Auth;
use PDO;

/**
 * FR-05 Peminjaman multi-item dan FR-07 Verifikasi.
 *
 * Alur status (Database_Final_dan_Arsitektur.md §3.5.1):
 *
 *   Laboran buat transaksi → menunggu_verifikasi (stok LANGSUNG berkurang)
 *          → Kepala Program approve → dipinjam
 *          → Kepala Program reject  → dibatalkan + alasan + stok dipulihkan
 *
 * Yang berubah saat peminjaman hanya `barang.stok`, bukan `barang.jumlah`.
 * `jumlah` adalah total unit yang dimiliki lab dan tidak berubah karena
 * dipinjam — unit yang sedang di tangan peminjam justru dihitung sebagai
 * `jumlah - stok`. Ini berbeda dari mutasi stok (FR-13) yang mengubah
 * keduanya, karena mutasi memang menambah/mengurangi kepemilikan.
 */
final class PeminjamanController
{
    /** Batas wajar satu transaksi; menahan payload yang tidak masuk akal. */
    private const MAX_ITEM = 50;

    private const STATUS = [
        'menunggu_verifikasi',
        'dipinjam',
        'sebagian_kembali',
        'dikembalikan',
        'dibatalkan',
    ];

    // ── Baca ─────────────────────────────────────────────────────────

    /**
     * Daftar peminjaman. Kepala Program juga boleh membacanya — melihat
     * daftar pengajuan adalah bagian dari use case Verifikasi (Tabel 3.1).
     */
    public function index(Request $request): void
    {
        $sql = self::SELECT_HEADER;
        $params = [];
        $where  = [];

        $status = $request->query('status');
        if ($status !== null && $status !== '' && $status !== 'semua') {
            if (!in_array($status, self::STATUS, true)) {
                throw HttpException::badRequest(
                    'Filter status harus salah satu dari: ' . implode(', ', self::STATUS) . '.'
                );
            }
            $where[] = 'p.status = :status';
            $params['status'] = $status;
        }

        $cari = trim((string) ($request->query('cari') ?? ''));
        if ($cari !== '') {
            // Placeholder tidak boleh dipakai ulang: ATTR_EMULATE_PREPARES
            // false membuat MySQL menolak satu nama untuk beberapa posisi.
            $where[] = '(p.kode_peminjaman LIKE :cari1
                      OR pm.nama_peminjam  LIKE :cari2
                      OR pm.nis_nip        LIKE :cari3)';
            $params['cari1'] = $params['cari2'] = $params['cari3'] = '%' . $cari . '%';
        }

        if ($where !== []) {
            $sql .= ' WHERE ' . implode(' AND ', $where);
        }

        // Terbaru di atas. id jadi pemecah seri karena tanggal_pinjam hanya
        // berpresisi hari dan beberapa transaksi bisa dicatat di hari sama.
        $sql .= ' ORDER BY p.tanggal_pinjam DESC, p.id_peminjaman DESC';

        Response::success(
            array_map(self::presentHeader(...), Database::select($sql, $params)),
            'Daftar peminjaman.'
        );
    }

    /** Satu transaksi lengkap dengan rincian barangnya. */
    public function show(Request $request): void
    {
        Response::success(self::findOrFail(Validator::id($request)), 'Detail peminjaman.');
    }

    // ── Tulis ────────────────────────────────────────────────────────

    public function store(Request $request): void
    {
        $idPeminjam = Validator::positiveInt($request, 'id_peminjam');
        $tglPinjam  = Validator::date($request, 'tanggal_pinjam');
        $tglKembali = Validator::date($request, 'tanggal_kembali');

        // Format YYYY-MM-DD aman dibandingkan sebagai string.
        if ($tglKembali < $tglPinjam) {
            throw HttpException::unprocessable(
                'Tanggal jatuh tempo tidak boleh lebih awal dari tanggal pinjam.'
            );
        }

        $items  = self::parseItems($request);
        $idUser = Auth::user()['id_user'];

        $id = Database::transaction(
            function (PDO $pdo) use ($idPeminjam, $tglPinjam, $tglKembali, $items, $idUser): int {
                $peminjam = $pdo->prepare(
                    'SELECT id_peminjam FROM peminjam WHERE id_peminjam = :id'
                );
                $peminjam->execute(['id' => $idPeminjam]);
                if ($peminjam->fetch() === false) {
                    throw HttpException::unprocessable('Peminjam yang dipilih tidak ada.');
                }

                $barang = self::lockBarang($pdo, array_keys($items));

                foreach ($items as $idBarang => $jumlah) {
                    if (!isset($barang[$idBarang])) {
                        throw HttpException::unprocessable(
                            "Barang dengan id $idBarang tidak ada."
                        );
                    }

                    $stok = (int) $barang[$idBarang]['stok'];
                    if ($stok < $jumlah) {
                        throw HttpException::unprocessable(sprintf(
                            'Stok "%s" tinggal %d unit, tidak cukup untuk meminjam %d unit.',
                            $barang[$idBarang]['nama_barang'],
                            $stok,
                            $jumlah
                        ));
                    }
                }

                $kode = self::kodeBerikutnya($pdo, $tglPinjam);

                $pdo->prepare(
                    'INSERT INTO peminjaman
                        (kode_peminjaman, id_peminjam, id_user, tanggal_pinjam,
                         tanggal_kembali, status)
                     VALUES (:kode, :id_peminjam, :id_user, :tanggal_pinjam,
                             :tanggal_kembali, \'menunggu_verifikasi\')'
                )->execute([
                    'kode'            => $kode,
                    'id_peminjam'     => $idPeminjam,
                    'id_user'         => $idUser,
                    'tanggal_pinjam'  => $tglPinjam,
                    'tanggal_kembali' => $tglKembali,
                ]);

                $idPeminjaman = (int) $pdo->lastInsertId();

                $detail = $pdo->prepare(
                    'INSERT INTO peminjaman_detail (id_peminjaman, id_barang, jumlah_pinjam)
                     VALUES (:id_peminjaman, :id_barang, :jumlah)'
                );
                $kurangi = $pdo->prepare(
                    'UPDATE barang SET stok = stok - :jumlah WHERE id_barang = :id_barang'
                );

                foreach ($items as $idBarang => $jumlah) {
                    $detail->execute([
                        'id_peminjaman' => $idPeminjaman,
                        'id_barang'     => $idBarang,
                        'jumlah'        => $jumlah,
                    ]);
                    $kurangi->execute(['jumlah' => $jumlah, 'id_barang' => $idBarang]);
                }

                return $idPeminjaman;
            }
        );

        Response::success(
            self::findOrFail($id),
            'Peminjaman diajukan dan menunggu verifikasi Kepala Program.',
            201
        );
    }

    /**
     * FR-07 — approve atau reject, khusus Kepala Program.
     *
     * Reject memulihkan stok seluruh barang di transaksi ini. Karena itu
     * langkah paling rawan: kalau dijalankan dua kali, stok bertambah dua
     * kali. Perubahan status dilakukan LEBIH DULU dan hanya dari
     * `menunggu_verifikasi`; stok baru dipulihkan setelah baris statusnya
     * benar-benar terbukti berubah.
     */
    public function verifikasi(Request $request): void
    {
        $id     = Validator::id($request);
        $aksi   = Validator::enum($request, 'aksi', ['approve', 'reject']);
        $alasan = $aksi === 'reject'
            ? Validator::requiredString($request, 'alasan', 255)
            : null;

        Database::transaction(function (PDO $pdo) use ($id, $aksi, $alasan): void {
            $stmt = $pdo->prepare(
                'SELECT id_peminjaman, kode_peminjaman, status
                   FROM peminjaman WHERE id_peminjaman = :id FOR UPDATE'
            );
            $stmt->execute(['id' => $id]);
            $peminjaman = $stmt->fetch();

            if ($peminjaman === false) {
                throw HttpException::notFound('Peminjaman tidak ditemukan.');
            }

            if ($peminjaman['status'] !== 'menunggu_verifikasi') {
                throw HttpException::conflict(sprintf(
                    'Peminjaman %s sudah berstatus "%s" dan tidak bisa diverifikasi lagi.',
                    $peminjaman['kode_peminjaman'],
                    $peminjaman['status']
                ));
            }

            $ubah = $pdo->prepare(
                'UPDATE peminjaman
                    SET status = :status, alasan_dibatalkan = :alasan
                  WHERE id_peminjaman = :id AND status = \'menunggu_verifikasi\''
            );
            $ubah->execute([
                'status' => $aksi === 'approve' ? 'dipinjam' : 'dibatalkan',
                'alasan' => $alasan,
                'id'     => $id,
            ]);

            // Baris FOR UPDATE di atas seharusnya sudah menutup peluang ini.
            // Kalau tetap 0, ada jalur lain yang mengubah status dan stok
            // TIDAK boleh dipulihkan.
            if ($ubah->rowCount() !== 1) {
                throw HttpException::conflict(
                    'Status peminjaman berubah oleh proses lain. Coba muat ulang.'
                );
            }

            if ($aksi === 'approve') {
                return;
            }

            self::pulihkanStok($pdo, $id);
        });

        Response::success(
            self::findOrFail($id),
            $aksi === 'approve'
                ? 'Peminjaman disetujui dan barang tercatat dipinjam.'
                : 'Peminjaman ditolak dan stok barang dipulihkan.'
        );
    }

    // ── Pembantu ─────────────────────────────────────────────────────

    /**
     * Membaca `items` dari body jadi peta id_barang => jumlah.
     *
     * @return array<int,int> terurut naik menurut id_barang
     */
    private static function parseItems(Request $request): array
    {
        $raw = $request->input('items');

        if (!is_array($raw) || $raw === []) {
            throw HttpException::unprocessable(
                'Field "items" wajib berisi minimal satu barang.'
            );
        }
        if (count($raw) > self::MAX_ITEM) {
            throw HttpException::unprocessable(
                'Satu peminjaman maksimal ' . self::MAX_ITEM . ' jenis barang.'
            );
        }

        $items = [];

        foreach ($raw as $i => $item) {
            if (!is_array($item)) {
                throw HttpException::unprocessable("items[$i] harus berupa objek.");
            }

            $idBarang = self::intWajib($item['id_barang'] ?? null, "items[$i].id_barang");
            $jumlah   = self::intWajib($item['jumlah'] ?? null, "items[$i].jumlah");

            // Ditolak, bukan dijumlahkan diam-diam: keranjang di UI yang
            // seharusnya menggabungkan baris kembar, dan menjumlahkannya di
            // sini justru menyembunyikan bug di sisi klien.
            if (isset($items[$idBarang])) {
                throw HttpException::unprocessable(
                    "Barang dengan id $idBarang muncul lebih dari sekali. "
                    . 'Gabungkan jumlahnya jadi satu baris.'
                );
            }

            $items[$idBarang] = $jumlah;
        }

        // Diurutkan SETELAH digabung. Semua transaksi mengunci baris barang
        // dalam urutan id yang sama supaya tidak saling deadlock.
        ksort($items);

        return $items;
    }

    private static function intWajib(mixed $value, string $field): int
    {
        if (is_int($value)) {
            $int = $value;
        } elseif (is_string($value) && preg_match('/^\d+$/', trim($value)) === 1) {
            $int = (int) trim($value);
        } else {
            throw HttpException::unprocessable("Field '$field' harus angka bulat positif.");
        }

        if ($int < 1) {
            throw HttpException::unprocessable("Field '$field' harus lebih dari 0.");
        }

        return $int;
    }

    /**
     * Mengunci baris barang yang terlibat.
     *
     * @param list<int> $ids sudah terurut naik
     * @return array<int,array<string,mixed>>
     */
    private static function lockBarang(PDO $pdo, array $ids): array
    {
        // Nama placeholder dibuat sendiri; jumlahnya dinamis dan tidak boleh
        // dirangkai dari nilai input.
        $names  = [];
        $params = [];
        foreach (array_values($ids) as $i => $id) {
            $names[] = ":b$i";
            $params["b$i"] = $id;
        }

        $stmt = $pdo->prepare(
            'SELECT id_barang, nama_barang, jumlah, stok
               FROM barang
              WHERE id_barang IN (' . implode(', ', $names) . ')
              ORDER BY id_barang
                FOR UPDATE'
        );
        $stmt->execute($params);

        $barang = [];
        foreach ($stmt->fetchAll() as $row) {
            $barang[(int) $row['id_barang']] = $row;
        }

        return $barang;
    }

    /**
     * Nomor urut berikutnya untuk tahun transaksi, mis. `PMJ-2026-001`.
     *
     * Tahun diambil dari tanggal pinjam, bukan tanggal pencatatan, supaya
     * kode transaksi selalu sejalan dengan periode laporan.
     *
     * Rentang LIKE dibaca dengan FOR UPDATE: di REPEATABLE READ, pemindaian
     * rentang mengambil gap lock, jadi transaksi lain yang menyisipkan kode
     * pada prefiks tahun yang sama akan menunggu, bukan berlomba. UNIQUE KEY
     * `uq_peminjaman_kode` tetap jadi jaring terakhir.
     */
    private static function kodeBerikutnya(PDO $pdo, string $tanggalPinjam): string
    {
        $prefix = sprintf('PMJ-%s-', substr($tanggalPinjam, 0, 4));

        $stmt = $pdo->prepare(
            'SELECT COALESCE(MAX(CAST(SUBSTRING(kode_peminjaman, :mulai) AS UNSIGNED)), 0) AS urut
               FROM peminjaman
              WHERE kode_peminjaman LIKE :prefix
                FOR UPDATE'
        );
        // SUBSTRING MySQL berbasis 1, jadi karakter pertama setelah prefiks.
        $stmt->bindValue('mulai', strlen($prefix) + 1, PDO::PARAM_INT);
        $stmt->bindValue('prefix', $prefix . '%');
        $stmt->execute();

        $urut = (int) ($stmt->fetch()['urut'] ?? 0);

        return $prefix . sprintf('%03d', $urut + 1);
    }

    /**
     * Mengembalikan stok seluruh barang pada satu transaksi yang ditolak.
     *
     * Pemeriksaan `stok + kembali <= jumlah` saat ini TIDAK bisa terpicu, dan
     * itu memang disengaja. Mutasi stok (FR-13) mengubah `jumlah` dan `stok`
     * dengan selisih yang sama, jadi `jumlah - stok` tidak berubah karenanya;
     * peminjaman menaikkan selisih itu dan pemulihan menurunkannya kembali
     * ke angka semula. Justru keputusan D-02 — mutasi menyentuh keduanya,
     * bukan hanya `stok` seperti bunyi §3.9 — yang menutup lubangnya.
     *
     * Pemeriksaan ini dibiarkan sebagai penjaga invarian: kalau nanti FR-06
     * Pengembalian atau perubahan pada mutasi merusak asumsi di atas, stok
     * mustahil akan tertahan di sini, bukan tersimpan diam-diam.
     */
    private static function pulihkanStok(PDO $pdo, int $idPeminjaman): void
    {
        $detail = $pdo->prepare(
            'SELECT id_barang, jumlah_pinjam
               FROM peminjaman_detail
              WHERE id_peminjaman = :id
              ORDER BY id_barang'
        );
        $detail->execute(['id' => $idPeminjaman]);
        $baris = $detail->fetchAll();

        if ($baris === []) {
            return;
        }

        $ids    = array_map(static fn (array $r): int => (int) $r['id_barang'], $baris);
        $barang = self::lockBarang($pdo, $ids);

        $kembalikan = $pdo->prepare(
            'UPDATE barang SET stok = stok + :jumlah WHERE id_barang = :id_barang'
        );

        foreach ($baris as $row) {
            $idBarang = (int) $row['id_barang'];
            $jumlah   = (int) $row['jumlah_pinjam'];

            if (!isset($barang[$idBarang])) {
                throw HttpException::unprocessable(
                    "Barang dengan id $idBarang sudah tidak ada, stok tidak bisa dipulihkan."
                );
            }

            $stokBaru = (int) $barang[$idBarang]['stok'] + $jumlah;
            $total    = (int) $barang[$idBarang]['jumlah'];

            if ($stokBaru > $total) {
                throw HttpException::conflict(sprintf(
                    'Stok "%s" tidak bisa dipulihkan: %d + %d melebihi total %d unit yang '
                    . 'dimiliki. Kemungkinan ada mutasi stok yang mengurangi total selama '
                    . 'peminjaman ini menunggu verifikasi — perbaiki lewat Mutasi Stok dulu.',
                    $barang[$idBarang]['nama_barang'],
                    (int) $barang[$idBarang]['stok'],
                    $jumlah,
                    $total
                ));
            }

            $kembalikan->execute(['jumlah' => $jumlah, 'id_barang' => $idBarang]);
        }
    }

    private const SELECT_HEADER = <<<'SQL'
        SELECT p.id_peminjaman, p.kode_peminjaman, p.id_peminjam, p.id_user,
               p.tanggal_pinjam, p.tanggal_kembali, p.status, p.alasan_dibatalkan,
               pm.nama_peminjam, pm.nis_nip, pm.kelas_jabatan,
               u.username,
               (SELECT COUNT(*) FROM peminjaman_detail d
                 WHERE d.id_peminjaman = p.id_peminjaman) AS jumlah_item,
               (SELECT COALESCE(SUM(d.jumlah_pinjam), 0) FROM peminjaman_detail d
                 WHERE d.id_peminjaman = p.id_peminjaman) AS total_unit
          FROM peminjaman p
          JOIN peminjam pm ON pm.id_peminjam = p.id_peminjam
          JOIN users    u  ON u.id_user      = p.id_user
        SQL;

    /** @param array<string,mixed> $row */
    private static function presentHeader(array $row): array
    {
        return [
            'id_peminjaman'     => (int) $row['id_peminjaman'],
            'kode_peminjaman'   => $row['kode_peminjaman'],
            'id_peminjam'       => (int) $row['id_peminjam'],
            'nama_peminjam'     => $row['nama_peminjam'],
            'nis_nip'           => $row['nis_nip'],
            'kelas_jabatan'     => $row['kelas_jabatan'],
            'dicatat_oleh'      => $row['username'],
            'tanggal_pinjam'    => $row['tanggal_pinjam'],
            'tanggal_kembali'   => $row['tanggal_kembali'],
            'status'            => $row['status'],
            'alasan_dibatalkan' => $row['alasan_dibatalkan'],
            'jumlah_item'       => (int) $row['jumlah_item'],
            'total_unit'        => (int) $row['total_unit'],
        ];
    }

    /** @return array<string,mixed> header + rincian barang */
    private static function findOrFail(int $id): array
    {
        $row = Database::selectOne(
            self::SELECT_HEADER . ' WHERE p.id_peminjaman = :id',
            ['id' => $id]
        );

        if ($row === null) {
            throw HttpException::notFound('Peminjaman tidak ditemukan.');
        }

        // LEFT JOIN, bukan JOIN: item yang belum dikembalikan tetap harus
        // muncul. Datanya dipakai layar Pengembalian untuk menandai mana yang
        // sudah masuk dan mana yang masih di tangan peminjam (FR-06).
        $detail = Database::select(
            'SELECT d.id_detail, d.id_barang, d.jumlah_pinjam,
                    b.kode_barang, b.nama_barang, b.merk,
                    pg.id_pengembalian, pg.tanggal_pengembalian, pg.kondisi,
                    pg.jumlah_hari_telat, pg.denda
               FROM peminjaman_detail d
               JOIN barang b ON b.id_barang = d.id_barang
               LEFT JOIN pengembalian pg ON pg.id_detail = d.id_detail
              WHERE d.id_peminjaman = :id
              ORDER BY d.id_detail',
            ['id' => $id]
        );

        return self::presentHeader($row) + [
            'items' => array_map(static fn (array $d): array => [
                'id_detail'     => (int) $d['id_detail'],
                'id_barang'     => (int) $d['id_barang'],
                'kode_barang'   => $d['kode_barang'],
                'nama_barang'   => $d['nama_barang'],
                'merk'          => $d['merk'],
                'jumlah_pinjam' => (int) $d['jumlah_pinjam'],
                'pengembalian'  => $d['id_pengembalian'] === null ? null : [
                    'id_pengembalian'      => (int) $d['id_pengembalian'],
                    'tanggal_pengembalian' => $d['tanggal_pengembalian'],
                    'kondisi'              => $d['kondisi'],
                    'jumlah_hari_telat'    => (int) $d['jumlah_hari_telat'],
                    'denda'                => (float) $d['denda'],
                ],
            ], $detail),
            'total_denda' => array_sum(array_map(
                static fn (array $d): float => (float) ($d['denda'] ?? 0),
                $detail
            )),
        ];
    }
}
