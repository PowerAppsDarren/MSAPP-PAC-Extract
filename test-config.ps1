#!/usr/bin/env pwsh
# Test configuration saving and loading

$configPath = Join-Path $PSScriptRoot "msapp-downloader-config.json"

Write-Host "Configuration Test" -ForegroundColor Yellow
Write-Host "=================" -ForegroundColor Yellow
Write-Host ""

# Check if config exists
if (Test-Path $configPath) {
    Write-Host "✅ Config file exists at: $configPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Current contents:" -ForegroundColor Cyan
    Get-Content $configPath | Write-Host
} else {
    Write-Host "❌ Config file NOT found at: $configPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Creating test config..." -ForegroundColor Yellow
    
    $testConfig = @{
        LastEnvironment = "https://test.crm.dynamics.com"
        LastAuthProfile = "TestProfile"
        DownloadDirectory = "./downloads"
        ConfigVersion = "1.0"
        CreatedDate = (Get-Date).ToString()
    }
    
    $testConfig | ConvertTo-Json -Depth 3 | Set-Content $configPath
    
    if (Test-Path $configPath) {
        Write-Host "✅ Config file created successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Contents:" -ForegroundColor Cyan
        Get-Content $configPath | Write-Host
    } else {
        Write-Host "❌ Failed to create config file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "File permissions:" -ForegroundColor Yellow
ls -la $configPath 2>&1 | Write-Host