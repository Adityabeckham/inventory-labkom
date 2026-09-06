<?php

include 'koneksi.php';

$id_peminjam = $_POST['id_peminjam'];

$query = mysqli_query($conn,
"DELETE FROM peminjam WHERE id_peminjam='$id_peminjam'");

if($query){

    echo json_encode(array(
        "success" => true,
        "message" => "Data berhasil dihapus"
    ));

}else{

    echo json_encode(array(
        "success" => false,
        "message" => "Data gagal dihapus"
    ));
}

?>