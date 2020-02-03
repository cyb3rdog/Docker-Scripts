@echo off
SET MACHINE=default
SET VM_MEMORY=4098
SET VM_DISK_SIZE=10000
SET VM_DRIVER=virtualbox
SET VM_NIC_MODE=deny

IF NOT "%1"=="" SET MACHINE=%1

ECHO Searching for Docker Virtual Machine '%MACHINE%'...
SETLOCAL ENABLEDELAYEDEXPANSION
FOR /F "USEBACKQ tokens=1" %%i IN (`docker-machine ls`) DO (  
  IF %%i==%MACHINE% SET DOCKER_MACHINE_NAME=%%i
)
IF NOT "%DOCKER_MACHINE_NAME%"=="%MACHINE%" GOTO Create

ECHO Virtual Machine '%MACHINE%' already exist!
CHOICE /M "Do you want to delete this virtual machine: "
IF ERRORLEVEL 2 GOTO Exit
ECHO Removing '%MACHINE%'...
docker-machine rm -f '%MACHINE%'

:Create
docker-machine create --driver %VM_DRIVER% --virtualbox-memory %VM_MEMORY% --virtualbox-disk-size %VM_DISK_SIZE% --virtualbox-host-dns-resolver --virtualbox-hostonly-nicpromisc %VM_NIC_MODE% %MACHINE%

:Exit
ECHO Done. Press any key.
pause > nul
