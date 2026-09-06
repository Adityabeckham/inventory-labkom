<?php

include 'koneksi.php';

$nama_peminjam = $_POST['nama_peminjam'];
$no_hp = $_POST['no_hp'];

$query = mysqli_query($conn, "INSERT INTO peminjam 
(nama_peminjam, no_hp,)
VALUES
('$nama_peminjam','$no_hp')");

if($query){

    echo json_encode(array(
        "success" => true,
        "message" => "Data berhasil ditambahkan"
    ));

}else{

    echo json_encode(array(
        "success" => false,
        "message" => "Data gagal ditambahkan"
    ));
}

?>