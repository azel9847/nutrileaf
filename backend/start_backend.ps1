# NutriLeaf — Backend Startup Script
# Run this from the repo root OR the backend/ folder.
# PowerShell: .\backend\start_backend.ps1

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  NutriLeaf FastAPI Backend" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Starting uvicorn on http://0.0.0.0:8000 ..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Flutter connection URLs:" -ForegroundColor Yellow
Write-Host "  Web (Chrome)         -> http://localhost:8000" -ForegroundColor White
Write-Host "  Android Emulator     -> http://10.0.2.2:8000" -ForegroundColor White
Write-Host "  Physical Device      -> http://<YOUR_PC_IP>:8000" -ForegroundColor White
Write-Host ""
Write-Host "Find your PC IP with: ipconfig (look for IPv4 Address)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Docs: http://localhost:8000/docs" -ForegroundColor DarkGray
Write-Host "Health: http://localhost:8000/api/health" -ForegroundColor DarkGray
Write-Host ""

# Change to the backend directory regardless of where you run the script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

.\venv\Scripts\uvicorn.exe main:app --host 0.0.0.0 --port 8000 --reload
