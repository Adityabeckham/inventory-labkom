<?php

include 'koneksi.php';

$id_peminjam     = $_POST['id_peminjam'];
$id_user         = $_POST['id_user'];
$tanggal_pinjam  = $_POST['tanggal_pinjam'];
$tanggal_kembali = $_POST['tanggal_kembali'];

$id_barang       = $_POST['id_barang'];
$jumlah_pinjam   = $_POST['jumlah_pinjam'];

$status = "dipinjam";

$query = mysqli_query($conn, "INSERT INTO peminjaman
(id_peminjam, id_user, tanggal_pinjam, tanggal_kembali, status)
VALUES
('$id_peminjam','$id_user','$tanggal_pinjam','$tanggal_kembali','$status')");

if($query){

    $id_peminjaman = mysqli_insert_id($conn);

    $detail = mysqli_query($conn, "INSERT INTO detail_peminjaman
    (id_peminjaman, id_barang, jumlah_pinjam)
    VALUES
    ('$id_peminjaman','$id_barang','$jumlah_pinjam')");

    $stok = mysqli_query($conn, "UPDATE tbl_barang SET
    jumlah = jumlah - '$jumlah_pinjam'
    WHERE id_barang='$id_barang'");

    echo json_encode(array(
        "success" => true,
        "message" => "Peminjaman berhasil"
    ));

}else{

    echo json_encode(array(
        "success" => false,
        "message" => "Peminjaman gagal"
    ));
}

?>