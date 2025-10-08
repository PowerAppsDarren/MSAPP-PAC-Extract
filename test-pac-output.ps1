#!/usr/bin/env pwsh
# Diagnostic script to test PAC CLI output formats

# Set PAC CLI path
$pacPath = "$HOME/bin/pac/tools/pac"

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "PAC CLI OUTPUT FORMAT DIAGNOSTIC TOOL" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check PAC CLI version
Write-Host "TEST 1: PAC CLI Version" -ForegroundColor Green
Write-Host "Running: pac help | head -5" -ForegroundColor Cyan
& $pacPath help | Select-Object -First 5
Write-Host ""

# Test 2: Check authentication status
Write-Host "TEST 2: Authentication Status" -ForegroundColor Green
Write-Host "Running: pac auth list" -ForegroundColor Cyan
$authOutput = & $pacPath auth list 2>&1
Write-Host $authOutput
Write-Host ""

# Check if authenticated
$activeAuth = $authOutput | Select-String "Active"
if (-not $activeAuth) {
    Write-Host "❌ No active authentication found. Please authenticate first." -ForegroundColor Red
    Write-Host "Run the main script and select option 1 to authenticate." -ForegroundColor Yellow
    exit 1
}

# Test 3: Get current environment
Write-Host "TEST 3: Current Environment" -ForegroundColor Green
Write-Host "Running: pac env who" -ForegroundColor Cyan
$envWho = & $pacPath env who 2>&1
Write-Host $envWho
Write-Host ""

# Extract environment URL if possible
$envUrl = ""
if ($envWho -match "https://[^\s]+") {
    $envUrl = $matches[0]
    Write-Host "Detected Environment URL: $envUrl" -ForegroundColor Green
} else {
    Write-Host "Enter your environment URL (or ID):" -ForegroundColor Yellow
    $envUrl = Read-Host "Environment"
}

# Test 4: List canvas apps (default format)
Write-Host "TEST 4: Canvas Apps List (Default Format)" -ForegroundColor Green
Write-Host "Running: pac canvas list --environment $envUrl" -ForegroundColor Cyan
$canvasListDefault = & $pacPath canvas list --environment $envUrl 2>&1 | Out-String
Write-Host $canvasListDefault
Write-Host ""

# Parse and analyze the output
Write-Host "ANALYSIS OF DEFAULT OUTPUT:" -ForegroundColor Yellow
$lines = $canvasListDefault -split "`n"
$lineCount = 0
$appLines = @()

foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $lineCount++
    
    Write-Host "Line $lineCount`: [$($line.Length) chars] " -NoNewline
    
    # Check for different patterns
    if ($line -match "^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}") {
        Write-Host "✓ GUID found" -ForegroundColor Green
        $appLines += $line
    } elseif ($line -match "Canvas App Name|Environment|^-+$") {
        Write-Host "Header/Separator" -ForegroundColor Blue
    } elseif ($line -match "\d{1,2}/\d{1,2}/\d{4}") {
        Write-Host "✓ Contains date" -ForegroundColor Green
        $appLines += $line
    } elseif ($line.Length -gt 20 -and -not ($line -match "^Press Enter|^No canvas apps")) {
        Write-Host "Possible app line" -ForegroundColor Yellow
        $appLines += $line
    } else {
        Write-Host "Other" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Found $($appLines.Count) potential app lines" -ForegroundColor Cyan
Write-Host ""

# Test 5: Try JSON output
Write-Host "TEST 5: Canvas Apps List (JSON Format)" -ForegroundColor Green
Write-Host "Running: pac canvas list --environment $envUrl --output json" -ForegroundColor Cyan
$canvasListJson = & $pacPath canvas list --environment $envUrl --output json 2>&1

if ($LASTEXITCODE -eq 0) {
    try {
        $appsJson = $canvasListJson | ConvertFrom-Json
        Write-Host "✅ JSON parsing successful!" -ForegroundColor Green
        Write-Host "Found $($appsJson.Count) apps in JSON format" -ForegroundColor Cyan
        
        if ($appsJson.Count -gt 0) {
            Write-Host ""
            Write-Host "Sample JSON structure (first app):" -ForegroundColor Yellow
            $appsJson | Select-Object -First 1 | ConvertTo-Json -Depth 2
            
            Write-Host ""
            Write-Host "App Names and IDs from JSON:" -ForegroundColor Yellow
            foreach ($app in $appsJson | Select-Object -First 5) {
                Write-Host "  Name/ID: $($app.Name)" -ForegroundColor Cyan
                Write-Host "  Display: $($app.DisplayName)" -ForegroundColor White
                if ($app.Owner) {
                    Write-Host "  Owner: $($app.Owner)" -ForegroundColor Gray
                }
                Write-Host ""
            }
        }
    } catch {
        Write-Host "❌ JSON parsing failed: $_" -ForegroundColor Red
        Write-Host "Raw output:" -ForegroundColor Yellow
        Write-Host $canvasListJson
    }
} else {
    Write-Host "❌ JSON output command failed" -ForegroundColor Red
    Write-Host $canvasListJson
}

Write-Host ""
Write-Host "TEST 6: Try Table Format" -ForegroundColor Green
Write-Host "Running: pac canvas list --environment $envUrl --output table" -ForegroundColor Cyan
$canvasListTable = & $pacPath canvas list --environment $envUrl --output table 2>&1 | Out-String
Write-Host $canvasListTable

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "DIAGNOSTIC COMPLETE" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Green
Write-Host "- Default format: $($appLines.Count) potential app lines found" -ForegroundColor White
if ($appsJson) {
    Write-Host "- JSON format: $($appsJson.Count) apps found" -ForegroundColor White
}
Write-Host ""
Write-Host "If you see apps listed but the main script can't find them," -ForegroundColor Yellow
Write-Host "please share the output above to help fix the parsing logic." -ForegroundColor Yellow