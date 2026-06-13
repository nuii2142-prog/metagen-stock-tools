@echo off
chcp 65001 >nul
setlocal

set "THIS=%~dp0"
if "%THIS:~-1%"=="\" set "THIS=%THIS:~0,-1%"
rem -- Defaults (edit if needed) ---------------------------------
set "AI_MODE=ai"
set "AI_MODEL=Adobe Firefly"
rem -- Where is dreamstime-embed.ps1? -----------------------------
rem 1) Same folder as this file (default - keep them together)
rem 2) Edit INSTALL_DIR below if you move the .ps1 elsewhere
set "INSTALL_DIR=%USERPROFILE%\Documents\Fable Metagen\dreamstime-tool"
set "SCRIPT=%THIS%\dreamstime-embed.ps1"
if not exist "%SCRIPT%" set "SCRIPT=%INSTALL_DIR%\dreamstime-embed.ps1"
if not exist "%SCRIPT%" (
  echo.
  echo Could not find dreamstime-embed.ps1.
  echo Put this .bat in the same folder as dreamstime-embed.ps1,
  echo or edit the INSTALL_DIR line inside this .bat.
  echo.
  pause
  exit /b 1
)
set "CSV="

if not "%~1"=="" set "CSV=%~1"

if "%CSV%"=="" (
  for /f "delims=" %%F in ('dir /b /a-d /o-d "%THIS%\MetaGen_Dreamstime_*.csv" 2^>nul') do (
    set "CSV=%THIS%\%%F"
    goto FOUND_CSV
  )
)

:FOUND_CSV
if "%CSV%"=="" (
  echo.
  echo Could not find MetaGen_Dreamstime_*.csv in this folder.
  echo Put the Dreamstime CSV in the same folder as this file, then double-click again.
  echo.
  pause
  exit /b 1
)

for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmmss"') do set "STAMP=%%T"
set "OUT=%THIS%\Dreamstime Ready %STAMP%"

echo.
echo Dreamstime Metadata Embed
echo =========================
echo CSV:    %CSV%
echo Images: %THIS%
echo Output: %OUT%
echo.
echo This will NOT edit your original images.
echo It will create/copy files into a NEW Dreamstime Ready folder every time.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Csv "%CSV%" -ImagesDir "%THIS%" -OutDir "%OUT%" -AiMode "%AI_MODE%" -AiModel "%AI_MODEL%"

echo.
if errorlevel 1 (
  echo Something went wrong. Please send Codex a screenshot of this window.
) else (
  echo Done. Upload images from this new folder:
  echo %OUT%
)
echo.
pause
