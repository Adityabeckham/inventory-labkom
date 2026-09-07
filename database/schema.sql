-- =====================================================================
-- Inventory Labkom — Skema Database
-- Sistem Inventory Laboratorium Komputer Berbasis Mobile
-- SMK Al-Madani Jampangkulon
--
-- Rujukan : docs_project/Database_Final_dan_Arsitektur.md v1.5 §3
-- Target  : MySQL 5.7+ / MariaDB 10.4+ (XAMPP)
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS `inventory_labkom`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `inventory_labkom`;

-- ---------------------------------------------------------------------
-- 3.1  users — akun login (dikelola lewat fitur Kelola User, FR-12)
--      admin = Laboran, super_admin = Kepala Program
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id_user`    INT(11)      NOT NULL AUTO_INCREMENT,
  `username`   VARCHAR(50)  NOT NULL,
  `password`   VARCHAR(255) NOT NULL COMMENT 'hash bcrypt, bukan plaintext',
  `level`      ENUM('admin','super_admin') NOT NULL,
  `nip`        VARCHAR(30)  DEFAULT NULL COMMENT 'alternatif identitas login',
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_user`),
  UNIQUE KEY `uq_users_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3.2  kategori
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `kategori`;
CREATE TABLE `kategori` (
  `id_kategori`   INT(11)      NOT NULL AUTO_INCREMENT,
  `nama_kategori` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id_kategori`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3.3  barang
--      jumlah = total unit dimiliki, stok = unit tersedia saat ini
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `barang`;
CREATE TABLE `barang` (
  `id_barang`     INT(11)      NOT NULL AUTO_INCREMENT,
  `id_kategori`   INT(11)      NOT NULL,
  `kode_barang`   VARCHAR(30)  NOT NULL,
  `nama_barang`   VARCHAR(100) NOT NULL,
  `merk`          VARCHAR(100) DEFAULT NULL,
  `jumlah`        INT(11)      NOT NULL DEFAULT 0 COMMENT 'total unit dimiliki',
  `kondisi`       VARCHAR(50)  DEFAULT NULL,
  `stok`          INT(11)      NOT NULL DEFAULT 0 COMMENT 'unit tersedia',
  `tanggal_input` DATE         NOT NULL,
  `serial_number` VARCHAR(50)  DEFAULT NULL,
  PRIMARY KEY (`id_barang`),
  UNIQUE KEY `uq_barang_kode` (`kode_barang`),
  KEY `fk_barang_kategori` (`id_kategori`),
  CONSTRAINT `fk_barang_kategori` FOREIGN KEY (`id_kategori`)
    REFERENCES `kategori` (`id_kategori`) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3.4  peminjam — subjek yang meminjam (siswa/guru/staf), bukan akun login
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `peminjam`;
CREATE TABLE `peminjam` (
  `id_peminjam`    INT(11)      NOT NULL AUTO_INCREMENT,
  `nama_peminjam`  VARCHAR(100) NOT NULL,
  `nis_nip`        VARCHAR(30)  DEFAULT NULL COMMENT 'NIS untuk siswa, NIP untuk guru/staf',
  `kelas_jabatan`  VARCHAR(50)  DEFAULT NULL COMMENT 'contoh: XII TKJ 1, atau nama jabatan',
  `no_hp`          VARCHAR(20)  DEFAULT NULL,
  PRIMARY KEY (`id_peminjam`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3.5  peminjaman — header transaksi
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `peminjaman`;
CREATE TABLE `peminjaman` (
  `id_peminjaman`     INT(11)     NOT NULL AUTO_INCREMENT,
  `kode_peminjaman`   VARCHAR(20) NOT NULL COMMENT 'format PMJ-2026-001, generate otomatis',
  `id_peminjam`       INT(11)     NOT NULL,
  `id_user`           INT(11)     NOT NULL COMMENT 'Laboran yang mencatat',
  `tanggal_pinjam`    DATE        NOT NULL,
  `tanggal_kembali`   DATE        NOT NULL COMMENT 'rencana/jatuh tempo',
  `status`            ENUM('menunggu_verifikasi','dipinjam','sebagian_kembali','dikembalikan','dibatalkan')
                      NOT NULL DEFAULT 'menunggu_verifikasi',
  `alasan_dibatalkan` VARCHAR(255) DEFAULT NULL COMMENT 'diisi saat Kepala Program reject',
  PRIMARY KEY (`id_peminjaman`),
  UNIQUE KEY `uq_peminjaman_kode` (`kode_peminjaman`),
  KEY `fk_peminjaman_peminjam` (`id_peminjam`),
  KEY `fk_peminjaman_user` (`id_user`),
  KEY `idx_peminjaman_status` (`status`),
  CONSTRAINT `fk_peminjaman_peminjam` FOREIGN KEY (`id_peminjam`)
    REFERENCES `peminjam` (`id_peminjam`) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `fk_peminjaman_user` FOREIGN KEY (`id_user`)
    REFERENCES `users` (`id_user`) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3.6  peminjaman_detail — pivot multi-barang per transaksi
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `peminjaman_detail`;
CREATE TABLE `peminjaman_detail` (
  `id_detail`     INT(11) NOT NULL AUTO_INCREMENT,
  `id_peminjaman` INT(11) NOT NULL,
  `id_barang`     INT(11) NOT NULL,
  `jumlah_pinjam` INT(11) NOT NULL,
  PRIMARY KEY (`id_detail`),
  KEY `fk_detail_peminjaman` (`id_peminjaman`),
  KEY `fk_detail_barang` (`id_barang`),
  CONSTRAINT `fk_detail_peminjaman` FOREIGN KEY (`id_peminjaman`)
    REFERENCES `peminjaman` (`id_peminjaman`) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT `fk_detail_barang` FOREIGN KEY (`id_barang`)
    REFERENCES `barang` (`id_barang`) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3.7  pengembalian — per item (mengacu peminjaman_detail, bukan header)
--      jumlah_hari_telat & denda dihitung backend, bukan trigger DB
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `pengembalian`;
CREATE TABLE `pengembalian` (
  `id_pengembalian`      INT(11)       NOT NULL AUTO_INCREMENT,
  `id_detail`            INT(11)       NOT NULL,
  `tanggal_pengembalian` DATE          NOT NULL,
  `kondisi`              ENUM('baik','rusak') NOT NULL,
  `jumlah_hari_telat`    INT(11)       NOT NULL DEFAULT 0,
  `denda`                DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id_pengembalian`),
  UNIQUE KEY `uq_pengembalian_detail` (`id_detail`) COMMENT 'satu detail hanya bisa dikembalikan sekali',
  CONSTRAINT `fk_pengembalian_detail` FOREIGN KEY (`id_detail`)
    REFERENCES `peminjaman_detail` (`id_detail`) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3.8  pengaturan_denda — tarif denda per hari (FR-11)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `pengaturan_denda`;
CREATE TABLE `pengaturan_denda` (
  `id_pengaturan`  INT(11)       NOT NULL AUTO_INCREMENT,
  `tarif_per_hari` DECIMAL(10,2) NOT NULL,
  `updated_at`     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_pengaturan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3.9  stok_mutasi — penyesuaian stok manual (FR-13)
--      terpisah dari perubahan stok akibat peminjaman/pengembalian
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `stok_mutasi`;
CREATE TABLE `stok_mutasi` (
  `id_mutasi`      INT(11)      NOT NULL AUTO_INCREMENT,
  `id_barang`      INT(11)      NOT NULL,
  `id_user`        INT(11)      NOT NULL COMMENT 'Laboran yang mencatat',
  `jenis`          ENUM('masuk','keluar') NOT NULL,
  `jumlah`         INT(11)      NOT NULL,
  `keterangan`     VARCHAR(255) DEFAULT NULL,
  `tanggal_mutasi` DATE         NOT NULL,
  PRIMARY KEY (`id_mutasi`),
  KEY `fk_mutasi_barang` (`id_barang`),
  KEY `fk_mutasi_user` (`id_user`),
  CONSTRAINT `fk_mutasi_barang` FOREIGN KEY (`id_barang`)
    REFERENCES `barang` (`id_barang`) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `fk_mutasi_user` FOREIGN KEY (`id_user`)
    REFERENCES `users` (`id_user`) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
