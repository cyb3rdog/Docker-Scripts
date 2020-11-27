@echo off

SET MACHINE=VECTOR
SET SW_NAME=vector-node

REM ------ VARIABLES ------
:Variables
ECHO Setting Enviroment Variables for User '%USERNAME%'...

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i
FOR /F "USEBACKQ tokens=1" %%i IN (`docker-machine ip %MACHINE%`) DO SET HOST_IP=%%i
FOR /F "USEBACKQ tokens=1" %%i IN (`docker-machine active`) DO SET MACHINE_ACTIVE=%%i

ECHO %MACHINE_ACTIVE%: '%HOST_IP%'
ECHO.

REM ------ SHELL ------
start "" http://%HOST_IP%/


echo press any key
pause > nul