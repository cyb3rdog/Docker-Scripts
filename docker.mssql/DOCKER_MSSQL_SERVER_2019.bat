@echo off
REM -------------------------------------------------------------------------------
REM --- Full Installation Script, allowing you to run any of available Editions ---
REM --- of the latest official Microsoft MSSQL Server in Docker for Windows.    ---
REM --- The minimal pre-requisities to use this Script "as is" are:             ---
REM ---  * DockerToolbox                                                        ---
REM ---  * Oracle VirtualBox                                                    ---
REM -------------------------------------------------------------------------------
REM --- This Script does everything automaticaly, including creation of the     ---
REM --- Virtual Machine, if that does not exist, creating and setting up the    ---
REM --- MSSQL Docker Container, enabling it for remote connections on 1433      ---
REM -------------------------------------------------------------------------------
REM --- Script Optional Parameters:                                             ---
REM --- %1 - Docker Virtual Machine Name                                        ---
REM --- %2 - MSSQL Container Name                                               ---
REM --- %3 - MSSQL SuperAdmin (sa) Strong!Password                              ---
REM --- %4 - MSSQL Image Tag                                                    ---
REM --- Usage Example:                                                          ---
REM ---  DOCKER_MSSQL_SERVER default MSSQL Preactor123                          ---
REM -------------------------------------------------------------------------------
REM --- Author : Vaclav Macha, Minerva                                          ---
REM -------------------------------------------------------------------------------


SET MACHINE=MSSQL-2019
SET VM_MEMORY=4098
SET VM_DISK_SIZE=20000
SET VM_DRIVER=virtualbox
SET VM_NIC_MODE=deny

SET HOST_NAME=MSSQL-2019
SET CONTAINER_NAME=MSSQL

SET MSSQL_IMAGE_TAG=mcr.microsoft.com/mssql/server:2019-latest
SET MSSQL_USER=sa
SET MSSQL_PASS=Preactor123
SET MSSQL_PORT=1433

SET HOSTS_FILE=%WINDIR%\system32\drivers\etc\hosts

IF NOT "%1"=="" SET MACHINE=%1
IF NOT "%2"=="" SET CONTAINER_NAME=%2
IF NOT "%3"=="" SET MSSQL_IMAGE_TAG=%3
IF NOT "%4"=="" SET MSSQL_PASS=%4


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
  SET DOCKER_MSSQL_CID=%%F
)

IF "%DOCKER_MSSQL_CID%"=="" GOTO Select
ECHO Container '%CONTAINER_NAME%' already exist.
GOTO Restart
CHOICE /M "- Do you want to delete this container: "
IF ERRORLEVEL 2 GOTO Restart
ECHO Removing '%DOCKER_MSSQL_CID%'...
docker rm -f %DOCKER_MSSQL_CID%


REM ------ SELECT ------
:Select
ECHO Done.
ECHO.
ECHO Available SQL Server Editions:
ECHO 1. Developer      : This will run the container using the Developer Edition
ECHO 2. Express        : This will run the container using the Express Edition
ECHO 3. Standard       : This will run the container using the Standard Edition
ECHO 4. Enterprise     : This will run the container using the Enterprise Edition
ECHO 5. EnterpriseCore : This will run the container using the Enterprise Core
ECHO.
CHOICE /C 12345 /M "- Select MSSQL Edition: "

IF ERRORLEVEL 1 SET MSSQL_PID=Developer
IF ERRORLEVEL 2 SET MSSQL_PID=Express
IF ERRORLEVEL 3 SET MSSQL_PID=Standard
IF ERRORLEVEL 4 SET MSSQL_PID=Enterprise
IF ERRORLEVEL 5 SET MSSQL_PID=EnterpriseCore


REM ------ INSTALL ------
:Install
ECHO Done.
ECHO.
ECHO Installing '%CONTAINER_NAME%' from '%MSSQL_IMAGE_TAG%'...
docker run --name "%CONTAINER_NAME%" -h "%HOST_NAME%" -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=%MSSQL_PASS%" -e "MSSQL_PID=%MSSQL_PID%" -p %MSSQL_PORT%:%MSSQL_PORT% -d %MSSQL_IMAGE_TAG%
ECHO.
ECHO Installed Edition 	= 	%MSSQL_PID%
GOTO Hosts


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
  GOTO Hosts
)


REM ------ START ------
:Start
ECHO Starting Container '%CONTAINER_NAME%'...
docker start %CONTAINER_NAME%


REM ------ HOSTS ------
:Hosts
ECHO Done.
ECHO.
ECHO Scanning the '%HOSTS_FILE%' for :
ECHO %HOST_IP%	%HOST_NAME%

FOR /F "USEBACKQ tokens=2" %%i IN (%HOSTS_FILE%) DO (  
  IF %%i==%HOST_NAME% SET HOSTS_FOUND=Yes
)
IF "%HOSTS_FOUND%"=="Yes" (
  ECHO Host name '%HOST_NAME%' found.
  GOTO EditHosts
)
ECHO Hosts name '%HOST_NAME%' not found. Appending...
ECHO. >> %HOSTS_FILE%
ECHO %HOST_IP%	%HOST_NAME% >> %HOSTS_FILE%

:EditHosts
CHOICE /M "Do you want to edit the host file: "
IF ERRORLEVEL 2 GOTO Finish

attrib -R -H -S %HOSTS_FILE% /s /d
notepad.exe %HOSTS_FILE%

REM ------ FINISH ------
:Finish
ECHO Done.
ECHO.
ECHO MSSQL-Server Info :
ECHO Conatainer	= 	%CONTAINER_NAME%
ECHO Server		= 	%HOST_IP%:%MSSQL_PORT%
ECHO User 		=	%MSSQL_USER%
ECHO Pass		= 	%MSSQL_PASS%
ECHO.


:Exit
ECHO.
ECHO Finished. Press any key to exit.
pause > nul
