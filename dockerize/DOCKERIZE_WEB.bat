@echo off

SET MACHINE=
SET SW_PORT=

IF NOT "%1"=="" SET MACHINE=%1
IF NOT "%2"=="" SET SW_PORT=%2

IF NOT DEFINED MACHINE docker-machine ls
IF NOT DEFINED MACHINE ECHO.
IF NOT DEFINED MACHINE SET /p MACHINE="Machine? [default]: " || SET MACHINE=default
IF NOT DEFINED MACHINE SET /p SW_PORT="Port? [80]: "         || SW_PORT=80


REM ------ VARIABLES ------
:Variables
ECHO Setting Enviroment Variables for User '%USERNAME%'...

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i
FOR /F "USEBACKQ tokens=1" %%i IN (`docker-machine ip %MACHINE%`) DO SET HOST_IP=%%i


REM ------ WEB ------
start "" http://%HOST_IP%:%SW_PORT%/