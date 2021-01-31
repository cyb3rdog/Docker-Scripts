@echo off


SET MACHINE=
IF NOT "%1"=="" SET MACHINE=%1

IF NOT DEFINED MACHINE docker-machine ls
IF NOT DEFINED MACHINE ECHO.
IF NOT DEFINED MACHINE SET /p MACHINE="Machine? [default]: " || SET MACHINE=default


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