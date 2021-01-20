@echo off

SET MACHINE=BATOCERA
SET SW_NAME=batocera-docker
SET SHARE_NAME=docker_share

IF NOT "%1"=="" SET MACHINE=%1
IF NOT "%2"=="" SET SW_NAME=%2

REM ------ VARIABLES ------
:Variables
ECHO Setting Enviroment Variables for User '%USERNAME%'...

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i

REM ------ SHELL ------
ECHO.
ECHO Logging into the machine '%MACHINE%'...
ECHO Type 'docker exec -it -u root %SW_NAME% /bin/bash' to shell container
ECHO Type 'exit' to quit the shell.
ECHO.
ansicon -p
docker-machine ssh %MACHINE%