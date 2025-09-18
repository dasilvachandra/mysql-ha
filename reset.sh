#!/usr/bin/env bash
set -euo pipefail

echo "⚠️  WARNING: This will remove ALL Docker containers, images, volumes, and networks!"
echo "Press Ctrl+C to cancel or wait 5 seconds to continue..."
sleep 5

echo "🛑 Stopping all containers..."
docker stop $(docker ps -aq) 2>/dev/null || true

echo "🗑 Removing all containers..."
docker rm -f $(docker ps -aq) 2>/dev/null || true

echo "🗑 Removing all volumes..."
docker volume rm $(docker volume ls -q) 2>/dev/null || true

echo "🗑 Cleaning MySQL data at /opt/mysql/..."
rm -rf /opt/mysql/* || true

echo "🗑 Removing all custom networks..."
docker network rm $(docker network ls -q) 2>/dev/null || true

echo "🗑 Removing all images..."
docker rmi -f $(docker images -q) 2>/dev/null || true

echo "🧹 Docker system prune..."
docker system prune -af --volumes || true

echo "✅ Docker environment fully reset!"
