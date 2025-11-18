#!/bin/bash
# Post-Fix Installation Script
# Run this after pulling the fixes

echo "🔧 Installing updated dependencies..."

cd backend

# Install new dependencies
npm install

echo ""
echo "✅ Dependencies installed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Copy .env.example to .env:  cp .env.example .env"
echo "2. Edit .env and set required variables (JWT_SECRET, etc.)"
echo "3. Start backend:  npm start"
echo ""
echo "🐳 Or use Docker:  docker-compose up -d"
echo ""
echo "📚 Read QUICK_START.md for detailed instructions"
