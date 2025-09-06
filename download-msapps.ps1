#!/usr/bin/env pwsh
# Interactive Power Platform MSAPP Downloader
# This script provides an interactive menu system to connect to Power Platform and download canvas apps

# Set PAC CLI path
$pacPath = "$HOME/bin/pac/tools/pac"

# Colors for better visibility
$Host.UI.RawUI.BackgroundColor = 'Black'
$Host.UI.RawUI.ForegroundColor = 'White'

function Write-ColorOutput($ForegroundColor, $Text) {
    $fc = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Host $Text
    $Host.UI.RawUI.ForegroundColor = $fc
}

function Show-MainMenu {
    Clear-Host
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-ColorOutput Yellow "     🚀 POWER PLATFORM MSAPP DOWNLOADER"
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-Host ""
    Write-ColorOutput Green "MAIN MENU:"
    Write-Host "  1. 🔐 Manage Authentication"
    Write-Host "  2. 🌍 Select Environment"
    Write-Host "  3. 📱 Download Canvas Apps"
    Write-Host "  4. 📦 Batch Download All Apps"
    Write-Host "  5. 📁 Configure Download Directory"
    Write-Host "  6. ℹ️  Show Current Settings"
    Write-Host "  7. 🔄 Refresh Environment List"
    Write-Host "  8. ❌ Exit"
    Write-Host ""
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
}

function Show-AuthMenu {
    Clear-Host
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-ColorOutput Yellow "     🔐 AUTHENTICATION MANAGEMENT"
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-Host ""
    
    # Show current auth profiles
    Write-ColorOutput Green "Current Authentication Profiles:"
    Write-Host ""
    & $pacPath auth list
    Write-Host ""
    
    Write-ColorOutput Green "OPTIONS:"
    Write-Host "  1. ➕ Create New Authentication"
    Write-Host "  2. 🔄 Switch Active Profile"
    Write-Host "  3. 🗑️  Delete Authentication Profile"
    Write-Host "  4. 🔙 Back to Main Menu"
    Write-Host ""
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
}

function Create-NewAuth {
    Clear-Host
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-ColorOutput Yellow "     ➕ CREATE NEW AUTHENTICATION"
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-Host ""
    
    Write-ColorOutput Green "Select Authentication Type:"
    Write-Host "  1. 🌐 Interactive (Browser-based)"
    Write-Host "  2. 🔑 Service Principal"
    Write-Host "  3. 🔙 Cancel"
    Write-Host ""
    
    $authChoice = Read-Host "Enter your choice (1-3)"
    
    switch ($authChoice) {
        "1" {
            Write-Host ""
            Write-ColorOutput Yellow "Enter your Power Platform environment URL"
            Write-Host "Example: https://org12345.crm.dynamics.com"
            $envUrl = Read-Host "Environment URL"
            
            Write-Host ""
            Write-ColorOutput Yellow "Enter a name for this profile (optional)"
            $profileName = Read-Host "Profile Name (press Enter to skip)"
            
            Write-Host ""
            Write-ColorOutput Cyan "Opening browser for authentication..."
            
            if ([string]::IsNullOrWhiteSpace($profileName)) {
                & $pacPath auth create --environment $envUrl
            } else {
                & $pacPath auth create --environment $envUrl --name $profileName
            }
            
            Write-Host ""
            Write-ColorOutput Green "✅ Authentication created successfully!"
            Read-Host "Press Enter to continue"
        }
        "2" {
            Write-Host ""
            Write-ColorOutput Yellow "Service Principal Authentication Setup"
            $tenantId = Read-Host "Tenant ID"
            $appId = Read-Host "Application (Client) ID"
            $clientSecret = Read-Host "Client Secret" -AsSecureString
            $envUrl = Read-Host "Environment URL"
            
            $secret = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret)
            )
            
            & $pacPath auth create --tenant $tenantId --applicationId $appId --clientSecret $secret --environment $envUrl
            
            Write-Host ""
            Write-ColorOutput Green "✅ Service Principal authentication created!"
            Read-Host "Press Enter to continue"
        }
        "3" {
            return
        }
    }
}

function Select-Environment {
    Clear-Host
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-ColorOutput Yellow "     🌍 SELECT ENVIRONMENT"
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-Host ""
    
    Write-ColorOutput Green "Fetching available environments..."
    Write-Host ""
    
    # Get environments list
    $envOutput = & $pacPath env list 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput Red "❌ Error: Unable to fetch environments. Please check authentication."
        Write-Host $envOutput
        Read-Host "Press Enter to continue"
        return $null
    }
    
    Write-Host $envOutput
    Write-Host ""
    
    Write-ColorOutput Yellow "Enter the Environment ID or URL from the list above:"
    $selectedEnv = Read-Host "Environment"
    
    # Select the environment
    & $pacPath env select --environment $selectedEnv
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✅ Environment selected successfully!"
        $script:currentEnvironment = $selectedEnv
    } else {
        Write-ColorOutput Red "❌ Failed to select environment"
    }
    
    Read-Host "Press Enter to continue"
    return $selectedEnv
}

function Download-CanvasApps {
    Clear-Host
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-ColorOutput Yellow "     📱 DOWNLOAD CANVAS APPS"
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-Host ""
    
    if ([string]::IsNullOrWhiteSpace($script:currentEnvironment)) {
        Write-ColorOutput Red "❌ No environment selected. Please select an environment first."
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-ColorOutput Green "Fetching canvas apps list..."
    Write-Host ""
    
    # Get canvas apps list with detailed output
    Write-Host "Running: pac canvas list --environment $script:currentEnvironment"
    $appsOutput = & $pacPath canvas list --environment $script:currentEnvironment 2>&1 | Out-String
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput Red "❌ Error: Unable to fetch apps list"
        Write-Host $appsOutput
        Read-Host "Press Enter to continue"
        return
    }
    
    # Display the raw output for debugging
    Write-Host $appsOutput
    
    # Parse the output to extract app information
    # Try multiple parsing strategies
    $lines = $appsOutput -split "`n"
    $apps = @()
    $headerFound = $false
    
    foreach ($line in $lines) {
        # Skip empty lines and headers
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -match "Canvas App Name|Environment|^-+$") { 
            $headerFound = $true
            continue 
        }
        
        # Strategy 1: Look for GUID pattern (original)
        if ($line -match "([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})\s+(.+)") {
            $apps += @{
                Id = $matches[1].Trim()
                Name = $matches[2].Trim()
            }
            continue
        }
        
        # Strategy 2: Parse name-owner-date format (from screenshot)
        # If line contains text and ends with a date pattern
        if ($headerFound -and $line -match "^(.+?)\s{2,}(.+?)\s+(\d{1,2}/\d{1,2}/\d{4})\s*$") {
            $appName = $matches[1].Trim()
            $owner = $matches[2].Trim()
            $date = $matches[3].Trim()
            
            # Generate a temporary ID based on app name (will need to fetch real ID)
            $tempId = "temp_" + ($appName -replace '[^a-zA-Z0-9]', '_')
            
            $apps += @{
                Id = $tempId
                Name = $appName
                Owner = $owner
                Date = $date
            }
            continue
        }
        
        # Strategy 3: If it looks like an app name line (simple heuristic)
        if ($headerFound -and $line.Length -gt 10 -and -not ($line -match "^Press Enter|^No canvas apps")) {
            # Try to extract just the app name if we can't parse the full format
            $possibleName = $line -split '\s{2,}' | Select-Object -First 1
            if ($possibleName -and $possibleName.Trim().Length -gt 0) {
                $apps += @{
                    Id = "unknown_" + ($apps.Count + 1)
                    Name = $possibleName.Trim()
                }
            }
        }
    }
    
    if ($apps.Count -eq 0) {
        Write-ColorOutput Yellow "No canvas apps found in this environment."
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-Host ""
    Write-ColorOutput Green "Found $($apps.Count) canvas app(s)"
    Write-Host ""
    Write-ColorOutput Yellow "OPTIONS:"
    Write-Host "  1. 📥 Download specific app (enter App ID)"
    Write-Host "  2. 📦 Download all apps"
    Write-Host "  3. 🔙 Back to Main Menu"
    Write-Host ""
    
    $downloadChoice = Read-Host "Enter your choice (1-3)"
    
    switch ($downloadChoice) {
        "1" {
            # List apps with numbers for selection
            Write-Host ""
            Write-ColorOutput Yellow "Select an app by number:"
            for ($i = 0; $i -lt $apps.Count; $i++) {
                Write-Host "  $($i + 1). $($apps[$i].Name)"
                if ($apps[$i].Owner) {
                    Write-Host "      Owner: $($apps[$i].Owner)"
                }
            }
            Write-Host ""
            $selection = Read-Host "Enter app number (1-$($apps.Count))"
            
            if ($selection -match '^\d+$') {
                $index = [int]$selection - 1
                if ($index -ge 0 -and $index -lt $apps.Count) {
                    $selectedApp = $apps[$index]
                    
                    # If we have a temp ID, we need to get the real ID
                    if ($selectedApp.Id -like "temp_*" -or $selectedApp.Id -like "unknown_*") {
                        Write-ColorOutput Yellow "Fetching actual App ID for: $($selectedApp.Name)"
                        # Try to get the app ID using the app name
                        Download-SingleAppByName -AppName $selectedApp.Name
                    } else {
                        Download-SingleApp -AppId $selectedApp.Id -AppName $selectedApp.Name
                    }
                } else {
                    Write-ColorOutput Red "❌ Invalid selection"
                    Read-Host "Press Enter to continue"
                }
            } else {
                Write-ColorOutput Red "❌ Please enter a number"
                Read-Host "Press Enter to continue"
            }
        }
        "2" {
            Download-AllApps -Apps $apps
        }
        "3" {
            return
        }
    }
}

function Download-SingleApp {
    param(
        [string]$AppId,
        [string]$AppName
    )
    
    # Sanitize app name for filename
    $safeAppName = $AppName -replace '[^\w\-\.]', '_'
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $fileName = "${safeAppName}_${timestamp}.msapp"
    $filePath = Join-Path $script:downloadDirectory $fileName
    
    Write-Host ""
    Write-ColorOutput Cyan "Downloading: $AppName"
    Write-Host "App ID: $AppId"
    Write-Host "Saving to: $filePath"
    Write-Host ""
    
    & $pacPath canvas download --environment $script:currentEnvironment --app $AppId --path $filePath
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✅ Successfully downloaded: $fileName"
        
        # Ask if user wants to extract it
        Write-Host ""
        $extract = Read-Host "Do you want to extract this app now? (Y/N)"
        if ($extract -eq 'Y' -or $extract -eq 'y') {
            Extract-MsApp -MsAppPath $filePath -AppName $safeAppName
        }
    } else {
        Write-ColorOutput Red "❌ Failed to download app"
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Download-SingleAppByName {
    param(
        [string]$AppName
    )
    
    Write-ColorOutput Yellow "⚠️  Note: Downloading by name requires matching the exact app name."
    Write-ColorOutput Cyan "Attempting to download: $AppName"
    
    # Sanitize app name for filename
    $safeAppName = $AppName -replace '[^\w\-\.]', '_'
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $fileName = "${safeAppName}_${timestamp}.msapp"
    $filePath = Join-Path $script:downloadDirectory $fileName
    
    Write-Host ""
    Write-Host "Saving to: $filePath"
    Write-Host ""
    
    # Try to download using app name (this might need adjustment based on PAC CLI capabilities)
    # First, try to get the app list with verbose output to find the ID
    $detailedList = & $pacPath canvas list --environment $script:currentEnvironment --output json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        try {
            $appsJson = $detailedList | ConvertFrom-Json
            $matchingApp = $appsJson | Where-Object { $_.Name -eq $AppName -or $_.DisplayName -eq $AppName }
            
            if ($matchingApp) {
                Write-ColorOutput Green "Found app ID: $($matchingApp.Name)"
                Download-SingleApp -AppId $matchingApp.Name -AppName $AppName
                return
            }
        } catch {
            Write-ColorOutput Yellow "Could not parse JSON output, trying alternative method..."
        }
    }
    
    # Fallback: try downloading with the app name directly (some versions of PAC support this)
    & $pacPath canvas download --environment $script:currentEnvironment --app "$AppName" --path $filePath 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✅ Successfully downloaded: $fileName"
        
        # Ask if user wants to extract it
        Write-Host ""
        $extract = Read-Host "Do you want to extract this app now? (Y/N)"
        if ($extract -eq 'Y' -or $extract -eq 'y') {
            Extract-MsApp -MsAppPath $filePath -AppName $safeAppName
        }
    } else {
        Write-ColorOutput Red "❌ Could not download app by name. You may need to use the App ID instead."
        Write-ColorOutput Yellow "Try running 'pac canvas list --environment $script:currentEnvironment' manually to get the App ID."
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Download-AllApps {
    param(
        [array]$Apps
    )
    
    Write-Host ""
    Write-ColorOutput Yellow "This will download all $($Apps.Count) apps."
    
    # Show the apps that will be downloaded
    Write-Host ""
    Write-ColorOutput Green "Apps to download:"
    foreach ($app in $Apps) {
        Write-Host "  - $($app.Name)"
        if ($app.Owner) {
            Write-Host "    Owner: $($app.Owner)"
        }
    }
    
    Write-Host ""
    $confirm = Read-Host "Are you sure? (Y/N)"
    
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        return
    }
    
    # First, try to get all app IDs if we don't have them
    $needsIdLookup = $Apps | Where-Object { $_.Id -like "temp_*" -or $_.Id -like "unknown_*" -or $_.Id -like "app_*" }
    
    if ($needsIdLookup.Count -gt 0) {
        Write-ColorOutput Yellow "Fetching actual App IDs..."
        
        # Try to get detailed list with JSON output
        $detailedList = & $pacPath canvas list --environment $script:currentEnvironment --output json 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            try {
                $appsJson = $detailedList | ConvertFrom-Json
                
                # Update app IDs where possible
                foreach ($app in $Apps) {
                    if ($app.Id -like "temp_*" -or $app.Id -like "unknown_*" -or $app.Id -like "app_*") {
                        $matchingApp = $appsJson | Where-Object { $_.DisplayName -eq $app.Name -or $_.Name -eq $app.Name }
                        if ($matchingApp) {
                            $app.Id = $matchingApp.Name  # The 'Name' field in JSON is actually the ID
                            Write-ColorOutput Green "Found ID for $($app.Name): $($app.Id)"
                        }
                    }
                }
            } catch {
                Write-ColorOutput Yellow "Could not parse JSON output. Will try to download by name..."
            }
        }
    }
    
    $successCount = 0
    $failCount = 0
    
    foreach ($app in $Apps) {
        $safeAppName = $app.Name -replace '[^\w\-\.]', '_'
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $fileName = "${safeAppName}_${timestamp}.msapp"
        $filePath = Join-Path $script:downloadDirectory $fileName
        
        Write-Host ""
        Write-ColorOutput Cyan "Downloading ($($Apps.IndexOf($app) + 1)/$($Apps.Count)): $($app.Name)"
        
        # If we still don't have a real ID, try downloading by name
        if ($app.Id -like "temp_*" -or $app.Id -like "unknown_*" -or $app.Id -like "app_*") {
            Write-ColorOutput Yellow "Attempting to download by name..."
            & $pacPath canvas download --environment $script:currentEnvironment --app "$($app.Name)" --path $filePath 2>&1
        } else {
            & $pacPath canvas download --environment $script:currentEnvironment --app $app.Id --path $filePath
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput Green "✅ Downloaded: $fileName"
            $successCount++
        } else {
            Write-ColorOutput Red "❌ Failed: $($app.Name)"
            $failCount++
        }
        
        # Small delay to avoid rate limiting
        Start-Sleep -Seconds 1
    }
    
    Write-Host ""
    Write-ColorOutput Green "════════════════════════════════════════════════════════════════"
    Write-ColorOutput Yellow "Download Summary:"
    Write-ColorOutput Green "✅ Successful: $successCount"
    Write-ColorOutput Red "❌ Failed: $failCount"
    Write-ColorOutput Green "════════════════════════════════════════════════════════════════"
    
    Write-Host ""
    $extractAll = Read-Host "Do you want to extract all downloaded apps? (Y/N)"
    if ($extractAll -eq 'Y' -or $extractAll -eq 'y') {
        Extract-AllMsApps
    }
    
    Read-Host "Press Enter to continue"
}

function Extract-MsApp {
    param(
        [string]$MsAppPath,
        [string]$AppName
    )
    
    $extractPath = Join-Path $script:downloadDirectory "extracted_$AppName"
    
    Write-Host ""
    Write-ColorOutput Cyan "Extracting to: $extractPath"
    
    & $pacPath canvas unpack --msapp $MsAppPath --sources $extractPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✅ Successfully extracted!"
    } else {
        Write-ColorOutput Red "❌ Extraction failed"
    }
}

function Extract-AllMsApps {
    $msappFiles = Get-ChildItem -Path $script:downloadDirectory -Filter "*.msapp"
    
    foreach ($file in $msappFiles) {
        $appName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $extractPath = Join-Path $script:downloadDirectory "extracted_$appName"
        
        if (Test-Path $extractPath) {
            Write-ColorOutput Yellow "⚠️  Skipping $appName (already extracted)"
            continue
        }
        
        Write-Host ""
        Write-ColorOutput Cyan "Extracting: $($file.Name)"
        
        & $pacPath canvas unpack --msapp $file.FullName --sources $extractPath
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput Green "✅ Extracted to: extracted_$appName"
        } else {
            Write-ColorOutput Red "❌ Failed to extract: $($file.Name)"
        }
    }
}

function Configure-DownloadDirectory {
    Clear-Host
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-ColorOutput Yellow "     📁 CONFIGURE DOWNLOAD DIRECTORY"
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-Host ""
    
    Write-ColorOutput Green "Current download directory:"
    Write-Host "  $script:downloadDirectory"
    Write-Host ""
    
    Write-ColorOutput Yellow "Enter new download directory path (or press Enter to keep current):"
    $newPath = Read-Host "Path"
    
    if (![string]::IsNullOrWhiteSpace($newPath)) {
        if (!(Test-Path $newPath)) {
            Write-Host ""
            $create = Read-Host "Directory doesn't exist. Create it? (Y/N)"
            if ($create -eq 'Y' -or $create -eq 'y') {
                New-Item -ItemType Directory -Path $newPath -Force | Out-Null
                $script:downloadDirectory = $newPath
                Write-ColorOutput Green "✅ Directory created and set!"
            }
        } else {
            $script:downloadDirectory = $newPath
            Write-ColorOutput Green "✅ Download directory updated!"
        }
    }
    
    Read-Host "Press Enter to continue"
}

function Show-CurrentSettings {
    Clear-Host
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-ColorOutput Yellow "     ℹ️  CURRENT SETTINGS"
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-Host ""
    
    Write-ColorOutput Green "PAC CLI Location:"
    Write-Host "  $pacPath"
    Write-Host ""
    
    Write-ColorOutput Green "Download Directory:"
    Write-Host "  $script:downloadDirectory"
    Write-Host ""
    
    Write-ColorOutput Green "Current Environment:"
    if ([string]::IsNullOrWhiteSpace($script:currentEnvironment)) {
        Write-Host "  (None selected)"
    } else {
        Write-Host "  $script:currentEnvironment"
    }
    Write-Host ""
    
    Write-ColorOutput Green "Active Authentication Profile:"
    & $pacPath auth list | Select-String "Active"
    Write-Host ""
    
    Write-ColorOutput Green "Downloaded Apps in Current Directory:"
    $msappCount = (Get-ChildItem -Path $script:downloadDirectory -Filter "*.msapp" -ErrorAction SilentlyContinue).Count
    $extractedCount = (Get-ChildItem -Path $script:downloadDirectory -Directory -Filter "extracted_*" -ErrorAction SilentlyContinue).Count
    Write-Host "  MSAPP files: $msappCount"
    Write-Host "  Extracted apps: $extractedCount"
    Write-Host ""
    
    Read-Host "Press Enter to continue"
}

# Initialize variables
$script:currentEnvironment = ""
$script:downloadDirectory = Join-Path (Get-Location) "downloads"

# Create download directory if it doesn't exist
if (!(Test-Path $script:downloadDirectory)) {
    New-Item -ItemType Directory -Path $script:downloadDirectory -Force | Out-Null
}

# Main program loop
while ($true) {
    Show-MainMenu
    $choice = Read-Host "Enter your choice (1-8)"
    
    switch ($choice) {
        "1" {
            while ($true) {
                Show-AuthMenu
                $authChoice = Read-Host "Enter your choice (1-4)"
                
                switch ($authChoice) {
                    "1" { Create-NewAuth }
                    "2" {
                        Write-Host ""
                        Write-ColorOutput Yellow "Enter the name of the profile to activate:"
                        $profileName = Read-Host "Profile Name"
                        & $pacPath auth select --name $profileName
                        if ($LASTEXITCODE -eq 0) {
                            Write-ColorOutput Green "✅ Profile activated!"
                        } else {
                            Write-ColorOutput Red "❌ Failed to activate profile"
                        }
                        Read-Host "Press Enter to continue"
                    }
                    "3" {
                        Write-Host ""
                        Write-ColorOutput Yellow "Enter the name of the profile to delete:"
                        $profileName = Read-Host "Profile Name"
                        & $pacPath auth delete --name $profileName
                        if ($LASTEXITCODE -eq 0) {
                            Write-ColorOutput Green "✅ Profile deleted!"
                        } else {
                            Write-ColorOutput Red "❌ Failed to delete profile"
                        }
                        Read-Host "Press Enter to continue"
                    }
                    "4" { break }
                }
                
                if ($authChoice -eq "4") { break }
            }
        }
        "2" { Select-Environment }
        "3" { Download-CanvasApps }
        "4" {
            Clear-Host
            Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
            Write-ColorOutput Yellow "     📦 BATCH DOWNLOAD ALL APPS"
            Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
            Write-Host ""
            
            if ([string]::IsNullOrWhiteSpace($script:currentEnvironment)) {
                Write-ColorOutput Red "❌ No environment selected. Please select an environment first."
                Read-Host "Press Enter to continue"
                continue
            }
            
            # Get all apps
            Write-ColorOutput Green "Fetching all canvas apps..."
            $appsOutput = & $pacPath canvas list 2>&1 | Out-String
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput Red "❌ Error: Unable to fetch apps"
                Read-Host "Press Enter to continue"
                continue
            }
            
            # Parse apps with improved logic
            $lines = $appsOutput -split "`n"
            $apps = @()
            $headerFound = $false
            
            foreach ($line in $lines) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                if ($line -match "Canvas App Name|Environment|^-+$") { 
                    $headerFound = $true
                    continue 
                }
                
                # Look for GUID pattern
                if ($line -match "([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})\s+(.+)") {
                    $apps += @{
                        Id = $matches[1].Trim()
                        Name = $matches[2].Trim()
                    }
                    continue
                }
                
                # Parse name-owner-date format
                if ($headerFound -and $line -match "^(.+?)\s{2,}(.+?)\s+(\d{1,2}/\d{1,2}/\d{4})\s*$") {
                    $apps += @{
                        Id = "app_" + ($apps.Count + 1)
                        Name = $matches[1].Trim()
                        Owner = $matches[2].Trim()
                        Date = $matches[3].Trim()
                    }
                    continue
                }
                
                # Fallback: any non-empty line after header
                if ($headerFound -and $line.Length -gt 10 -and -not ($line -match "^Press Enter|^No canvas apps")) {
                    $possibleName = $line -split '\s{2,}' | Select-Object -First 1
                    if ($possibleName -and $possibleName.Trim().Length -gt 0) {
                        $apps += @{
                            Id = "app_" + ($apps.Count + 1)
                            Name = $possibleName.Trim()
                        }
                    }
                }
            }
            
            if ($apps.Count -gt 0) {
                Download-AllApps -Apps $apps
            } else {
                Write-ColorOutput Yellow "No apps found to download."
                Read-Host "Press Enter to continue"
            }
        }
        "5" { Configure-DownloadDirectory }
        "6" { Show-CurrentSettings }
        "7" {
            Clear-Host
            Write-ColorOutput Cyan "Refreshing environment list..."
            & $pacPath env list
            Read-Host "Press Enter to continue"
        }
        "8" {
            Clear-Host
            Write-ColorOutput Green "Thank you for using Power Platform MSAPP Downloader!"
            Write-ColorOutput Yellow "Goodbye! 👋"
            exit
        }
        default {
            Write-ColorOutput Red "Invalid choice. Please try again."
            Start-Sleep -Seconds 2
        }
    }
}