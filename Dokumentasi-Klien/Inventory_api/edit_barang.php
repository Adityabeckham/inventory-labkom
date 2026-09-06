<?php
include "koneksi.php";

$id_barang = $_POST['id_barang'];
$nama_barang = $_POST['nama_barang'];
$jumlah = $_POST['jumlah'];
$kondisi = $_POST['kondisi'];
$tanggal_input = $_POST['tanggal_input'];
$id_kategori = $_POST['id_kategori'];

$query = mysqli_query($conn, "
UPDATE tbl_barang SET 
nama_barang='$nama_barang',
jumlah='$jumlah',
kondisi='$kondisi',
tanggal_input='$tanggal_input',
id_kategori='$id_kategori'
WHERE id_barang='$id_barang'
");

if($query){
    echo json_encode(["status" => "success"]);
}else{
    echo json_encode(["status" => "fail"]);
}
?>