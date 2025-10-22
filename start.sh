#!/bin/bash
set -e

echo "?? Starting Photo Album Java Application with Oracle DB"
echo "=================================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "? Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

echo "? Docker is running"

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "? docker-compose not found. Please install Docker Compose."
    exit 1
fi

echo "? Docker Compose is available"

# Create uploads directory if it doesn't exist
mkdir -p uploads

echo "?? Created uploads directory"

# Start the services
echo "?? Starting services with Docker Compose..."
echo "   - Oracle Database 21c XE (this may take 2-3 minutes on first run)"
echo "   - Photo Album Java Application"
echo ""

docker-compose up --build

echo ""
echo "?? Services stopped. To clean up completely, run:"
echo "   docker-compose down -v"