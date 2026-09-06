<?php
$conn = mysqli_connect("localhost", "root", "", "inventory");

if(!$conn){
    die("Koneksi gagal: " . mysqli_connect_error());
}
?>