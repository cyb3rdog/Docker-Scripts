@echo off

IF NOT "%1"=="" SET MACHINE=%1

IF NOT DEFINED MACHINE docker-machine ls
IF NOT DEFINED MACHINE ECHO.
IF NOT DEFINED MACHINE SET /p MACHINE="Machine? [default]: " || SET MACHINE=default

REM ------ VARIABLES ------
:Variables
ECHO Setting Enviroment Variables for User '%USERNAME%'...

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i

REM ------ SHELL ------
ECHO.
ECHO Logging into the machine '%MACHINE%'...
ECHO.
ECHO Type 'docker exec -it -u root CONTAINER_NAME /bin/bash' to shell container
ECHO Type 'exit' to quit the shell.
ECHO.
ansicon -p
docker-machine ssh %MACHINE%