<?php

include 'koneksi.php';

$id_peminjam = $_POST['id_peminjam'];
$nama_peminjam = $_POST['nama_peminjam'];
$no_hp = $_POST['no_hp'];

$query = mysqli_query($conn, "UPDATE peminjam SET
nama_peminjam='$nama_peminjam',
no_hp='$no_hp',
WHERE id_peminjam='$id_peminjam'");

if($query){

    echo json_encode(array(
        "success" => true,
        "message" => "Data berhasil diupdate"
    ));

}else{

    echo json_encode(array(
        "success" => false,
        "message" => "Data gagal diupdate"
    ));
}

?>