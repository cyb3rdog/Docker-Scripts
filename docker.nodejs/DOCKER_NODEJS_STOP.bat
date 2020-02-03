@echo off

SET MACHINE=NODEJS

SET SQL_NAME=mssql
SET DB_NAME=redis
SET SW_NAME=nodejs


REM ------ VARIABLES ------
:Variables
ECHO Setting Enviroment Variables for User '%USERNAME%'...

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i


REM ------ CONTAINERS ------
ECHO Done.
ECHO.
ECHO Stopping Containers in Machine '%MACHINE%'...
docker stop %SW_NAME%
docker stop %DB_NAME%
docker stop %SQL_NAME%

REM ------ MACHINE ------
ECHO Done.
ECHO.
ECHO Checking State of Docker Virtual Machine '%MACHINE%'...
SETLOCAL ENABLEDELAYEDEXPANSION
FOR /F "tokens=* USEBACKQ" %%F IN (`docker-machine status %MACHINE%`) DO (
  SET DOCKER_MACHINE_STATUS=%%F
)
IF NOT "%DOCKER_MACHINE_STATUS%"=="Running" GOTO Exit

ECHO Done.
ECHO.
ECHO Stopping Virtual Machine '%MACHINE%'...
docker-machine stop %MACHINE%


:Exit
ECHO.
ECHO Finished. Press any key to quit.
pause > nul