<?php
include "koneksi.php";

$username = $_POST['username'];
$password = $_POST['password'];

$query = mysqli_query($conn, "
SELECT * FROM user 
WHERE username='$username' AND password='$password'
");

$data = mysqli_fetch_assoc($query);

if($data){
    echo json_encode([
        "status" => "success",
        "data" => $data
    ]);
}else{
    echo json_encode([
        "status" => "fail"
    ]);
}
?>