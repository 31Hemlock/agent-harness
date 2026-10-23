@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%~1"=="" (
    echo Usage:
    echo   ai project-name [codex^|claude^|shell^|rebuild]
    echo.
    echo Examples:
    echo   ai icaf-vite rebuild
    echo   ai icaf-vite codex
    echo   ai icaf-vite claude
    echo   ai icaf-vite shell
    exit /b 1
)

set "PROJECT_CONFIG=%SCRIPT_DIR%\projects\%~1.bat"

if not exist "%PROJECT_CONFIG%" (
    echo Missing project config: %PROJECT_CONFIG%
    exit /b 1
)

set "PROJECT="
set "WORKSPACE="
set "CONTAINER_WORKDIR="
set "IMAGE="
set "CODEX_AUTH_VOLUME="
set "CLAUDE_AUTH_VOLUME="

call "%PROJECT_CONFIG%"

set "MODE=%~2"
if "%MODE%"=="" set "MODE=shell"

if not defined PROJECT (
    echo PROJECT is not set. Check %PROJECT_CONFIG%
    exit /b 1
)

if not defined WORKSPACE (
    echo WORKSPACE is not set. Check %PROJECT_CONFIG%
    exit /b 1
)

if not defined IMAGE (
    echo IMAGE is not set. Check %PROJECT_CONFIG%
    exit /b 1
)

if not defined CODEX_AUTH_VOLUME (
    echo CODEX_AUTH_VOLUME is not set. Check %PROJECT_CONFIG%
    exit /b 1
)

if not defined CLAUDE_AUTH_VOLUME (
    echo CLAUDE_AUTH_VOLUME is not set. Check %PROJECT_CONFIG%
    exit /b 1
)

if not defined CONTAINER_WORKDIR set "CONTAINER_WORKDIR=/workspace"

if not exist "%WORKSPACE%\" (
    echo WORKSPACE path does not exist: %WORKSPACE%
    exit /b 1
)

if /I "%MODE%"=="rebuild" (
    docker build -t "%IMAGE%" -f "%SCRIPT_DIR%\Dockerfile" "%SCRIPT_DIR%"
    exit /b %ERRORLEVEL%
)

set "AI_COMMAND="
if /I "%MODE%"=="codex" set "AI_COMMAND=codex --no-alt-screen --sandbox danger-full-access --ask-for-approval never"
if /I "%MODE%"=="claude" set "AI_COMMAND=claude"
if /I "%MODE%"=="shell" set "AI_COMMAND=zsh"

if not defined AI_COMMAND (
    echo Unknown mode: %MODE%
    exit /b 1
)

set "CONTAINER_NAME=ai-%PROJECT%-%MODE%"

set "GIT_MOUNT="
if exist "%WORKSPACE%\.git\" (
    set "GIT_MOUNT=-v "%WORKSPACE%\.git:%CONTAINER_WORKDIR%/.git:ro""
)

set "NODE_MODULES_MOUNT="
if exist "%WORKSPACE%\node_modules\" (
    set "NODE_MODULES_MOUNT=-v "%WORKSPACE%\node_modules:%CONTAINER_WORKDIR%/node_modules:ro""
)

docker run -it --rm ^
    --init ^
    --name "%CONTAINER_NAME%" ^
    --cap-drop=ALL ^
    --security-opt no-new-privileges ^
    --pids-limit=256 ^
    --memory=6g ^
    --memory-swap=6g ^
    --ulimit fsize=1073741824:1073741824 ^
    -e AI_WORKSPACE_WATCHDOG=1 ^
    -e AI_WORKSPACE_MAX_FILE_BYTES=1073741824 ^
    -e AI_WORKSPACE_WATCHDOG_INTERVAL=1 ^
    -e GIT_OPTIONAL_LOCKS=0 ^
    -e PROJECT_DIR="%CONTAINER_WORKDIR%" ^
    -p 127.0.0.1:1455:1455 ^
    -v "%WORKSPACE%:%CONTAINER_WORKDIR%" ^
    %GIT_MOUNT% ^
    %NODE_MODULES_MOUNT% ^
    -v "%CODEX_AUTH_VOLUME%:/home/node/.codex" ^
    -v "%CLAUDE_AUTH_VOLUME%:/home/node/.claude" ^
    -w "%CONTAINER_WORKDIR%" ^
    "%IMAGE%" %AI_COMMAND%

exit /b %ERRORLEVEL%