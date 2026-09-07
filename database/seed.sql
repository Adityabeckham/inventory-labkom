-- =====================================================================
-- Inventory Labkom — Data Awal (seed)
-- Rujukan : docs_project/Database_Final_dan_Arsitektur.md v1.5
--           Data contoh diambil dari mockup asli skripsi (Gambar 3.21 & 3.25)
--
-- Jalankan SETELAH schema.sql
--   mysql -u root < database/schema.sql
--   mysql -u root < database/seed.sql
-- =====================================================================

USE `inventory_labkom`;

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM `pengembalian`;
DELETE FROM `peminjaman_detail`;
DELETE FROM `peminjaman`;
DELETE FROM `stok_mutasi`;
DELETE FROM `barang`;
DELETE FROM `kategori`;
DELETE FROM `peminjam`;
DELETE FROM `pengaturan_denda`;
DELETE FROM `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- users — akun login awal
--
--   PERINGATAN: password di bawah HANYA untuk development.
--   Ganti lewat menu Kelola User sebelum dipakai di lingkungan nyata.
--
--   username | password    | level        | peran di UI
--   ---------+-------------+--------------+-----------------
--   laboran  | laboran123  | admin        | Laboran
--   kaprog   | kaprog123   | super_admin  | Kepala Program
-- ---------------------------------------------------------------------
INSERT INTO `users` (`id_user`, `username`, `password`, `level`, `nip`) VALUES
(1, 'laboran', '$2y$10$RIfBPaw6/1dEsoTDVc4jAONZQSe/CzcHIwIXSYp6JTIJsvB0kR6BG', 'admin',       '198504122010011002'),
(2, 'kaprog',  '$2y$10$3ZUlrUSIdFLHZqXtVl9M0.esfqA49uWOHEfljKo3QtgMb/9crqT3S', 'super_admin', '197911182005012003');

-- ---------------------------------------------------------------------
-- kategori — sesuai filter chip di mockup Daftar Barang (Gambar 3.21)
-- ---------------------------------------------------------------------
INSERT INTO `kategori` (`id_kategori`, `nama_kategori`) VALUES
(1, 'Komputer'),
(2, 'Jaringan'),
(3, 'Elektronik');

-- ---------------------------------------------------------------------
-- barang — data contoh dari mockup Daftar Barang (Gambar 3.21)
-- ---------------------------------------------------------------------
INSERT INTO `barang`
  (`id_barang`, `id_kategori`, `kode_barang`, `nama_barang`, `merk`, `jumlah`, `kondisi`, `stok`, `tanggal_input`, `serial_number`) VALUES
(1, 1, 'A01', 'Laptop Lenovo ThinkPad',    'Lenovo',   40, 'Baik', 40, '2026-01-15', 'LNV-TP-0001'),
(2, 3, 'A02', 'Monitor LG 24 Inch',        'LG',       25, 'Baik', 25, '2026-01-15', 'LG-M24-0001'),
(3, 1, 'A03', 'Keyboard Logitech K120',    'Logitech', 40, 'Baik', 40, '2026-01-20', NULL),
(4, 1, 'A04', 'Mouse Logitech 8100',       'Logitech', 40, 'Baik', 40, '2026-01-20', NULL),
(5, 2, 'A05', 'Switch Hub TP-Link 16 Port','TP-Link',  50, 'Baik', 50, '2026-02-03', 'TPL-SW16-001'),
(6, 2, 'A06', 'Kabel LAN Cat6 (roll)',     'Belden',   10, 'Baik', 10, '2026-02-03', NULL),
(7, 3, 'A07', 'Proyektor Epson EB-X51',    'Epson',     4, 'Baik',  4, '2026-02-10', 'EPS-X51-0001');

-- ---------------------------------------------------------------------
-- peminjam — data contoh dari mockup Kelola Peminjam (Gambar 3.25)
-- ---------------------------------------------------------------------
INSERT INTO `peminjam` (`id_peminjam`, `nama_peminjam`, `nis_nip`, `kelas_jabatan`, `no_hp`) VALUES
(1, 'Raka Maulana',  '190001', 'XII TKJ 1', '081234567890'),
(2, 'Siti Aisyah',   '190002', 'XII TKJ 2', '082345678910'),
(3, 'Ahmad Fauzi',   '190003', 'XII TKJ 1', '083456789012'),
(4, 'Dewi Ramadani', '190004', 'XII TKJ 3', '085678901234'),
(5, 'Nadia Putri',   '190005', 'XII TKJ 2', '087890123456');

-- ---------------------------------------------------------------------
-- pengaturan_denda — tarif default, bisa diubah lewat FR-11
-- ---------------------------------------------------------------------
INSERT INTO `pengaturan_denda` (`id_pengaturan`, `tarif_per_hari`) VALUES
(1, 5000.00);
