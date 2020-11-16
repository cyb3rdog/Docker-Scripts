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
ECHO ---   %%1 - Docker Virtual Machine Name                                      ---
ECHO ---   %%2 - Docker Container Name                                            ---
ECHO ---   %%3 - Host Name                                                        ---
ECHO ---   %%4 - Password                                                         ---
ECHO --- Usage Examples:                                                         ---
ECHO ---  DOCKER_ODOO_START                                                      ---
ECHO ---  DOCKER_ODOO_START odoo odoo odoo odoo                                  ---
ECHO -------------------------------------------------------------------------------
REM --- Author : Vaclav Macha                                                   ---
REM -------------------------------------------------------------------------------

SET VM_MEMORY=8192
SET VM_DISK_SIZE=5000
SET VM_DRIVER=virtualbox
SET VM_NIC_MODE=deny

SET MACHINE=ODOO
SET HOST_NAME=ODOO

SET DB_NAME=db
SET DB_PORT=5432
SET DB_IMAGE=postgres:10

SET PG_NAME=pgadmin
SET PG_PORT=8080
SET PG_USER=admin@odoo
SET PG_PASS=odoo
SET PG_IMAGE=dpage/pgadmin4

SET SW_NAME=odoo
SET SW_PORT=8069
SET SW_USER=odoo
SET SW_PASS=odoo
SET SW_IMAGE=odoo:latest

SET HOSTS_FILE=%WINDIR%\system32\drivers\etc\hosts

IF NOT "%1"=="" SET MACHINE=%1
IF NOT "%2"=="" SET SW_NAME=%2
IF NOT "%3"=="" SET HOST_NAME=%3
IF NOT "%4"=="" SET SW_PASS=%4


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


REM ------ REMOVE ------
:Remove
ECHO Done.
ECHO.
ECHO Checking Existing Docker Containers...
SETLOCAL ENABLEDELAYEDEXPANSION
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -a -q -f name^="%SW_NAME%"`) DO SET DOCKER_SW_CID=%%F
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -a -q -f name^="%DB_NAME%"`) DO SET DOCKER_DB_CID=%%F
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -a -q -f name^="%PG_NAME%"`) DO SET DOCKER_PG_CID=%%F

IF "%DOCKER_SW_CID%"=="" GOTO Select
GOTO Restart

REM ------ DELETE ------

ECHO Container '%SW_NAME%' already exist.
CHOICE /M "- Do you want to delete this container: "
IF ERRORLEVEL 2 GOTO Restart
ECHO Removing '%DOCKER_SW_CID%'...
docker rm -f %DOCKER_PG_CID%
docker rm -f %DOCKER_DB_CID%
docker rm -f %DOCKER_SW_CID%


REM ------ SELECT ------
:Select

REM ------ INSTALL ------
:Install
ECHO Done.
ECHO.
ECHO Installing '%DB_NAME%' from '%DB_IMAGE%'...
docker run --name %DB_NAME% -h "%HOST_NAME%" -p %DB_PORT%:%DB_PORT% -e POSTGRES_USER=%SW_USER% -e POSTGRES_PASSWORD=%SW_PASS% -e POSTGRES_DB=postgres -d %DB_IMAGE%
ECHO.
ECHO Installing '%PG_NAME%' from '%PG_IMAGE%'...
docker run --name %PG_NAME% -h "%HOST_NAME%" -p %PG_PORT%:80 --link %DB_NAME%:%DB_NAME% -e "PGADMIN_DEFAULT_EMAIL=%PG_USER%" -e "PGADMIN_DEFAULT_PASSWORD=%PG_PASS%" -d %PG_IMAGE%
ECHO.
ECHO Installing '%SW_NAME%' from '%SW_IMAGE%'...
docker run --name %SW_NAME% -h "%HOST_NAME%" -p 80:%SW_PORT% --link %DB_NAME%:%DB_NAME% -t -d %SW_IMAGE%

ECHO.
GOTO Start


REM ------ RESTART ------
:Restart
ECHO Done.
ECHO.
SETLOCAL ENABLEDELAYEDEXPANSION
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -q -f status^=running -f name^="%SW_NAME%"`) DO (  
  ECHO Container '%SW_NAME%' is already running.
  CHOICE /M "- Do you want to restart this container: "
  IF ERRORLEVEL 2 GOTO Hosts
  ECHO Restarting Container '%SW_NAME%'...
  docker restart %SW_NAME%
  GOTO Hosts
)


REM ------ START ------
:Start
ECHO Starting Containers...
docker start %DB_NAME%
docker start %PG_NAME%
docker start %SW_NAME%
GOTO Hosts


REM ------ HOSTS ------
:Hosts
ECHO Done.
ECHO.
ECHO Scanning the '%HOSTS_FILE%' for line:
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
ECHO Server Info :
ECHO Server		= 	%HOST_IP%
ECHO User 		=	%SW_USER%
ECHO Pass		= 	%SW_PASS%
ECHO Web		=	http://%HOST_IP%/
ECHO Web		=	http://%HOST_NAME%/
ECHO PgAdmin		=	http://%HOST_IP%:%PG_PORT%
ECHO PgAdmin		=	http://%HOST_NAME%:%PG_PORT%
ECHO.

REM ------ SHELL ------
start "" http://%HOST_NAME%/
ECHO.
ECHO Logging into the container '%SW_NAME%'...
ECHO Type 'exit' to quit the shell.
ECHO.
REM docker run -it odoo bash
docker exec -it -u root %SW_NAME% /bin/bash

:Exit
ECHO.
ECHO Finished. Press any key to quit.
pause > nul
