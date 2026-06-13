@echo off
chcp 65001 >nul
setlocal

set "THIS=%~dp0"
if "%THIS:~-1%"=="\" set "THIS=%THIS:~0,-1%"
set "SCRIPT=C:\Users\Darks\Documents\GPT META gen\dreamstime-embed.ps1"
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

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Csv "%CSV%" -ImagesDir "%THIS%" -OutDir "%OUT%" -AiMode "ai" -AiModel "Adobe Firefly"

echo.
if errorlevel 1 (
  echo Something went wrong. Please send Codex a screenshot of this window.
) else (
  echo Done. Upload images from this new folder:
  echo %OUT%
)
echo.
pause
