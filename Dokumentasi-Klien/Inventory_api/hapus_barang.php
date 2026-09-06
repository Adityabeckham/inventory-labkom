<?php
include "koneksi.php";

$id_barang = $_POST['id_barang'];

$query = mysqli_query($conn, "
DELETE FROM tbl_barang WHERE id_barang='$id_barang'
");

if($query){
    echo json_encode(["status" => "success"]);
}else{
    echo json_encode(["status" => "fail"]);
}
?>