@echo off
echo ===================================================
echo   Inventory Labkom — Backend PHP Server (Port 8080)
echo ===================================================
cd /d %~dp0backend
php -S 127.0.0.1:8080 -t public public/index.php
pause
