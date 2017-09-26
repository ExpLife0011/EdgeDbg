@ECHO OFF
SETLOCAL
FOR /F "usebackq delims=[.] tokens=2,3,4" %%I in (`ver`) DO (
  IF NOT "%%I.%%J" == "Version 10.0" (
    ECHO This application is designed to run on Windows 10.0, but you appear to be
    ECHO running %%I.%%J. EdgeBugId will try to start Edge in BugId, but there
    ECHO is no guarantee this is going to work.
  ) ELSE IF /I "%%K" LSS "15063" (
    ECHO === DEPRECATION WARNING =======================================================
    ECHO Starting with Windows 10.0.15063 ^(Creators Edition^), Edge has become a full
    ECHO Universal Windows Platform ^(UWP^) App and BugId can be used to run Edge
    ECHO directly without the need for EdgeBugId. In fact, EdgeBugId should no longer
    ECHO be used to run Edge as it will NOT debug all the sandboxed child processes
    ECHO that you are probably most interested in!
    ECHO ===============================================================================
    PAUSE
  )
)

IF "%PROCESSOR_ARCHITEW6432%" == "AMD64" (
  SET OSISA=x64
) ELSE IF "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
  SET OSISA=x64
) ELSE (
  SET OSISA=x86
)

IF NOT DEFINED cdb (
  CALL :SET_CDB_IF_EXISTS "%ProgramFiles%\Windows Kits\10\Debuggers\%OSISA%\cdb.exe"
  CALL :SET_CDB_IF_EXISTS "%ProgramFiles%\Windows Kits\8.1\Debuggers\%OSISA%\cdb.exe"
  CALL :SET_CDB_IF_EXISTS "%ProgramFiles%\Windows Kits\8.0\Debuggers\%OSISA%\cdb.exe"
  IF EXIST "%ProgramFiles(x86)%" (
    CALL :SET_CDB_IF_EXISTS "%ProgramFiles(x86)%\Windows Kits\10\Debuggers\%OSISA%\cdb.exe"
    CALL :SET_CDB_IF_EXISTS "%ProgramFiles(x86)%\Windows Kits\8.1\Debuggers\%OSISA%\cdb.exe"
    CALL :SET_CDB_IF_EXISTS "%ProgramFiles(x86)%\Windows Kits\8.0\Debuggers\%OSISA%\cdb.exe"
  )
  IF NOT DEFINED cdb (
    ECHO - Cannot find cdb.exe, please set the "cdb" environment variable to the correct path.
    EXIT /B 1
  )
) ELSE (
  :: Make sure cdb is quoted
  SET cdb="%cdb:"=%"
)
IF NOT EXIST %cdb% (
  ECHO - Cannot find cdb.exe at %cdb%, please set the "cdb" environment variable to the correct path.
  EXIT /B 1
)

IF NOT DEFINED EdgeDbg (
  SET EdgeDbg="%~dp0bin\EdgeDbg_%OSISA%.exe"
) ELSE (
  SET EdgeDbg="%EdgeDbg:"=%"
)
IF NOT EXIST %EdgeDbg% (
  ECHO - Cannot find EdgeDbg at %EdgeDbg%, please set the "EdgeDbg" environment variable to the correct path.
  EXIT /B 1
)

IF NOT DEFINED Kill (
  SET Kill="%~dp0modules\Kill\bin\Kill_%OSISA%.exe"
) ELSE (
  SET Kill="%Kill:"=%"
)
IF NOT EXIST %Kill% (
  ECHO - Cannot find Kill at %Kill%, please set the "Kill" environment variable to the correct path.
  EXIT /B 1
)

IF NOT DEFINED BugId (
  SET BugId="%~dp0..\BugId\BugId.py"
) ELSE (
  SET BugId="%BugId:"=%"
)
IF NOT EXIST %BugId% (
  ECHO - Cannot find BugId at %BugId%, please set the "BugId" environment variable to the correct path.
  EXIT /B 1
)

IF NOT DEFINED PYTHON (
  SET PYTHON="%SystemDrive%\Python27\python.exe"
) ELSE (
  SET PYTHON="%PYTHON:"=%"
)
IF NOT EXIST %PYTHON% (
  ECHO - Cannot find Python at %PYTHON%, please set the "PYTHON" environment variable to the correct path.
  EXIT /B 1
)

If "%~1" == "" (
  SET URL="http://%COMPUTERNAME%:28876/"
  SET BugIdArguments=
) ELSE (
  SET URL="%~1"
  SET BugIdArguments=%2 %3 %4 %5 %6 %7 %8 %9
)

ECHO * Terminating all running processes associated with Edge...
%Kill% ApplicationFrameHost.exe browser_broker.exe MicrosoftEdge.exe MicrosoftEdgeCP.exe RuntimeBroker.exe 
IF ERRORLEVEL 1 (
  ECHO - Cannot terminate all running processes associated with Edge.
  EXIT /B 1
)

IF EXIST "%LOCALAPPDATA%\Packages\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\AC\MicrosoftEdge\User\Default\Recovery\Active\*.*" (
  ECHO * Deleting crash recovery data...
  DEL "%LOCALAPPDATA%\Packages\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\AC\MicrosoftEdge\User\Default\Recovery\Active\*.*" /Q >nul
)

ECHO * Starting Edge in BugId...
ECHO + URL: %URL%
%EdgeDbg% %URL% %PYTHON% %BugId% --pids=@ProcessIds@ %BugIdArguments% edgedbg
EXIT /B %ERRORLEVEL%

:SET_CDB_IF_EXISTS
  IF NOT DEFINED cdb (
    IF EXIST "%~1" (
      SET cdb="%~1"
    )
  )
  EXIT /B 0
