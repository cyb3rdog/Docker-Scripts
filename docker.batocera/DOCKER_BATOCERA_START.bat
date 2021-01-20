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
ECHO --- Usage Examples:                                                         ---
ECHO ---  DOCKER-BATOCERA-SIMPLE                                                 ---
ECHO ---  DOCKER-BATOCERA-SIMPLE BATOCERA batocera-docker                        ---
ECHO -------------------------------------------------------------------------------

SET VM_MEMORY=4086
SET VM_DISK_SIZE=5000
SET VM_DRIVER=virtualbox
SET VM_NIC_MODE=deny

SET SHARE_NAME=docker_share
SET SHARE_DIR=%CD%

SET MACHINE=BATOCERA
SET HOST_NAME=BATOCERA

SET SW_NAME=batocera-docker
SET SW_IMAGE=batocera-docker

IF NOT "%1"=="" SET MACHINE=%1
IF NOT "%2"=="" SET SW_NAME=%2


REM ------ Machine ------
:Machine
ECHO.
ECHO Searching for Docker Virtual Machine '%MACHINE%'...
FOR /F "USEBACKQ tokens=1" %%i IN (`docker-machine ls`) DO (  
  IF %%i==%MACHINE% SET DOCKER_MACHINE_NAME=%%i
)
IF "%DOCKER_MACHINE_NAME%"=="%MACHINE%" GOTO Boot

ECHO Docker Virtual Machine '%MACHINE%' not Found!
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
REM "c:\Program Files\Oracle\VirtualBox\VBoxManage.exe" sharedfolder add %MACHINE% --name "%SHARE_NAME%" --hostpath %cd%\%SHARE_SUB_DIR%
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
docker-machine regenerate-certs %MACHINE% --force


REM ------ ADD SHARE ------
:Share
ECHO Done.
ECHO.
ECHO Mounting share '%SHARE_NAME%' at mount point '/%SHARE_NAME%'...

REM "c:\Program Files\Oracle\VirtualBox\VBoxManage.exe" sharedfolder add %MACHINE% --name "%SHARE_NAME%" --hostpath "%SHARE_DIR%"
REM docker plugin install --grant-all-permissions vieux/sshfs
REM docker volume create --driver vieux/sshfs -o sshcmd=test@node2:/home/test -o password=testpassword sshvolume
docker-machine ssh %MACHINE% 'sudo mkdir --parents /%SHARE_NAME%'
docker-machine ssh %MACHINE% 'sudo mount -t vboxsf %SHARE_NAME% /%SHARE_NAME%'


REM ------ GIT CLONE ------
:Build
ECHO Done.
ECHO.
ECHO Clonning GitHub Repository 'batocera.linux'...

git clone https://github.com/batocera-linux/batocera.linux.git batocera.linux
cd batocera.linux
git submodule init
git submodule update
cd ..


REM ------ BUILD ------
:Build
ECHO Done.
ECHO.
ECHO Building new image '%SW_NAME%' from '%SW_IMAGE%'...
docker build -t %SW_NAME% https://raw.githubusercontent.com/batocera-linux/batocera.linux/master/Dockerfile


REM ------ START ------
:Start
ECHO Done.
ECHO.
ECHO Starting Containers...
REM docker container run --user $(id -u) -it --rm -v %CD%/.:/build %SW_NAME%
docker run -it --rm --name %SW_NAME% -h "%MACHINE%" --user root -v /%SHARE_NAME%/batocera.linux:/build -w /build -d %SW_NAME%
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
