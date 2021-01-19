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
ansicon -p
cmd