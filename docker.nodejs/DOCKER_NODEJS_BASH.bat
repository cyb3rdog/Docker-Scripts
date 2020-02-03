@echo off

SET MACHINE=NODEJS
SET CONTAINER_NAME=nodejs

REM ------ VARIABLES ------
:Variables
ECHO Setting Enviroment Variables for User '%USERNAME%'...

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i

REM ------ SHELL ------
ECHO.
ECHO Logging into the machine '%MACHINE%'...
ECHO Type 'docker exec -it -u root %CONTAINER_NAME% /bin/bash' to shell container
ECHO Type 'exit' to quit the shell.
ECHO.
docker-machine ssh %MACHINE%