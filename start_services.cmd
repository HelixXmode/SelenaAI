@echo off

if "%1"=="full" (
    echo Starting full deployment...
) else (
    set "msg=Starting partial deployment... (backend run on host), use "full" to run all services in containers"
    echo !msg!
)

@echo off
openssl rand -hex 32 >nul 2>&1
if %ERRORLEVEL% == 0 (
    for /f %%i in ('openssl rand -hex 32') do set SEARXNG_SECRET_KEY=%%i
    goto :key_generated
)

python --version >nul 2>&1
if %ERRORLEVEL% == 0 (
    for /f %%i in ('python -c "import secrets; print(secrets.token_hex(32))"') do set SEARXNG_SECRET_KEY=%%i
    goto :key_generated
)

py --version >nul 2>&1
if %ERRORLEVEL% == 0 (
    for /f %%i in ('py -c "import secrets; print(secrets.token_hex(32))"') do set SEARXNG_SECRET_KEY=%%i
    goto :key_generated
)

echo Error: Neither openssl nor python is available to generate a secret key.
echo Please install Python from https://python.org or OpenSSL
exit /b 2

:key_generated
echo Secret key generated successfully

REM Generate secret key
for /f %%i in ('powershell -command "[System.Web.Security.Membership]::GeneratePassword(64,0)"') do set SEARXNG_SECRET_KEY=%%i

if "%1"=="full" (
    docker compose up -d backend
    timeout /t 5 /nobreak >nul
    docker compose --profile full up
) else (
    docker compose --profile core up
)