@echo off

:Start

SET MACHINE=erpnext
SET CONTAINER_NAME=erpnext

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i

echo Transfering '%PACKAGE%' From Docker container '%CONTAINER_NAME%'...
docker exec -ti %CONTAINER_NAME% cat /root/frappe_passwords.txt
echo.
docker cp "%CONTAINER_NAME%:/root/frappe_passwords.txt" "passwords.txt"
echo   "%CONTAINER_NAME%:/root/frappe_passwords.txt"-^> "passwords.txt"
echo.

:Finish
echo.
echo Finished.
echo.

:Exit
echo Press any key to exit.
pause > nul