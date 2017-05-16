@ECHO OFF

CLS
ECHO.
ECHO INSTALLING: Colligo 4.4 (SP3) ...
ECHO.

SETLOCAL
SET VERSIONPATH=%~dp0Versions\4.4SP3
SET INSTALLFLAG=1

REM Check whether the system is x64 or x86 machine
SET regpath="HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node"
REG QUERY "%regpath%" 1>NULL 2>&1

IF %ERRORLEVEL% == 0 GOTO x64
IF %ERRORLEVEL% == 1 GOTO x32

:x64
REM Check .Net Framework 4.0 Client Profile designed for both x86 and x64 computers
ECHO Checking for dotNetFramework 4.0 Client Profile Library ...
ECHO.
REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client" /v Install 2>NUL 1>NUL
IF NOT %ERRORLEVEL%==0 GOTO installNet4x64
GOTO installExtended

:installExtended
REM Check .Net Framework 4.0 Extended designed for both x86 and x64 computers
ECHO Checking for dotNetFramework 4.0 Extended Library ...
ECHO.
REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Install 2>NUL 1>NUL
IF NOT %ERRORLEVEL%==0 GOTO installNet4x64
GOTO NEXT

:installNet4x64
"%VERSIONPATH%\dotNetFx4.exe" /q /norestart /ChainingPackage ADMINDEPLOYMENT
GOTO NEXT

:NEXT
REM Check if Visual C++ redistributable x64 is currently installed
SET checkVCRedistx64 = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1D8E6291-B0D5-35EC-8441-6616F567A0F7}"
REG QUERY "%checkVCRedistx64%" 1>NULL 2>&1
IF NOT %ERRORLEVEL% == "0" GOTO installVCRedistx64

:installVCRedistx64
ECHO Checking for Visual Studio 2010 Redistributable Package (x64) ...
ECHO.
"%VERSIONPATH%\vcredist_x64.exe" /q

REM Check if Visual C++ redistributable x86 is currently installed
SET checkVCRedistx86 = "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{F0C3E5D1-1ADE-321E-8167-68EF0DE699A5}"
REG QUERY "%checkVCRedistx86%" 1>NULL 2>&1
IF NOT %ERRORLEVEL% == "0" GOTO installVCRedistx86
GOTO NEXT

:installVCRedistx86
ECHO Checking for Visual Studio 2010 Redistributable Package (x86) ...
ECHO.
"%VERSIONPATH%\vcredist_x86.exe " /q

:NEXT
ECHO Checking for Pre-requisits ...
ECHO.

REM Install Office Primary Interop Assembly 2007
MSIEXEC /i "%VERSIONPATH%\o2007PIA.MSI" /qn

REM Install Visual studio 2005 Tools for office 2nd Edition Runtime
"%VERSIONPATH%\vstor.exe" /q

ECHO Installing Colligo ...
ECHO.
MSIEXEC /qb /i "%VERSIONPATH%\ColligoContributor.msi" LICENSE_KEY=EQB42-9HNPQ-1RJGJ-PGFC4-341FH /lv* "%appdata%\colligoinstall.txt"

ECHO Align Email attachment size limit with Exchange
REG QUERY "HKEY_LOCAL_MACHINE\Software\Wow6432Node\ColligoOfflineClient\Outlook\CAMFilter\BlockLimit" /v CAMFILTER_BLOCK_LIMIT 2>NUL 1>NUL
IF NOT %ERRORLEVEL% == 0 REG ADD HKEY_LOCAL_MACHINE\Software\Wow6432Node\ColligoOfflineClient\Outlook\CAMFilter\BlockLimit /v CAMFILTER_BLOCK_LIMIT /t REG_DWORD /d 20000 /f
GOTO STATUS

:x32
REM Check .Net Framework 4.0 Client Profile designed for both x86 and x64 computers
ECHO Checking for dotNetFramework 4.0 Client Profile Library ...
ECHO.
REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client" /v Install 2>NUL 1>NUL
IF NOT %ERRORLEVEL%==0 GOTO installNet4x32
GOTO installExtended

:installExtended
REM Check .Net Framework 4.0 Extended designed for both x86 and x64 computers
ECHO Checking for dotNetFramework 4.0 Extended Library ...
ECHO.
REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Install 2>NUL 1>NUL
IF NOT %ERRORLEVEL%==0 GOTO installNet4x32
GOTO NEXT

:installNet4x32
"%VERSIONPATH%\dotNetFx4.exe" /q /norestart /ChainingPackage ADMINDEPLOYMENT
GOTO NEXT

:NEXT
REM Check if Visual C++ redistributable x86 is currently installed
SET checkVCRedistx86 = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{F0C3E5D1-1ADE-321E-8167-68EF0DE699A5}"
REG QUERY "%checkVCRedistx86%" 1>NULL 2>&1

IF NOT %ERRORLEVEL% == "0" GOTO installVCRedistx86
GOTO NEXT

:installVCRedistx86
ECHO Checking for Visual Studio 2010 Redistributable Package (x86) ...
ECHO.
"%VERSIONPATH%\vcredist_x86.exe" /q

:NEXT
ECHO Checking for Pre-requisits ...
ECHO.

REM Install Office Primary Interop Assembly 2003
MSIEXEC /i "%VERSIONPATH%\o2003PIA.MSI" /qn

REM Install Office Primary Interop Assembly 2007
MSIEXEC /i "%VERSIONPATH%\o2007PIA.MSI" /qn

REM Install Visual studio 2005 Tools for office 2nd Edition Runtime
"%VERSIONPATH%\vstor.exe" /q

ECHO Installing Colligo ...
ECHO.
MSIEXEC /qb /i "%VERSIONPATH%\ColligoContributor.msi" LICENSE_KEY=EQB42-9HNPQ-1RJGJ-PGFC4-341FH /lv* "%appdata%\colligoinstall.txt"

ECHO Align Email attachment size limit with Exchange
REG QUERY "HKEY_LOCAL_MACHINE\Software\ColligoOfflineClient\Outlook\CAMFilter\BlockLimit" /v CAMFILTER_BLOCK_LIMIT 2>NUL 1>NUL
IF NOT %ERRORLEVEL% == 0 REG ADD HKEY_LOCAL_MACHINE\Software\ColligoOfflineClient\Outlook\CAMFilter\BlockLimit /v CAMFILTER_BLOCK_LIMIT /t REG_DWORD /d 20000 /f
GOTO STATUS

:STATUS
IF NOT "%ERRORLEVEL%" == "0" GOTO ERROR
IF "%ERRORLEVEL%" == "0" GOTO SUCCESS

:ERROR
ECHO.
ECHO An ERROR occurred during install.
ECHO Please contact the Helpdesk on x7500
ECHO and report the following error code.
ECHO.
ECHO "Error Code: %errorlevel%"
ECHO.
TIMEOUT 15 > NULL
GOTO EOF

:SUCCESS
ECHO.
ECHO COLLIGO installation completed successfully.
ECHO.
TIMEOUT 15 > NULL
GOTO EOF

:EOF
ENDLOCAL
EXIT


