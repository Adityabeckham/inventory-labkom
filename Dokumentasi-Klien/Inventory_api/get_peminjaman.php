<?php

include 'koneksi.php';

$query = mysqli_query($conn, "SELECT
peminjaman.id_peminjaman,
peminjam.nama_peminjam,
barang.nama_barang,
detail_peminjaman.jumlah_pinjam,
peminjaman.tanggal_pinjam,
peminjaman.tanggal_kembali,
peminjaman.status

FROM peminjaman

JOIN peminjam
ON peminjaman.id_peminjam = peminjam.id_peminjam

JOIN detail_peminjaman
ON peminjaman.id_peminjaman = detail_peminjaman.id_peminjaman

JOIN barang
ON detail_peminjaman.id_barang = barang.id_barang

ORDER BY peminjaman.id_peminjaman DESC");

$data = array();

while($row = mysqli_fetch_assoc($query)){
    $data[] = $row;
}

echo json_encode(array(
    "success" => true,
    "data" => $data
));

?>