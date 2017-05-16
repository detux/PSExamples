@ECHO OFF

CLS
ECHO.
ECHO Fix <anti-virus> Server Location...
ECHO.

SETLOCAL
SET log=%~dp0
SET source=%~dp0IpXfer
SET "target_1=C:\Program Files\Siemens\Customer\tools"
SET "target_2=C:\Program Files\Siemens\Customer\Virusprotection"
SET "command=IpXfer_x64.exe -S <server name> -P 85 -C 53972 -m 1 -e \\<server path>\ofcscan\pccnt\common\OfcNTCer.dat"

REM Copy the fixer file to the directory location using robocopy.
Robocopy.exe "%source%" "%target_1%" "IpXfer_x64.exe" /LOG+:"%log%\TrendMicroFix.log"
Robocopy.exe "%source%" "%target_2%" "IpXfer_x64.exe" /LOG+:"%log%\TrendMicroFix.log"

CD /d "%target_2%"
START "Fixing <anti-virus> Server Location...PLEASE DO NOT CLOSE THIS WINDOW" %command%
