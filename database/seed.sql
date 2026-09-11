-- =====================================================================
-- Inventory Labkom — Data Awal (Seed) Lengkap untuk Demo & E2E Testing
-- SMK Al-Madani Jampangkulon
-- =====================================================================

USE `inventory_labkom`;

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM TABLE `pengembalian`;
DELETE FROM TABLE `peminjaman_detail`;
DELETE FROM TABLE `peminjaman`;
DELETE FROM TABLE `stok_mutasi`;
DELETE FROM TABLE `barang`;
DELETE FROM TABLE `kategori`;
DELETE FROM TABLE `peminjam`;
DELETE FROM TABLE `pengaturan_denda`;
DELETE FROM TABLE `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- 1. users — akun login
--    laboran (admin)       pw: laboran123
--    kaprog  (super_admin) pw: kaprog123
-- ---------------------------------------------------------------------
INSERT INTO `users` (`id_user`, `username`, `password`, `level`, `nip`) VALUES
(1, 'laboran', '$2y$10$RIfBPaw6/1dEsoTDVc4jAONZQSe/CzcHIwIXSYp6JTIJsvB0kR6BG', 'admin',       '198504122010011002'),
(2, 'kaprog',  '$2y$10$3ZUlrUSIdFLHZqXtVl9M0.esfqA49uWOHEfljKo3QtgMb/9crqT3S', 'super_admin', '197911182005012003');

-- ---------------------------------------------------------------------
-- 2. kategori
-- ---------------------------------------------------------------------
INSERT INTO `kategori` (`id_kategori`, `nama_kategori`) VALUES
(1, 'Komputer'),
(2, 'Jaringan'),
(3, 'Elektronik'),
(4, 'Aksesori & Tools');

-- ---------------------------------------------------------------------
-- 3. barang — data barang inventaris laboratorium
-- ---------------------------------------------------------------------
INSERT INTO `barang`
  (`id_barang`, `id_kategori`, `kode_barang`, `nama_barang`, `merk`, `jumlah`, `kondisi`, `stok`, `tanggal_input`, `serial_number`, `spesifikasi`) VALUES
(1, 1, 'BRG-A01', 'Laptop Lenovo ThinkPad X280', 'Lenovo',   40, 'Baik', 37, '2026-01-15', 'LNV-TP-9921', 'Core i5-8250U · RAM 8GB DDR4 · SSD 256GB NVMe · Layar 12.5" FHD IPS'),
(2, 3, 'BRG-A02', 'Monitor LG 24 Inch IPS',       'LG',       25, 'Baik', 24, '2026-01-15', 'LG-M24-8842', 'Panel IPS 24" Full HD (1920x1080) · 75Hz Refresh Rate · HDMI & VGA'),
(3, 1, 'BRG-A03', 'Keyboard Logitech K120 USB',   'Logitech', 40, 'Baik', 40, '2026-01-20', 'LOG-K120-112', 'Layout Full-Size Standard · Konektivitas USB Plug-and-Play · Spill-Resistant'),
(4, 1, 'BRG-A04', 'Mouse Logitech B100 Optical',  'Logitech', 40, 'Baik', 40, '2026-01-20', 'LOG-B100-334', 'Sensor Optik 800 DPI · Ambidextrous Design · USB Wired Connection'),
(5, 2, 'BRG-A05', 'Switch Hub TP-Link 16 Port',   'TP-Link',  50, 'Baik', 48, '2026-02-03', 'TPL-SW16-551', '16-Port 10/100/1000Mbps Gigabit RJ45 · Auto MDI/MDIX · Metal Rackmount'),
(6, 2, 'BRG-A06', 'Mikrotik RouterBoard RB951',   'MikroTik', 15, 'Baik', 14, '2026-02-03', 'MT-RB951-778', 'Atheros 600MHz CPU · RAM 64MB · 5x LAN Ports · Wireless 2.4GHz High Power'),
(7, 3, 'BRG-A07', 'Proyektor Epson EB-X51 3800',  'Epson',     4, 'Baik',  2, '2026-02-10', 'EPS-X51-0001', '3800 Lumens Brightness · Resolusi XGA (1024x768) · Contrast 16.000:1 · HDMI'),
(8, 4, 'BRG-A08', 'Crimping Tool & Cable Tester',  'TNS Tools', 20, 'Baik', 20, '2026-02-12', 'TNS-CRMP-09', 'Tang Crimp RJ45/RJ11 + Cable Tester LAN Multi-Function & Pouch');

-- ---------------------------------------------------------------------
-- 4. peminjam — daftar siswa & guru
-- ---------------------------------------------------------------------
INSERT INTO `peminjam` (`id_peminjam`, `nama_peminjam`, `nis_nip`, `kelas_jabatan`, `no_hp`) VALUES
(1, 'Raka Maulana',        '190001', 'XII TKJ 1',            '081234567890'),
(2, 'Siti Aisyah',         '190002', 'XII TKJ 2',            '082345678910'),
(3, 'Budi Santoso, S.Kom', '198803', 'Guru Produktif TKJ',   '083456789012'),
(4, 'Ahmad Fauzi',         '190003', 'XII TKJ 1',            '085678901234'),
(5, 'Dewi Ramadani',       '190004', 'XII TKJ 3',            '087890123456');

-- ---------------------------------------------------------------------
-- 5. pengaturan_denda
-- ---------------------------------------------------------------------
INSERT INTO `pengaturan_denda` (`id_pengaturan`, `tarif_per_hari`) VALUES
(1, 5000.00);

-- ---------------------------------------------------------------------
-- 6. peminjaman — data transaksi peminjaman bervariasi
-- ---------------------------------------------------------------------
INSERT INTO `peminjaman` 
  (`id_peminjaman`, `kode_peminjaman`, `id_peminjam`, `id_user`, `tanggal_pinjam`, `tanggal_kembali`, `status`, `alasan_dibatalkan`) VALUES
-- Transaksi 1: Menunggu Verifikasi Kaprog (Raka Maulana pinjam 2 Laptop & 1 Proyektor)
(1, 'PMJ-2026-001', 1, 1, '2026-09-08', '2026-09-10', 'menunggu_verifikasi', NULL),

-- Transaksi 2: Dipinjam Aktif (Siti Aisyah pinjam 1 Mikrotik & 2 Switch TP-Link)
(2, 'PMJ-2026-002', 2, 1, '2026-09-01', '2026-09-08', 'dipinjam', NULL),

-- Transaksi 3: Dipinjam Aktif / Terlambat (Budi Santoso pinjam 1 Proyektor & 1 Monitor)
(3, 'PMJ-2026-003', 3, 1, '2026-08-25', '2026-09-01', 'dipinjam', NULL),

-- Transaksi 4: Dikembalikan Selesai (Ahmad Fauzi pinjam 1 Laptop)
(4, 'PMJ-2026-004', 4, 1, '2026-09-01', '2026-09-05', 'dikembalikan', NULL),

-- Transaksi 5: Dibatalkan (Dewi Ramadani)
(5, 'PMJ-2026-005', 5, 1, '2026-09-02', '2026-09-04', 'dibatalkan', 'Unit proyektor sedang dipakai acara rapat sekolah');

-- ---------------------------------------------------------------------
-- 7. peminjaman_detail — item barang per transaksi
-- ---------------------------------------------------------------------
INSERT INTO `peminjaman_detail` (`id_detail`, `id_peminjaman`, `id_barang`, `jumlah_pinjam`) VALUES
-- PMJ-2026-001 (Menunggu Verifikasi)
(1, 1, 1, 2), -- 2 Laptop Lenovo
(2, 1, 7, 1), -- 1 Proyektor Epson

-- PMJ-2026-002 (Dipinjam Aktif)
(3, 2, 6, 1), -- 1 Mikrotik Router
(4, 2, 5, 2), -- 2 Switch TP-Link

-- PMJ-2026-003 (Dipinjam / Terlambat)
(5, 3, 7, 1), -- 1 Proyektor Epson
(6, 3, 2, 1), -- 1 Monitor LG

-- PMJ-2026-004 (Dikembalikan Selesai)
(7, 4, 1, 1), -- 1 Laptop Lenovo

-- PMJ-2026-005 (Dibatalkan)
(8, 5, 7, 1); -- 1 Proyektor Epson

-- ---------------------------------------------------------------------
-- 8. pengembalian — histori item yang sudah dikembalikan
-- ---------------------------------------------------------------------
INSERT INTO `pengembalian` (`id_pengembalian`, `id_detail`, `tanggal_pengembalian`, `kondisi`, `jumlah_hari_telat`, `denda`) VALUES
(1, 7, '2026-09-05', 'baik', 0, 0.00);

-- ---------------------------------------------------------------------
-- 9. stok_mutasi — catatan riwayat perubahan stok laboratorium
-- ---------------------------------------------------------------------
INSERT INTO `stok_mutasi` (`id_mutasi`, `id_barang`, `id_user`, `jenis`, `jumlah`, `keterangan`, `tanggal_mutasi`) VALUES
(1, 1, 1, 'masuk', 40, 'Pengadaan awal unit Laptop Lenovo TKJ', '2026-01-15'),
(2, 6, 1, 'masuk', 15, 'Pengadaan RouterBoard Mikrotik Praktikum', '2026-02-03'),
(3, 7, 1, 'masuk',  4, 'Pengadaan Proyektor Laboratorium', '2026-02-10');
