<?php

include 'koneksi.php';

$id_peminjaman = $_POST['id_peminjaman'];

$query = mysqli_query($conn, "SELECT
detail_peminjaman.id_barang,
detail_peminjaman.jumlah_pinjam

FROM detail_peminjaman

WHERE id_peminjaman='$id_peminjaman'");

while($data = mysqli_fetch_assoc($query)){

    $id_barang = $data['id_barang'];
    $jumlah_pinjam = $data['jumlah_pinjam'];

    mysqli_query($conn, "UPDATE barang SET
    jumlah = jumlah + '$jumlah_pinjam'
    WHERE id_barang='$id_barang'");
}

$update = mysqli_query($conn, "UPDATE peminjaman SET
status='dikembalikan'
WHERE id_peminjaman='$id_peminjaman'");

if($update){

    echo json_encode(array(
        "success" => true,
        "message" => "Barang berhasil dikembalikan"
    ));

}else{

    echo json_encode(array(
        "success" => false,
        "message" => "Pengembalian gagal"
    ));
}

?>