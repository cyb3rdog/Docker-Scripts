@echo off

SET MACHINE=ODOO
SET CONTAINER_NAME=odoo

REM ------ VARIABLES ------
:Variables
ECHO Setting Enviroment Variables for User '%USERNAME%'...

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i

REM ------ SHELL ------
ECHO.
ECHO Logging into the machine's '%MACHINE%' container '%CONTAINER_NAME%'...
ECHO Type 'exit' to quit the shell.
ECHO.

REM docker exec -it -u root %CONTAINER_NAME% /bin/bash
docker-machine ssh %MACHINE%