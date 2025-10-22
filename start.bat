@echo off
echo ?? Starting Photo Album Java Application with Oracle DB
echo ==================================================

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ? Docker is not running. Please start Docker Desktop and try again.
    pause
    exit /b 1
)

echo ? Docker is running

REM Check if docker-compose is available
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ? docker-compose not found. Please install Docker Compose.
    pause
    exit /b 1
)

echo ? Docker Compose is available

REM Create uploads directory if it doesn't exist
if not exist "uploads" mkdir uploads
echo ?? Created uploads directory

REM Start the services
echo ?? Starting services with Docker Compose...
echo    - Oracle Database 21c XE (this may take 2-3 minutes on first run)
echo    - Photo Album Java Application
echo.

docker-compose up --build

echo.
echo ?? Services stopped. To clean up completely, run:
echo    docker-compose down -v
pause