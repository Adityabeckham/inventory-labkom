<?php

include 'koneksi.php';

$query = mysqli_query($conn, "SELECT * FROM peminjam");

$data = array();

while($row = mysqli_fetch_assoc($query)){
    $data[] = $row;
}

echo json_encode(array(
    "success" => true,
    "data" => $data
));

?>
