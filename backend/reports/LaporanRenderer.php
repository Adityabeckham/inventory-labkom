<?php
declare(strict_types=1);

namespace App\Reports;

use Mpdf\Mpdf;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PhpOffice\PhpWord\IOFactory;
use PhpOffice\PhpWord\PhpWord;
use PhpOffice\PhpWord\SimpleType\Jc;
use PhpOffice\PhpWord\Style\Language;
use RuntimeException;
use Throwable;

/**
 * Mengubah satu [Laporan] jadi byte PDF, Word, atau Excel.
 *
 * SEMUA writer menulis ke berkas sementara lalu dibaca kembali, tidak pernah
 * ke `php://output`. Bukan sekadar selera: PHPWord 1.4 memancarkan deprecation
 * di PHP 8.5, dan kalau writer-nya menulis ke output, teks peringatan itu
 * menyusup ke depan byte ZIP — `PK` di awal berkas berubah jadi "\nDeprecated"
 * dan Word menolak membukanya. Menulis ke berkas membuat integritas isinya
 * tidak bergantung pada pengaturan display_errors.
 *
 * Warna mengikuti design/DESIGN.md: Deep Navy #384C9D untuk kepala tabel.
 */
final class LaporanRenderer
{
    private const NAVY      = '384C9D';
    private const NAVY_TINT = 'EEF1FB';
    private const GARIS     = 'D5DBEA';

    public static function pdf(Laporan $l): string
    {
        // A4 melintang: laporan barang punya sembilan kolom dan tidak muat
        // di orientasi tegak tanpa teksnya jadi terlalu kecil untuk dibaca.
        return self::hasilkan('pdf', static function (string $berkas) use ($l): void {
            $mpdf = new Mpdf([
                'mode'    => 'utf-8',
                'format'  => 'A4-L',
                'tempDir' => self::direktoriSementara(),
                'margin_top' => 12,
                'margin_bottom' => 14,
                'margin_left' => 10,
                'margin_right' => 10,
            ]);
            $mpdf->SetTitle($l->judul);
            $mpdf->SetAuthor(Laporan::SEKOLAH);
            $mpdf->SetFooter('{PAGENO} / {nbpg}');
            $mpdf->WriteHTML(self::html($l));
            $mpdf->Output($berkas, \Mpdf\Output\Destination::FILE);
        });
    }

    public static function xlsx(Laporan $l): string
    {
        return self::hasilkan('xlsx', static function (string $berkas) use ($l): void {
            $buku = new Spreadsheet();
            $s = $buku->getActiveSheet();
            $s->setTitle(mb_substr($l->judul, 0, 31));

            $lebar = count($l->kolom);
            $kolomAkhir = self::hurufKolom($lebar);

            // Kepala: identitas sekolah, judul, periode.
            $s->setCellValue('A1', Laporan::SEKOLAH . ' — ' . Laporan::UNIT);
            $s->setCellValue('A2', $l->judul);
            $s->setCellValue('A3', $l->periode);
            $s->getStyle('A2')->getFont()->setBold(true)->setSize(14);
            $s->getStyle('A1')->getFont()->setSize(11);
            foreach (['A1', 'A2', 'A3'] as $sel) {
                $s->mergeCells("$sel:$kolomAkhir" . substr($sel, 1));
            }

            $barisJudul = 5;
            foreach ($l->kolom as $i => $judul) {
                $s->setCellValue(self::hurufKolom($i + 1) . $barisJudul, $judul);
            }

            $rentangJudul = "A$barisJudul:$kolomAkhir$barisJudul";
            $s->getStyle($rentangJudul)->getFont()->setBold(true)
                ->getColor()->setRGB('FFFFFF');
            $s->getStyle($rentangJudul)->getFill()
                ->setFillType(Fill::FILL_SOLID)->getStartColor()->setRGB(self::NAVY);
            $s->getStyle($rentangJudul)->getAlignment()
                ->setVertical(Alignment::VERTICAL_CENTER)->setWrapText(true);

            $baris = $barisJudul + 1;
            foreach ($l->baris as $isi) {
                foreach (array_values($isi) as $i => $nilai) {
                    // setCellValueExplicit tidak dipakai supaya angka tetap
                    // jadi angka — laporan Excel memang untuk dihitung ulang.
                    $s->setCellValue(self::hurufKolom($i + 1) . $baris, $nilai);
                }
                $baris++;
            }

            if ($l->baris !== []) {
                $rentangIsi = "A$barisJudul:$kolomAkhir" . ($baris - 1);
                $s->getStyle($rentangIsi)->getBorders()->getAllBorders()
                    ->setBorderStyle(Border::BORDER_THIN)
                    ->getColor()->setRGB(self::GARIS);

                foreach ($l->kolomKanan() as $i) {
                    $huruf = self::hurufKolom($i + 1);
                    $s->getStyle("$huruf" . ($barisJudul + 1) . ":$huruf" . ($baris - 1))
                        ->getAlignment()->setHorizontal(Alignment::HORIZONTAL_RIGHT);
                }

                // Nominal rupiah dibiarkan sebagai angka dan hanya diberi
                // format sel, supaya kolomnya masih bisa dijumlah di Excel.
                foreach ($l->kolomRupiah as $i) {
                    $huruf = self::hurufKolom($i + 1);
                    $s->getStyle("$huruf" . ($barisJudul + 1) . ":$huruf" . ($baris - 1))
                        ->getNumberFormat()->setFormatCode('"Rp" #,##0');
                }
            }

            if ($l->ringkasan !== []) {
                $baris++;
                foreach ($l->ringkasan as $label => $nilai) {
                    $s->setCellValue('A' . $baris, $label);
                    $s->setCellValue('B' . $baris, $nilai);
                    $s->getStyle('A' . $baris)->getFont()->setBold(true);
                    $baris++;
                }
            }

            for ($i = 1; $i <= $lebar; $i++) {
                $s->getColumnDimension(self::hurufKolom($i))->setAutoSize(true);
            }
            $s->freezePane('A' . ($barisJudul + 1));

            (new Xlsx($buku))->save($berkas);
            // Spreadsheet menahan objek gambar dan style; dilepas eksplisit
            // supaya memori tidak menumpuk saat beberapa laporan dibuat.
            $buku->disconnectWorksheets();
        });
    }

    public static function docx(Laporan $l): string
    {
        return self::hasilkan('docx', static function (string $berkas) use ($l): void {
            $word = new PhpWord();
            $word->getSettings()->setThemeFontLang(new Language(Language::EN_US));
            $word->setDefaultFontName('Arial');
            $word->setDefaultFontSize(9);

            $bagian = $word->addSection([
                'orientation'  => 'landscape',
                'marginTop'    => 700,
                'marginBottom' => 700,
                'marginLeft'   => 600,
                'marginRight'  => 600,
            ]);

            $bagian->addText(
                Laporan::SEKOLAH . ' — ' . Laporan::UNIT,
                ['size' => 10],
                ['alignment' => Jc::CENTER, 'spaceAfter' => 0]
            );
            $bagian->addText(
                $l->judul,
                ['bold' => true, 'size' => 14, 'color' => self::NAVY],
                ['alignment' => Jc::CENTER, 'spaceAfter' => 0]
            );
            $bagian->addText(
                $l->periode,
                ['size' => 9, 'color' => '646464'],
                ['alignment' => Jc::CENTER, 'spaceAfter' => 200]
            );

            $tabel = $bagian->addTable([
                'borderColor' => self::GARIS,
                'borderSize'  => 6,
                'cellMargin'  => 60,
                'width'       => 100 * 50,
                'unit'        => 'pct',
            ]);

            $tabel->addRow(null, ['tblHeader' => true]);
            foreach ($l->kolom as $judul) {
                $tabel->addCell(null, ['bgColor' => self::NAVY, 'valign' => 'center'])
                    ->addText($judul, ['bold' => true, 'color' => 'FFFFFF', 'size' => 9]);
            }

            foreach ($l->baris as $n => $isi) {
                $tabel->addRow();
                // Baris genap diberi latar tipis; tabel selebar ini sulit
                // diikuti matanya tanpa pembeda baris.
                $latar = $n % 2 === 1 ? ['bgColor' => self::NAVY_TINT] : [];
                foreach (array_values($isi) as $i => $nilai) {
                    $teks = in_array($i, $l->kolomRupiah, true)
                        ? Laporan::rupiah($nilai)
                        : (string) $nilai;

                    $tabel->addCell(null, $latar)->addText(
                        $teks,
                        ['size' => 9],
                        ['alignment' => in_array($i, $l->kolomKanan(), true)
                            ? Jc::END
                            : Jc::START],
                    );
                }
            }

            if ($l->baris === []) {
                $bagian->addTextBreak();
                $bagian->addText(
                    'Tidak ada data pada periode ini.',
                    ['italic' => true, 'size' => 9]
                );
            }

            if ($l->ringkasan !== []) {
                $bagian->addTextBreak();
                foreach ($l->ringkasan as $label => $nilai) {
                    $bagian->addText("$label: $nilai", ['bold' => true, 'size' => 10]);
                }
            }

            $bagian->addTextBreak();
            $bagian->addText(
                'Dicetak ' . date('d-m-Y H:i'),
                ['size' => 8, 'color' => '646464']
            );

            IOFactory::createWriter($word, 'Word2007')->save($berkas);
        });
    }

    // ── Pembantu ─────────────────────────────────────────────────────

    /**
     * Menjalankan writer ke berkas sementara lalu mengembalikan isinya.
     *
     * Keluaran liar selama pembuatan ditelan di sini, bukan dibiarkan lolos:
     * deprecation dari library yang tercetak sebelum header akan membuat
     * `header()` gagal dengan "headers already sent". Isinya tetap dicatat ke
     * log supaya tidak hilang diam-diam.
     *
     * @param callable(string):void $tulis
     */
    private static function hasilkan(string $ekstensi, callable $tulis): string
    {
        $berkas = tempnam(self::direktoriSementara(), 'laporan-') ?: null;
        if ($berkas === null) {
            throw new RuntimeException('Gagal membuat berkas sementara untuk laporan.');
        }

        ob_start();
        try {
            $tulis($berkas);
        } catch (Throwable $e) {
            ob_end_clean();
            @unlink($berkas);
            throw $e;
        }

        $liar = (string) ob_get_clean();
        if ($liar !== '') {
            error_log('[inventory-labkom] keluaran liar saat membuat laporan '
                . $ekstensi . ': ' . substr($liar, 0, 500));
        }

        $isi = file_get_contents($berkas);
        @unlink($berkas);

        if ($isi === false || $isi === '') {
            throw new RuntimeException("Laporan $ekstensi kosong setelah dibuat.");
        }

        return $isi;
    }

    private static function direktoriSementara(): string
    {
        $dir = sys_get_temp_dir() . '/inventory-labkom-laporan';
        if (!is_dir($dir) && !mkdir($dir, 0o777, true) && !is_dir($dir)) {
            throw new RuntimeException("Direktori sementara $dir tidak bisa dibuat.");
        }

        return $dir;
    }

    /** 1 => A, 27 => AA. Kelima laporan tidak sampai Z, tapi tetap ditangani. */
    private static function hurufKolom(int $n): string
    {
        $huruf = '';
        while ($n > 0) {
            $sisa = ($n - 1) % 26;
            $huruf = chr(65 + $sisa) . $huruf;
            $n = intdiv($n - 1 - $sisa, 26);
        }

        return $huruf;
    }

    private static function html(Laporan $l): string
    {
        $e = static fn (string|int|float $v): string => htmlspecialchars(
            (string) $v,
            ENT_QUOTES | ENT_SUBSTITUTE,
            'UTF-8'
        );

        $kepala = '';
        foreach ($l->kolom as $judul) {
            $kepala .= '<th>' . $e($judul) . '</th>';
        }

        $isi = '';
        foreach ($l->baris as $n => $baris) {
            $isi .= '<tr class="' . ($n % 2 === 1 ? 'genap' : '') . '">';
            foreach (array_values($baris) as $i => $nilai) {
                $kelas = in_array($i, $l->kolomKanan(), true) ? ' class="angka"' : '';
                $teks = in_array($i, $l->kolomRupiah, true)
                    ? Laporan::rupiah($nilai)
                    : $nilai;
                $isi .= "<td$kelas>" . $e($teks) . '</td>';
            }
            $isi .= '</tr>';
        }

        if ($l->baris === []) {
            $isi = '<tr><td class="kosong" colspan="' . count($l->kolom) . '">'
                . 'Tidak ada data pada periode ini.</td></tr>';
        }

        $ringkasan = '';
        foreach ($l->ringkasan as $label => $nilai) {
            $ringkasan .= '<p class="ringkas"><strong>' . $e($label) . ':</strong> '
                . $e($nilai) . '</p>';
        }

        $navy  = '#' . self::NAVY;
        $tint  = '#' . self::NAVY_TINT;
        $garis = '#' . self::GARIS;
        $dicetak = date('d-m-Y H:i');

        return <<<HTML
        <style>
            body { font-family: sans-serif; font-size: 8.5pt; color: #1E293B; }
            .sekolah { text-align: center; font-size: 9pt; margin: 0; }
            h1 { text-align: center; font-size: 14pt; color: $navy; margin: 2pt 0 0 0; }
            .periode { text-align: center; font-size: 8.5pt; color: #64748B; margin: 2pt 0 10pt 0; }
            table { width: 100%; border-collapse: collapse; }
            th { background: $navy; color: #fff; font-size: 8.5pt; padding: 4pt 5pt; text-align: left; }
            td { border: 0.4pt solid $garis; padding: 3pt 5pt; }
            tr.genap td { background: $tint; }
            td.angka { text-align: right; }
            td.kosong { text-align: center; font-style: italic; color: #64748B; padding: 12pt; }
            .ringkas { font-size: 9pt; margin: 8pt 0 0 0; }
            .jejak { font-size: 7.5pt; color: #64748B; margin-top: 12pt; }
        </style>
        <p class="sekolah">{$e(Laporan::SEKOLAH)} — {$e(Laporan::UNIT)}</p>
        <h1>{$e($l->judul)}</h1>
        <p class="periode">{$e($l->periode)}</p>
        <table>
            <thead><tr>$kepala</tr></thead>
            <tbody>$isi</tbody>
        </table>
        $ringkasan
        <p class="jejak">Dicetak $dicetak — {$l->jumlahBaris()} baris data.</p>
        HTML;
    }
}
