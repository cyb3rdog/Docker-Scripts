@echo off
REM -------------------------------------------------------------------------------
REM --- The minimal pre-requisities to use this Script "as is" are:             ---
REM ---  * DockerToolbox                                                        ---
REM ---  * Oracle VirtualBox                                                    ---
REM -------------------------------------------------------------------------------
REM --- This Script does everything automaticaly, including creation of the     ---
REM --- Virtual Machine, if that does not exist, creating and setting up the    ---
REM --- Docker Container, enabling it for remote connections on specified port  ---
ECHO -------------------------------------------------------------------------------
ECHO --- Script Optional Parameters:                                             ---
ECHO ---   %%1 - Docker Virtual Machine Name                                     ---
ECHO ---   %%2 - Docker Container Name                                           ---
ECHO ---   %%3 - Docker Image/Tag/Dockerfile to Build                            ---
ECHO --- Usage Examples:                                                         ---
ECHO ---  DOCKERIZE-CREATE-START.bat machine-name                                ---
ECHO ---  DOCKERIZE-CREATE-START.bat default default                             ---
ECHO -------------------------------------------------------------------------------

SET VM_MEMORY=4086
SET VM_DISK_SIZE=5000
SET VM_DRIVER=virtualbox
SET VM_NIC_MODE=deny

SET SHARE_NAME=docker_share
SET SHARE_DIR=%CD%

SET MACHINE=
SET SW_NAME=
SET SW_IMAGE=

IF NOT "%1"=="" SET MACHINE=%1
IF NOT "%2"=="" SET SW_NAME=%2
IF NOT "%2"=="" SET SW_IMAGE=%3

ECHO Please enter VM parameters:
ECHO.
IF NOT DEFINED MACHINE   SET /p MACHINE="Machine name? [default]: "    || SET MACHINE=default
IF NOT DEFINED SW_NAME   SET /p SW_NAME="Image/Tag name? [default]: "  || SET SW_NAME=default

SET SW_PORT=8080
SET HOSTS_FILE=%WINDIR%\system32\drivers\etc\hosts


REM ------ Machine ------
:Machine
ECHO.
ECHO Searching for Docker Virtual Machine '%MACHINE%'...
FOR /F "USEBACKQ tokens=1" %%i IN (`docker-machine ls`) DO (
  IF %%i==%MACHINE% SET DOCKER_MACHINE_NAME=%%i
)
IF "%DOCKER_MACHINE_NAME%"=="%MACHINE%" GOTO Boot

ECHO Docker Virtual Machine '%MACHINE%' not Found!
ECHO Please enter Virtual Machine parameters:
ECHO.
SET /p VM_MEMORY="Memory? [4086]: "        || SET VM_MEMORY=4086
SET /p VM_DISK_SIZE="Disk (MB)? [5000]: "  || SET VM_DISK_SIZE=5000
ECHO.
ECHO Creating New Virtual Machine '%MACHINE%'...
ECHO.

docker-machine create --driver %VM_DRIVER% --virtualbox-memory %VM_MEMORY% --virtualbox-disk-size %VM_DISK_SIZE% --virtualbox-host-dns-resolver --virtualbox-hostonly-nicpromisc %VM_NIC_MODE% --virtualbox-share-folder "%SHARE_DIR%":%SHARE_NAME% %MACHINE%
GOTO Variables


REM ------ BOOT ------
:Boot
ECHO Done.
ECHO.
ECHO Checking State of Docker Virtual Machine '%MACHINE%'...
SETLOCAL ENABLEDELAYEDEXPANSION
FOR /F "tokens=* USEBACKQ" %%F IN (`docker-machine status %MACHINE%`) DO (
  SET DOCKER_MACHINE_STATUS=%%F
)
IF "%DOCKER_MACHINE_STATUS%"=="Running" GOTO Variables

ECHO Done.
ECHO.
ECHO Booting Up Docker Virtual Machine '%MACHINE%'...
docker-machine start %MACHINE%


REM ------ VARIABLES ------
:Variables
ECHO Done.
ECHO.
ECHO Setting Enviroment Variables for User '%USERNAME%'...

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO ECHO %%i
FOR /F "USEBACKQ tokens=1" %%i IN (`docker-machine ip %MACHINE%`) DO SET HOST_IP=%%i
FOR /F "USEBACKQ tokens=1" %%i IN (`docker-machine active`) DO SET MACHINE_ACTIVE=%%i

ECHO.
ECHO - Active Machine: '%MACHINE_ACTIVE%'
ECHO - Active IP: '%HOST_IP%'


REM ------ REGENERATE ------
ECHO Done.
ECHO.
ECHO Regenerating '%MACHINE%'...
REM CHOICE /M "- Regenerate certificates? :"
REM IF ERRORLEVEL 2 GOTO Select
docker-machine regenerate-certs %MACHINE% --force


REM ------ ADD SHARE ------
:Share
ECHO Done.
ECHO.
ECHO Mounting share '%SHARE_NAME%' at mount point '/%SHARE_NAME%'...
REM "c:\Program Files\Oracle\VirtualBox\VBoxManage.exe" sharedfolder add %MACHINE% --name "%SHARE_NAME%" --hostpath "%SHARE_DIR%"


REM ------ SELECT ------
:Select
IF DEFINED SW_IMAGE GOTO Build
ECHO Done.
ECHO.
ECHO Available Options:
ECHO 1. Build          : This will build the image using 'docker build'
ECHO 2. Compose        : This will compose the image using 'docker compose'
ECHO 3. Start          : This will start the container using 'docker start'
ECHO.
CHOICE /C 123 /M "- Select: "

IF ERRORLEVEL 3 GOTO Start
IF ERRORLEVEL 2 GOTO Compose
IF ERRORLEVEL 1 GOTO Build


REM ------ BUILD ------
:Build
ECHO Done.
ECHO.
IF NOT DEFINED SW_IMAGE SET /p SW_IMAGE="Enter image tag: "    || SET SW_IMAGE=%SW_NAME%
ECHO Building new image '%SW_NAME%' from '%SW_IMAGE%'...

docker build -t %SW_NAME% .
docker run -it --rm --name %SW_NAME% -h "%MACHINE%" -p 80:%SW_PORT% -v "/%SHARE_NAME%":/usr/src/app -w /usr/src/app -d %SW_IMAGE%
GOTO Start


REM ------ COMPOSE ------
:Compose
ECHO Done.
ECHO.
ECHO Composing '%SW_NAME%'...

docker-compose up
GOTO Start


REM ------ START ------
:Start
ECHO Done.
ECHO.
ECHO Starting Containers...
docker start %SW_NAME%


REM ------ FINISH ------
:Finish
ECHO Done.
ECHO.
ECHO.

CHOICE /M "Do you want to ssh to '%MACHINE%': "
IF ERRORLEVEL 2 GOTO Exit


REM ------ SHELL ------
ECHO.
ECHO Logging into the machine '%MACHINE%'...
ECHO Type 'docker exec -it -u root %SW_NAME% /bin/bash' to shell into container
ECHO Type 'exit' to quit.
ECHO.
REM docker run -it odoo bash
REM docker exec -it -u root %SW_NAME% /bin/bash
ansicon -p
docker-machine ssh %MACHINE%


REM ------ EXIT ------
:Exit
ECHO.
ECHO Finished. Press any key to quit.
pause > nul
