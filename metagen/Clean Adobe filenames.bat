@echo off
setlocal
title Clean Adobe filenames

rem --- the python script must sit next to this .bat (ASCII-only file; Python prints Thai) ---
set "SCRIPT=%~dp0clean_adobe_filenames.py"

rem --- pick a working Python launcher (py first, then python) ---
py -3 --version >nul 2>nul
if %errorlevel%==0 (set "PY=py -3") else (set "PY=python")

rem --- target folder: dragged onto this file, or typed in ---
if "%~1"=="" (
  echo.
  echo   Drag an image folder ^(the one with the CSV^) onto this file,
  echo   or type its full path below and press Enter.
  echo.
  set /p "TARGET=Folder path: "
) else (
  set "TARGET=%~1"
)

echo.
%PY% "%SCRIPT%" "%TARGET%" --interactive

echo.
pause
endlocal
