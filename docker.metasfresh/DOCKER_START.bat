@echo off
REM -------------------------------------------------------------------------------
REM --- The minimal pre-requisities to use this Script "as is" are:             ---
REM ---  * DockerToolbox                                                        ---
REM ---  * Oracle VirtualBox                                                    ---
REM -------------------------------------------------------------------------------
REM --- This Script does everything automaticaly, including creation of the     ---
REM --- Virtual Machine, if that does not exist, creating and setting up the    ---
REM --- Docker Container, enabling it for remote connections on specified port  ---
REM -------------------------------------------------------------------------------
REM --- Script Optional Parameters:                                             ---
REM --- %1 - Docker Virtual Machine Name                                        ---
REM --- Usage Example:                                                          ---
REM ---  DOCKER_MSSQL_SERVER default MSSQL Preactor123                          ---
REM -------------------------------------------------------------------------------
REM --- Author : Vaclav Macha, Minerva                                          ---
REM -------------------------------------------------------------------------------


SET MACHINE=metasfresh
SET VM_MEMORY=4098
SET VM_DISK_SIZE=10000
SET VM_DRIVER=virtualbox
SET VM_NIC_MODE=deny

SET HOST_NAME=DOCKER
SET CONTAINER_NAME=metasfresh

SET IMAGE_TAG=metasfresh-docker:latest
SET IMAGE_USER=metasfresh
SET IMAGE_PASS=metasfresh
SET IMAGE_PORT=8069

SET HOSTS_FILE=%WINDIR%\system32\drivers\etc\hosts

IF NOT "%1"=="" SET MACHINE=%1
IF NOT "%2"=="" SET CONTAINER_NAME=%2
IF NOT "%3"=="" SET IMAGE_TAG=%3
IF NOT "%4"=="" SET IMAGE_PASS=%4


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

docker-machine create --driver %VM_DRIVER% --virtualbox-memory %VM_MEMORY% --virtualbox-disk-size %VM_DISK_SIZE% --virtualbox-host-dns-resolver --virtualbox-hostonly-nicpromisc %VM_NIC_MODE% %MACHINE%
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

REM SET DOCKER_CERT_PATH=C:\Users\%USERNAME%\.docker\machine\machines\default
REM SET DOCKER_HOST=tcp://192.168.99.100:2376
REM SET DOCKER_MACHINE_NAME=default
REM SET DOCKER_TLS_VERIFY=0
REM SET DOCKER_TOOLBOX_INSTALL_PATH="C:\Program Files\Docker Toolbox"

FOR /F "USEBACKQ tokens=1" %%i IN (`docker-machine ip %MACHINE%`) DO (  
  SET HOST_IP=%%i
)


REM ------ REGENERATE ------
ECHO Done.
ECHO.
ECHO Regenerating '%MACHINE%'...
docker-machine regenerate-certs %MACHINE% --force


REM ------ REMOVE ------
:Remove
ECHO Done.
ECHO.
ECHO Checking Existing Docker Containers...
SETLOCAL ENABLEDELAYEDEXPANSION
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -a -q -f name^="%CONTAINER_NAME%"`) DO (
  SET DOCKER_CONTAINER_CID=%%F
)

IF "%DOCKER_CONTAINER_CID%"=="" GOTO Select
ECHO Container '%CONTAINER_NAME%' already exist.
CHOICE /M "- Do you want to delete this container: "
IF ERRORLEVEL 2 GOTO Restart
ECHO Removing '%DOCKER_CONTAINER_CID%'...
docker rm -f %DOCKER_CONTAINER_CID%


REM ------ SELECT ------
:Select

REM ------ INSTALL ------
:Install
ECHO Done.
ECHO.
ECHO Installing '%CONTAINER_NAME%' from '%IMAGE_TAG%'...
docker run -d -e POSTGRES_USER=%IMAGE_USER% -e POSTGRES_PASSWORD=%IMAGE_PASS% --name db postgres:9.4
docker run --name %CONTAINER_NAME% -h "%HOST_NAME%" -p %IMAGE_PORT%:%IMAGE_PORT% --link db:db -t %CONTAINER_NAME% -d %IMAGE_TAG%

ECHO.
GOTO Finish


REM ------ RESTART ------
:Restart
ECHO Done.
ECHO.
SETLOCAL ENABLEDELAYEDEXPANSION
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -q -f status^=running -f name^="%CONTAINER_NAME%"`) DO (  
  ECHO Container '%CONTAINER_NAME%' is already running.
  CHOICE /M "- Do you want to restart this container: "
  IF ERRORLEVEL 2 GOTO Hosts
  ECHO Restarting Container '%CONTAINER_NAME%'...
  docker restart %CONTAINER_NAME%
  GOTO Finish
)


REM ------ START ------
:Start
ECHO Starting Container '%CONTAINER_NAME%'...
docker start db
docker start %CONTAINER_NAME%
GOTO Finish


REM ------ HOSTS ------
:Hosts
ECHO Done.
ECHO.
ECHO Scanning the '%HOSTS_FILE%' for line:
ECHO %HOST_IP%	%HOST_NAME%

FOR /F "USEBACKQ tokens=1" %%i IN (%HOSTS_FILE%) DO (  
  IF %%i==%HOST_IP% SET HOSTS_FOUND=Yes
)
IF "%HOSTS_FOUND%"=="Yes" GOTO Finish
ECHO Hosts record '%HOST_IP%' not found.
CHOICE /M "- Do you want to append it: "
IF ERRORLEVEL 2 GOTO Finish

REM notepad.exe %HOSTS_FILE%
ECHO. >> %HOSTS_FILE%
ECHO %HOST_IP%	%HOST_NAME% >> %HOSTS_FILE%


REM ------ FINISH ------
:Finish
ECHO Done.
ECHO.
ECHO Server Info :
ECHO Conatainer	= 	%CONTAINER_NAME%
ECHO Server		= 	%HOST_IP%:%IMAGE_PORT%
ECHO User 		=	%IMAGE_USER%
ECHO Pass		= 	%IMAGE_PASS%
ECHO.


:Exit
ECHO.
ECHO Finished. Press any key to exit.
pause > nul
