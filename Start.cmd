@echo off
setlocal
set "APP=%~dp0app\TurboOldPC.ps1"
if not exist "%APP%" (
  echo Application file is missing: "%APP%"
  pause
  exit /b 1
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%APP%"
if errorlevel 1 (
  echo.
  echo Application could not start. See README.md and check PowerShell errors above.
  pause
)
endlocal
