<?php
include "koneksi.php";

$query = mysqli_query($conn, "
SELECT tbl_barang.*, kategori.nama_kategori
FROM tbl_barang
JOIN kategori ON tbl_barang.id_kategori = kategori.id_kategori
");

$data = array();

while($row = mysqli_fetch_assoc($query)){
    $data[] = $row;
}

echo json_encode($data);
?>