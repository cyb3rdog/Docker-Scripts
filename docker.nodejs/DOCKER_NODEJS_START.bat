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
ECHO ---   %%3 - Host Name                                                       ---
ECHO ---   %%4 - Password                                                        ---
ECHO --- Usage Examples:                                                         ---
ECHO ---  DOCKER_NODEJS_START                                                    ---
ECHO ---  DOCKER_NODEJS_START NODEJS nodejs NODE                                 ---
ECHO -------------------------------------------------------------------------------

SET SHARE_SUB_DIR=docker_web_app
SET SHARE_NAME=docker_web_app

SET VM_MEMORY=4086
SET VM_DISK_SIZE=10000
SET VM_DRIVER=virtualbox
SET VM_NIC_MODE=deny

SET MACHINE=NODEJS
SET HOST_NAME=NODE

SET DB_NAME=redis
SET DB_PORT=6379
SET DB_PARAM=redis-server
SET DB_IMAGE=redis:latest

SET SQL_NAME=mssql
SET SQL_USER=sa
SET SQL_PASS=Admin123
SET SQL_PORT=1433
SET SQL_IMAGE_TAG=microsoft/mssql-server-linux:latest

SET SW_NAME=nodejs
SET SW_PORT=8080
SET SW_IMAGE=node:latest

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
"c:\Program Files\Oracle\VirtualBox\VBoxManage.exe" sharedfolder add %MACHINE% --name "%SHARE_NAME%" --hostpath %cd%\%SHARE_SUB_DIR%
REM TODO: Try --virtualbox-share-folder
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
CHOICE /M "- Regenerate certificates? :"
IF ERRORLEVEL 2 GOTO Share
docker-machine regenerate-certs %MACHINE% --force


REM ------ ADD SHARE ------
:Share
ECHO Done.
ECHO.
ECHO Creating share '%SHARE_NAME%'...

REM docker plugin install --grant-all-permissions vieux/sshfs
REM docker volume create --driver vieux/sshfs -o sshcmd=test@node2:/home/test -o password=testpassword sshvolume
docker-machine.exe ssh %MACHINE% 'sudo mkdir --parents /%SHARE_SUB_DIR%'
docker-machine.exe ssh %MACHINE% 'sudo mount -t vboxsf %SHARE_NAME% /%SHARE_SUB_DIR%'


REM ------ REMOVE ------
:Remove
ECHO Done.
ECHO.
ECHO Checking Existing Docker Containers...
SETLOCAL ENABLEDELAYEDEXPANSION
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -a -q -f name^="%SW_NAME%"`) DO SET DOCKER_SW_CID=%%F
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -a -q -f name^="%DB_NAME%"`) DO SET DOCKER_DB_CID=%%F
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -a -q -f name^="%SQL_NAME%"`) DO SET DOCKER_SQL_CID=%%F

IF "%DOCKER_SW_CID%"=="" GOTO Select
GOTO Restart

REM ------ DELETE ------

ECHO Container '%SW_NAME%' already exist.
CHOICE /M "- Do you want to delete this container: "
IF ERRORLEVEL 2 GOTO Restart
ECHO Removing '%DOCKER_SW_CID%', '%DOCKER_DB_CID%', '%DOCKER_SQL_CID%'...
docker stop %DOCKER_SQL_CID%
docker stop %DOCKER_DB_CID%
docker stop %DOCKER_SW_CID%

docker rm -f %DOCKER_SQL_CID%
docker rm -f %DOCKER_DB_CID%
docker rm -f %DOCKER_SW_CID%


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

IF ERRORLEVEL 1 SET SQL_PID=Developer
IF ERRORLEVEL 2 SET SQL_PID=Express
IF ERRORLEVEL 3 SET SQL_PID=Standard
IF ERRORLEVEL 4 SET SQL_PID=Enterprise
IF ERRORLEVEL 5 SET SQL_PID=EnterpriseCore


REM ------ INSTALL ------
:Install
ECHO Done.
ECHO.
ECHO Installing '%DB_NAME%' from '%DB_IMAGE%'...
docker run --name %DB_NAME% -h "%HOST_NAME%" -p %DB_PORT%:%DB_PORT% -v "/%SHARE_SUB_DIR%":/data -d %DB_IMAGE% %DB_PARAM%
ECHO.
ECHO Installing '%SQL_NAME%' from '%SQL_IMAGE%'...
docker run --name "%SQL_NAME%" -h "%HOST_NAME%" -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=%SQL_PASS%" -e "SQL_PID=%SQL_PID%" -p %SQL_PORT%:%SQL_PORT% -d %SQL_IMAGE_TAG%
ECHO.
ECHO Installing '%SW_NAME%' from '%SW_IMAGE%'...
docker run --name %SW_NAME% -h "%HOST_NAME%" -p 80:%SW_PORT% -v "/%SHARE_SUB_DIR%":/usr/src/app -w /usr/src/app -t -d %SW_IMAGE%

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
ECHO Done.
ECHO.
ECHO Starting Containers...
docker start %SQL_NAME%
docker start %DB_NAME%
docker start %SW_NAME%

docker exec -itd %SW_NAME% /bin/bash ./.start.sh


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
attrib -R -H -S %HOSTS_FILE% /s /d
ECHO. >> %HOSTS_FILE%
ECHO %HOST_IP%	%HOST_NAME% >> %HOSTS_FILE%

:EditHosts
CHOICE /M "Do you want to edit the host file: "
IF ERRORLEVEL 2 GOTO Finish
notepad.exe %HOSTS_FILE%
attrib +R +H +S %HOSTS_FILE% /s /d


REM ------ FINISH ------
:Finish
ECHO Done.
ECHO.
ECHO Server Info :
ECHO Server		= 	%HOST_IP%
ECHO Web		=	http://%HOST_IP%/
ECHO Web		=	http://%HOST_NAME%/
ECHO SQL Server	= 	%HOST_IP%:%SQL_PORT%
ECHO SQL User 	=	%SQL_USER%
ECHO SQL Pass	= 	%SQL_PASS%
ECHO.

start "" http://%HOST_NAME%/

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
docker-machine ssh %MACHINE%


REM ------ EXIT ------
:Exit
ECHO.
ECHO Finished. Press any key to quit.
pause > nul
