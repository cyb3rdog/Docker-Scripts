@echo off

SET MACHINE=odoo
SET HOST_NAME=odoo

SET PG_NAME=pgadmin
SET PG_PORT=8080
SET PG_USER=odoo
SET PG_PASS=odoo
SET PG_IMAGE=dpage/pgadmin4

REM ------ VARIABLES ------
:Variables
ECHO Setting Enviroment Variables for User '%USERNAME%'...

SETLOCAL ENABLEDELAYEDEXPANSION
FOR /f "tokens=*" %%i IN ('docker-machine env %MACHINE%') DO %%i

REM ------ PGADMIN ------
ECHO Installing '%PG_NAME%' from '%PG_IMAGE%'...
docker run --name %PG_NAME% -h "%HOST_NAME%" -p %PG_PORT%:80 -e "PGADMIN_DEFAULT_EMAIL=%PG_USER%" -e "PGADMIN_DEFAULT_PASSWORD=%PG_PASS%" -d %PG_IMAGE%


:Exit
ECHO.
ECHO Finished. Press any key to quit.
pause > nul