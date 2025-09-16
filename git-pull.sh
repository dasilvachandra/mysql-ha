#!/bin/bash
# Script otomatis git pull dengan timestamp log

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "🔄 [$TIMESTAMP] Menarik update terbaru dari remote..."
git pull origin main