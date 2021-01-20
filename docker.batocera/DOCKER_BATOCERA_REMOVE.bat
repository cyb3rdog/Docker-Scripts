@echo off

SET MACHINE=BATOCERA

:Start
IF NOT "%1"=="" SET MACHINE=%1
IF NOT "%MACHINE%"=="" GOTO Remove

docker-machine ls
ECHO.
SET /p MACHINE="Which one? : "
IF "%MACHINE%"=="" GOTO Exit

:Remove
docker-machine rm %MACHINE%

:Exit
ECHO Done. Press any key.
pause > nul
