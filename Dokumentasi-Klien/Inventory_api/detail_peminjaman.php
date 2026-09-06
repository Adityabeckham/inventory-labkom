<?php

include 'koneksi.php';

$id_peminjaman = $_GET['id_peminjaman'];

$query = mysqli_query($conn, "SELECT
detail_peminjaman.id_detail,
barang.nama_barang,
detail_peminjaman.jumlah_pinjam

FROM detail_peminjaman

JOIN barang
ON detail_peminjaman.id_barang = barang.id_barang

WHERE detail_peminjaman.id_peminjaman='$id_peminjaman'");

$data = array();

while($row = mysqli_fetch_assoc($query)){
    $data[] = $row;
}

echo json_encode(array(
    "success" => true,
    "data" => $data
));

?>