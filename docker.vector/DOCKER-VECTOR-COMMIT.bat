@echo off

SET MACHINE=VECTOR
SET SW_NAME=vector-node

REM ------ VARIABLES ------
:Variables
ECHO Setting Enviroment Variables for User '%USERNAME%'...

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i

docker tag %SW_NAME% cyb3rdog/%SW_NAME%:latest
docker push cyb3rdog/%SW_NAME%:latest