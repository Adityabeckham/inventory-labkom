<?php
include "koneksi.php";

$nama_barang = $_POST['nama_barang'];
$jumlah = $_POST['jumlah'];
$kondisi = $_POST['kondisi'];
$tanggal_input = $_POST['tanggal_input'];
$id_kategori = $_POST['id_kategori'];

$query = mysqli_query($conn, "
INSERT INTO tbl_barang (nama_barang, jumlah, kondisi, tanggal_input, id_kategori)
VALUES ('$nama_barang','$jumlah','$kondisi','$tanggal_input','$id_kategori')
");

if($query){
    echo json_encode([
        "status" => "success",
        "message" => "Data berhasil ditambahkan"
    ]);
}else{
    echo json_encode([
        "status" => "fail",
        "message" => "Gagal menambahkan data"
    ]);
}
?>