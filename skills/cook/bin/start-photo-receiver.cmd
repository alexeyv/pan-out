@echo off
setlocal

rem Start the background photo receiver for push-mode photo capture.
rem Usage: start-photo-receiver.cmd <inbox_dir> [port]

set "INBOX_DIR=%~1"
set "PORT=%~2"
if "%PORT%"=="" set "PORT=8765"

if "%INBOX_DIR%"=="" (
    echo Usage: start-photo-receiver.cmd ^<inbox_dir^> [port]
    exit /b 1
)

rem Get local WiFi IP
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /i "IPv4" ^| findstr /v "169.254"') do (
    set "LOCAL_IP=%%A"
    goto :got_ip
)
:got_ip
rem Strip leading space
set "LOCAL_IP=%LOCAL_IP: =%"

rem Start receiver in background
set "SCRIPT_DIR=%~dp0"
start /b python "%SCRIPT_DIR%photo-receiver.py" "%INBOX_DIR%" "%PORT%"

rem Give it a moment to start
timeout /t 1 /nobreak >nul

echo Photo receiver started
echo POST endpoint: http://%LOCAL_IP%:%PORT%/photo
echo Inbox: %INBOX_DIR%
