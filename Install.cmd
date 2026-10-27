@echo off
setlocal
set "INSTALLER=%~dp0install\Install.ps1"
if not exist "%INSTALLER%" (
  echo Installer not found: "%INSTALLER%"
  pause
  exit /b 1
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER%"
if errorlevel 1 (
  echo Install failed. Check the details above.
  pause
  exit /b 1
)
echo Installation completed.
pause
endlocal
