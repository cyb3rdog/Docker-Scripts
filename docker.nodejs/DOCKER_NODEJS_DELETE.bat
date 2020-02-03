@echo off

SET MACHINE=NODEJS

SET DB_NAME=redis
SET SQL_NAME=mssql
SET SW_NAME=nodejs

REM ------ VARIABLES ------
:Variables
ECHO Setting Enviroment Variables for User '%USERNAME%'...

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i


REM ------ REMOVE ------
ECHO Checking Existing Docker Containers...
SETLOCAL ENABLEDELAYEDEXPANSION
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -a -q -f name^="%SW_NAME%"`) DO SET DOCKER_SW_CID=%%F
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -a -q -f name^="%DB_NAME%"`) DO SET DOCKER_DB_CID=%%F
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -a -q -f name^="%SQL_NAME%"`) DO SET DOCKER_SQL_CID=%%F

IF "%DOCKER_SW_CID%"=="" GOTO Next1
docker rm -f %DOCKER_SW_CID%

:Next1
IF "%DOCKER_SQL_CID%"=="" GOTO Next2
docker rm -f %DOCKER_SQL_CID%

:Next2
IF "%DOCKER_DB_CID%"=="" GOTO Exit
docker rm -f %DOCKER_DB_CID%


:Exit
ECHO.
ECHO Finished. Press any key to quit.
pause > nul
