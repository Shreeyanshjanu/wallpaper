#!/bin/bash

set -e  # Exit on error

echo "🚀 Starting Flutter Web Build..."

# Install Flutter
echo "📦 Installing Flutter..."
if [ ! -d "flutter" ]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Disable analytics
flutter config --no-analytics

# Check Flutter installation
echo "🔍 Checking Flutter installation..."
flutter --version

# Enable web support
flutter config --enable-web

# Navigate to frontend directory
cd frontend

# Get dependencies
echo "📥 Getting Flutter dependencies..."
flutter pub get

# Build web app
echo "🔨 Building Flutter web app..."
flutter build web --release

echo "✅ Build complete!"
