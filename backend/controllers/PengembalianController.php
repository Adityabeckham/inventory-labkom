<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Database;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;
use DateTimeImmutable;
use PDO;
use PDOException;

/**
 * FR-06 — Pengembalian per item.
 *
 * Pengembalian mengacu ke `peminjaman_detail`, bukan ke header, sehingga satu
 * transaksi bisa kembali sebagian. Status header ikut menyesuaikan sendiri:
 * `sebagian_kembali` selama masih ada item tersisa, `dikembalikan` begitu
 * item terakhir masuk.
 *
 * Satu baris detail dikembalikan UTUH atau belum sama sekali. Tabel
 * `pengembalian` tidak punya kolom jumlah dan `id_detail`-nya UNIQUE (D-03),
 * jadi "2 dari 3 unit kembali" memang tidak punya tempat penyimpanan. Ini
 * batasan skema, bukan pilihan tampilan — form di layar harus menampilkan
 * jumlahnya sebagai teks tetap, bukan field yang bisa diubah.
 */
final class PengembalianController
{
    /**
     * Tab pada layar Pengembalian (Database_Final_dan_Arsitektur.md §3.7.1).
     *
     * Ini SARINGAN, bukan pembagian yang saling lepas. "Sebagian Kembali"
     * beririsan dengan "Belum Kembali" maupun "Terlambat": satu transaksi
     * dengan 1 dari 2 item kembali dan sudah lewat jatuh tempo memenuhi
     * "Sebagian" sekaligus "Terlambat". Yang saling lepas hanya Belum vs
     * Terlambat (dibedakan tanggal) dan Sudah vs sisanya.
     */
    private const TAB = [
        'belum_kembali'    => 'sisa > 0 AND p.tanggal_kembali >= :hari_ini',
        'terlambat'        => 'sisa > 0 AND p.tanggal_kembali <  :hari_ini',
        'sebagian_kembali' => 'sisa > 0 AND kembali > 0',
        'sudah_kembali'    => 'sisa = 0',
    ];

    /**
     * Hanya transaksi yang barangnya benar-benar pernah keluar yang muncul di
     * layar ini. Pengajuan yang masih menunggu atau sudah dibatalkan tidak
     * pernah diserahkan, jadi tidak ada yang bisa dikembalikan.
     */
    private const STATUS_TAMPIL = ['dipinjam', 'sebagian_kembali', 'dikembalikan'];

    /** Status header yang masih boleh menerima pengembalian. */
    private const STATUS_BOLEH_KEMBALI = ['dipinjam', 'sebagian_kembali'];

    public function index(Request $request): void
    {
        $hariIni = date('Y-m-d');
        $params  = [];
        $having  = [];

        $tab = $request->query('tab');
        if ($tab !== null && $tab !== '' && $tab !== 'semua') {
            if (!isset(self::TAB[$tab])) {
                throw HttpException::badRequest(
                    'Tab harus salah satu dari: semua, ' . implode(', ', array_keys(self::TAB)) . '.'
                );
            }
            $having[] = self::TAB[$tab];

            // Hanya dua tab yang membandingkan tanggal. Parameter yang tidak
            // muncul di SQL harus TIDAK dikirim: dengan
            // ATTR_EMULATE_PREPARES false, MySQL menolak parameter berlebih.
            if (str_contains(self::TAB[$tab], ':hari_ini')) {
                $params['hari_ini'] = $hariIni;
            }
        }

        $where = 'p.status IN (\'' . implode('\', \'', self::STATUS_TAMPIL) . '\')';

        $cari = trim((string) ($request->query('cari') ?? ''));
        if ($cari !== '') {
            $where .= ' AND (p.kode_peminjaman LIKE :cari1
                          OR pm.nama_peminjam  LIKE :cari2
                          OR pm.nis_nip        LIKE :cari3)';
            $params['cari1'] = $params['cari2'] = $params['cari3'] = '%' . $cari . '%';
        }

        $sql = "SELECT p.id_peminjaman, p.kode_peminjaman, p.tanggal_pinjam,
                       p.tanggal_kembali, p.status,
                       pm.nama_peminjam, pm.nis_nip, pm.kelas_jabatan,
                       u.username,
                       COUNT(d.id_detail) AS jumlah_item,
                       COALESCE(SUM(d.jumlah_pinjam), 0) AS total_unit,
                       SUM(CASE WHEN pg.id_pengembalian IS NULL THEN 1 ELSE 0 END) AS sisa,
                       SUM(CASE WHEN pg.id_pengembalian IS NULL THEN 0 ELSE 1 END) AS kembali,
                       COALESCE(SUM(pg.denda), 0) AS total_denda
                  FROM peminjaman p
                  JOIN peminjam pm ON pm.id_peminjam = p.id_peminjam
                  JOIN users    u  ON u.id_user      = p.id_user
                  JOIN peminjaman_detail d ON d.id_peminjaman = p.id_peminjaman
                  LEFT JOIN pengembalian pg ON pg.id_detail = d.id_detail
                 WHERE $where
                 GROUP BY p.id_peminjaman, p.kode_peminjaman, p.tanggal_pinjam,
                          p.tanggal_kembali, p.status, pm.nama_peminjam,
                          pm.nis_nip, pm.kelas_jabatan, u.username";

        if ($having !== []) {
            $sql .= ' HAVING ' . implode(' AND ', $having);
        }

        $sql .= ' ORDER BY p.tanggal_kembali ASC, p.id_peminjaman DESC';

        Response::success(
            array_map(
                static fn (array $row): array => self::present($row, $hariIni),
                Database::select($sql, $params)
            ),
            'Daftar pengembalian.'
        );
    }

    public function store(Request $request): void
    {
        $idDetail = Validator::positiveInt($request, 'id_detail');
        $kondisi  = Validator::enum($request, 'kondisi', ['baik', 'rusak']);
        $tanggal  = Validator::optionalDate($request, 'tanggal_pengembalian')
            ?? date('Y-m-d');

        $id = Database::transaction(
            function (PDO $pdo) use ($idDetail, $kondisi, $tanggal): int {
                // Header ikut dikunci, bukan cuma barisnya: langkah terakhir
                // menghitung ulang sisa item dan menulis status header. Tanpa
                // kunci itu, dua pengembalian terakhir yang berbarengan
                // sama-sama melihat "masih ada sisa" lalu sama-sama menulis
                // sebagian_kembali, dan transaksinya tersangkut selamanya.
                $stmt = $pdo->prepare(
                    'SELECT d.id_detail, d.id_peminjaman, d.id_barang, d.jumlah_pinjam,
                            b.nama_barang,
                            p.kode_peminjaman, p.status, p.tanggal_pinjam, p.tanggal_kembali
                       FROM peminjaman_detail d
                       JOIN peminjaman p ON p.id_peminjaman = d.id_peminjaman
                       JOIN barang     b ON b.id_barang     = d.id_barang
                      WHERE d.id_detail = :id
                        FOR UPDATE'
                );
                $stmt->execute(['id' => $idDetail]);
                $detail = $stmt->fetch();

                if ($detail === false) {
                    throw HttpException::notFound('Item peminjaman tidak ditemukan.');
                }

                if (!in_array($detail['status'], self::STATUS_BOLEH_KEMBALI, true)) {
                    throw HttpException::conflict(sprintf(
                        'Peminjaman %s berstatus "%s", barangnya tidak dalam keadaan dipinjam.',
                        $detail['kode_peminjaman'],
                        $detail['status']
                    ));
                }

                if ($tanggal < $detail['tanggal_pinjam']) {
                    throw HttpException::unprocessable(
                        'Tanggal pengembalian tidak boleh lebih awal dari tanggal pinjam ('
                        . $detail['tanggal_pinjam'] . ').'
                    );
                }

                $hariTelat = self::hariTelat($detail['tanggal_kembali'], $tanggal);

                // Tarif dibaca SEKARANG lalu ikut tersimpan di baris ini.
                // Mengubah tarif nanti tidak boleh mengubah denda yang sudah
                // tercatat — angka di laporan harus tetap seperti saat kejadian.
                $denda = $hariTelat * PengaturanDendaController::tarifBerlaku();

                try {
                    $pdo->prepare(
                        'INSERT INTO pengembalian
                            (id_detail, tanggal_pengembalian, kondisi, jumlah_hari_telat, denda)
                         VALUES (:id_detail, :tanggal, :kondisi, :telat, :denda)'
                    )->execute([
                        'id_detail' => $idDetail,
                        'tanggal'   => $tanggal,
                        'kondisi'   => $kondisi,
                        'telat'     => $hariTelat,
                        'denda'     => $denda,
                    ]);
                } catch (PDOException $e) {
                    // uq_pengembalian_detail — penjaga sesungguhnya. Ditangkap
                    // di sini hanya supaya pesannya bisa dibaca pengguna.
                    if ($e->getCode() === '23000') {
                        throw HttpException::conflict(sprintf(
                            'Barang "%s" pada %s sudah pernah dikembalikan.',
                            $detail['nama_barang'],
                            $detail['kode_peminjaman']
                        ));
                    }
                    throw $e;
                }

                $idPengembalian = (int) $pdo->lastInsertId();

                self::pulihkanStok(
                    $pdo,
                    (int) $detail['id_barang'],
                    (int) $detail['jumlah_pinjam'],
                    (string) $detail['nama_barang']
                );

                self::selaraskanStatusHeader($pdo, (int) $detail['id_peminjaman']);

                return $idPengembalian;
            }
        );

        Response::success(self::findOrFail($id), 'Pengembalian dicatat.', 201);
    }

    // ── Pembantu ─────────────────────────────────────────────────────

    /**
     * Selisih hari dari jatuh tempo, 0 kalau tepat waktu atau lebih awal.
     *
     * Dihitung di PHP, bukan SQL, supaya angka yang disimpan sama persis
     * dengan yang dipakai mengalikan tarif — tidak ada dua sumber kebenaran.
     */
    private static function hariTelat(string $jatuhTempo, string $dikembalikan): int
    {
        $tempo = new DateTimeImmutable($jatuhTempo);
        $aktual = new DateTimeImmutable($dikembalikan);

        if ($aktual <= $tempo) {
            return 0;
        }

        return (int) $tempo->diff($aktual)->days;
    }

    /**
     * Unit yang kembali masuk lagi ke stok, TERMASUK yang kondisinya rusak.
     *
     * Menahan unit rusak di luar stok terdengar masuk akal, tapi akibatnya
     * `jumlah - stok` tinggal 1 selamanya, dan layar Aset Lab akan membacanya
     * sebagai "1 dipinjam atau diajukan" untuk barang yang justru tergeletak
     * rusak di rak. Penghapusan kepemilikan punya jalurnya sendiri: Laboran
     * mencatat mutasi keluar (FR-13), yang menurunkan `jumlah` dan `stok`
     * sekaligus.
     *
     * Penjaga `stok + kembali <= jumlah` sama seperti pada pembatalan
     * peminjaman — lihat alasan lengkapnya di catatan D-07.
     */
    private static function pulihkanStok(PDO $pdo, int $idBarang, int $jumlah, string $nama): void
    {
        $stmt = $pdo->prepare(
            'SELECT jumlah, stok FROM barang WHERE id_barang = :id FOR UPDATE'
        );
        $stmt->execute(['id' => $idBarang]);
        $barang = $stmt->fetch();

        if ($barang === false) {
            throw HttpException::unprocessable(
                "Barang \"$nama\" sudah tidak ada, stok tidak bisa dipulihkan."
            );
        }

        $stokBaru = (int) $barang['stok'] + $jumlah;
        $total    = (int) $barang['jumlah'];

        if ($stokBaru > $total) {
            throw HttpException::conflict(sprintf(
                'Stok "%s" tidak bisa dipulihkan: %d + %d melebihi total %d unit yang dimiliki.',
                $nama,
                (int) $barang['stok'],
                $jumlah,
                $total
            ));
        }

        $pdo->prepare('UPDATE barang SET stok = :stok WHERE id_barang = :id')
            ->execute(['stok' => $stokBaru, 'id' => $idBarang]);
    }

    /** Header jadi `dikembalikan` saat item terakhir masuk, `sebagian_kembali` selama masih ada sisa. */
    private static function selaraskanStatusHeader(PDO $pdo, int $idPeminjaman): void
    {
        $stmt = $pdo->prepare(
            'SELECT COUNT(*) AS sisa
               FROM peminjaman_detail d
               LEFT JOIN pengembalian pg ON pg.id_detail = d.id_detail
              WHERE d.id_peminjaman = :id AND pg.id_pengembalian IS NULL'
        );
        $stmt->execute(['id' => $idPeminjaman]);
        $sisa = (int) ($stmt->fetch()['sisa'] ?? 0);

        $pdo->prepare('UPDATE peminjaman SET status = :status WHERE id_peminjaman = :id')
            ->execute([
                'status' => $sisa === 0 ? 'dikembalikan' : 'sebagian_kembali',
                'id'     => $idPeminjaman,
            ]);
    }

    /**
     * @param array<string,mixed> $row
     * @return array<string,mixed>
     */
    private static function present(array $row, string $hariIni): array
    {
        $sisa    = (int) $row['sisa'];
        $kembali = (int) $row['kembali'];
        $lewat   = $row['tanggal_kembali'] < $hariIni;

        return [
            'id_peminjaman'   => (int) $row['id_peminjaman'],
            'kode_peminjaman' => $row['kode_peminjaman'],
            'nama_peminjam'   => $row['nama_peminjam'],
            'nis_nip'         => $row['nis_nip'],
            'kelas_jabatan'   => $row['kelas_jabatan'],
            'dicatat_oleh'    => $row['username'],
            'tanggal_pinjam'  => $row['tanggal_pinjam'],
            'tanggal_kembali' => $row['tanggal_kembali'],
            'status'          => $row['status'],
            'jumlah_item'     => (int) $row['jumlah_item'],
            'total_unit'      => (int) $row['total_unit'],
            'item_sisa'       => $sisa,
            'item_kembali'    => $kembali,
            'total_denda'     => (float) $row['total_denda'],
            'tampilan_status' => self::tampilanStatus($sisa, $kembali, $lewat),
        ];
    }

    /**
     * Satu badge untuk kartu, dari tab yang bisa terpenuhi bersamaan.
     *
     * Terlambat menang di atas segalanya karena hanya itu yang menuntut
     * tindakan. Urutannya sengaja ditulis di satu tempat: kalau badge dan
     * saringan tab memakai aturan berbeda, keduanya akan tampak bertentangan
     * di layar dan terbaca seperti bug.
     */
    private static function tampilanStatus(int $sisa, int $kembali, bool $lewatTempo): string
    {
        if ($sisa === 0) {
            return 'sudah_kembali';
        }
        if ($lewatTempo) {
            return 'terlambat';
        }
        if ($kembali > 0) {
            return 'sebagian_kembali';
        }

        return 'belum_kembali';
    }

    /** @return array<string,mixed> */
    private static function findOrFail(int $id): array
    {
        $row = Database::selectOne(
            'SELECT pg.*, d.id_peminjaman, d.id_barang, d.jumlah_pinjam,
                    b.kode_barang, b.nama_barang,
                    p.kode_peminjaman, p.tanggal_kembali, p.status AS status_peminjaman
               FROM pengembalian pg
               JOIN peminjaman_detail d ON d.id_detail     = pg.id_detail
               JOIN barang            b ON b.id_barang     = d.id_barang
               JOIN peminjaman        p ON p.id_peminjaman = d.id_peminjaman
              WHERE pg.id_pengembalian = :id',
            ['id' => $id]
        );

        if ($row === null) {
            throw HttpException::notFound('Pengembalian tidak ditemukan.');
        }

        return [
            'id_pengembalian'      => (int) $row['id_pengembalian'],
            'id_detail'            => (int) $row['id_detail'],
            'id_peminjaman'        => (int) $row['id_peminjaman'],
            'kode_peminjaman'      => $row['kode_peminjaman'],
            'id_barang'            => (int) $row['id_barang'],
            'kode_barang'          => $row['kode_barang'],
            'nama_barang'          => $row['nama_barang'],
            'jumlah_pinjam'        => (int) $row['jumlah_pinjam'],
            'tanggal_pengembalian' => $row['tanggal_pengembalian'],
            'tanggal_kembali'      => $row['tanggal_kembali'],
            'kondisi'              => $row['kondisi'],
            'jumlah_hari_telat'    => (int) $row['jumlah_hari_telat'],
            'denda'                => (float) $row['denda'],
            'status_peminjaman'    => $row['status_peminjaman'],
        ];
    }
}
