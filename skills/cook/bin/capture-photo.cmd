@echo off
setlocal

rem Capture a photo from an IP Webcam Android app
rem Usage: capture-photo.cmd <camera_url> <output_path> [label]
rem
rem Called by the panout-capture-photo skill, which handles URL discovery
rem and caching in the session state file.
rem
rem Exit codes:
rem   0 - success, photo saved
rem   1 - missing arguments
rem   3 - camera unreachable
rem   4 - capture failed

set "CAMERA_URL=%~1"
set "OUTPUT_PATH=%~2"
set "LABEL=%~3"
if "%LABEL%"=="" set "LABEL=photo"

if "%CAMERA_URL%"=="" goto usage
if "%OUTPUT_PATH%"=="" goto usage
goto main

:usage
echo Usage: capture-photo.cmd ^<camera_url^> ^<output_path^> [label]
exit /b 1

:main
rem Strip trailing slash
if "%CAMERA_URL:~-1%"=="/" set "CAMERA_URL=%CAMERA_URL:~0,-1%"

rem Check if camera is reachable (1 second timeout)
curl -s --connect-timeout 1 --max-time 2 "%CAMERA_URL%/status.json" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Camera not reachable at %CAMERA_URL%
    echo Is IP Webcam running on the phone?
    exit /b 3
)

rem Ensure output directory exists
for %%F in ("%OUTPUT_PATH%") do mkdir "%%~dpF" 2>nul

rem Capture with autofocus (photoaf.jpg triggers AF then captures)
curl -s --max-time 10 -o "%OUTPUT_PATH%" "%CAMERA_URL%/photoaf.jpg"
if errorlevel 1 (
    echo ERROR: Capture failed
    del /f /q "%OUTPUT_PATH%" 2>nul
    exit /b 4
)

rem Verify output file exists and is non-empty
if not exist "%OUTPUT_PATH%" (
    echo ERROR: Capture failed - output file missing
    exit /b 4
)
for %%F in ("%OUTPUT_PATH%") do set FILE_SIZE=%%~zF
if "%FILE_SIZE%"=="0" (
    echo ERROR: Capture failed - output file is empty
    del /f /q "%OUTPUT_PATH%"
    exit /b 4
)

echo Captured: %OUTPUT_PATH% (%FILE_SIZE% bytes) -- %LABEL%
exit /b 0
