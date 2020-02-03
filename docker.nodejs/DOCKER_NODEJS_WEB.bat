@echo off

SET MACHINE=NODEJS
SET HOSTNAME=NODE
SET SW_NAME=nodejs

REM ------ VARIABLES ------
:Variables
ECHO Setting Enviroment Variables for User '%USERNAME%'...

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i

REM ------ SHELL ------
start "" http://%HOSTNAME%/
docker exec -it %SW_NAME% /bin/bash ./.start.sh


echo press any key
pause > nul