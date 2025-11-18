# Post-Fix Installation Script (Windows)
# Run this after pulling the fixes

Write-Host "🔧 Installing updated dependencies..." -ForegroundColor Cyan

Set-Location backend

# Install new dependencies
npm install

Write-Host ""
Write-Host "✅ Dependencies installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "1. Copy .env.example to .env:  Copy-Item .env.example .env"
Write-Host "2. Edit .env and set required variables (JWT_SECRET, etc.)"
Write-Host "3. Start backend:  npm start"
Write-Host ""
Write-Host "🐳 Or use Docker:  docker-compose up -d" -ForegroundColor Cyan
Write-Host ""
Write-Host "📚 Read QUICK_START.md for detailed instructions" -ForegroundColor Blue
