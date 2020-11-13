@ECHO OFF
REM Author: Bernd Schemmer (Bernd.Schemmer@gmx.de)
REM
REM Version: 0.02 11.05.2005 
REM
SET DEF_TARGETHOST=sol9
SET DEF_SSH_USER=xtrnaw7
SET DEFAULT_DISPLAY_NUMBER=1

SET VNC_DIRECTORY="C:\Program Files\RealVNC\VNC4"
SET SSH_DIRECTORY="C:\SSH"

SET ERRMSG=vncviewer not found.
IF NOT EXIST %VNC_DIRECTORY%\vncviewer.exe GOTO ErrExit

SET ERRMSG=ssh not found
IF NOT EXIST %SSH_DIRECTORY%\ssh.exe GOTO ErrExit

SET SSH_USER=%3
IF "%SSH_USER%"x == ""x SET SSH_USER=%DEF_SSH_USER%

SET TARGETHOST=%2
IF "%TARGETHOST%"x == ""x SET TARGETHOST=%DEF_TARGETHOST%

SET DISPLAY=%1
IF "%DISPLAY%"x == "-h"x   GOTO Usage
IF "%DISPLAY%"x == "help"x GOTO Usage

IF "%DISPLAY%"x == ""x SET DISPLAY=%DEFAULT_DISPLAY_NUMBER%

SET PADCHAR=0
IF "%DISPLAY%"x == "1"x GOTO DISPOK
IF "%DISPLAY%"x == "2"x GOTO DISPOK
IF "%DISPLAY%"x == "3"x GOTO DISPOK
IF "%DISPLAY%"x == "4"x GOTO DISPOK
IF "%DISPLAY%"x == "5"x GOTO DISPOK
IF "%DISPLAY%"x == "6"x GOTO DISPOK
IF "%DISPLAY%"x == "7"x GOTO DISPOK
IF "%DISPLAY%"x == "8"x GOTO DISPOK
IF "%DISPLAY%"x == "9"x GOTO DISPOK

SET PADCHAR=
IF "%DISPLAY%"x == "38"x GOTO DISPOK

SET ERRMSG=Unknown parameter
GOTO ErrExit

:Usage
ECHO. Usage: %0 [displaynumber] [targethost] [ssh_user]
ECHO.
ECHO. Defaults:
ECHO.   displaynumber %DEFAULT_DISPLAY_NUMBER%
ECHO.   targethost    %DEF_TARGETHOST%
ECHO.   ssh_user      %DEF_SSH_USER%
ECHO.
GOTO Ende


:DISPOK
SET LOCAL_PORT=59%PADCHAR%%DISPLAY%
SET REMOTE_PORT=79%PADCHAR%%DISPLAY%

ECHO. Opening secury VNC connection to %TARGETHOST% (Display %DISPLAY%) ...

ECHO. Starting vncviewer ...
pushd "%VNC_DIRECTORY%"

ECHO. Wait until the ssh connection is established!
ECHO. Use localhost:%LOCAL_PORT% as connect string in VNC
start vncviewer.exe

ECHO. Starting local ssh ...
%SSH_DIRECTORY%\ssh  -T -l %SSH_USER% -L %LOCAL_PORT%:localhost:%REMOTE_PORT% %TARGETHOST% 
popd
pause
GOTO DISPOK

:Ende
SET ERRMSG=
exit 0

:ErrExit
ECHO.
ECHO. ERROR: %ERRMSG%
ECHO.
exit 255
