#!/usr/bin/env pwsh
# Interactive Power Platform MSAPP Downloader
# This script provides an interactive menu system to connect to Power Platform and download canvas apps

# Set PAC CLI path
$pacPath = "$HOME/bin/pac/tools/pac"

# Configuration file path
$configPath = Join-Path $PSScriptRoot "msapp-downloader-config.json"

# Colors for better visibility
$Host.UI.RawUI.BackgroundColor = 'Black'
$Host.UI.RawUI.ForegroundColor = 'White'

# Configuration functions
function Load-Configuration {
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath | ConvertFrom-Json
            return $config
        } catch {
            Write-ColorOutput Yellow "⚠️  Could not load saved configuration. Starting fresh."
            return @{}
        }
    }
    return @{}
}

function Save-Configuration {
    param(
        [hashtable]$Config
    )
    
    try {
        # Ensure the config is a proper hashtable
        if ($null -eq $Config) {
            $Config = @{}
        }
        
        # Convert hashtable to JSON and save
        $jsonContent = $Config | ConvertTo-Json -Depth 3
        $jsonContent | Set-Content $configPath -Force
        
        # Don't show success message every time - it's too verbose
        # Only show on explicit saves or errors
    } catch {
        Write-ColorOutput Red "❌ Could not save configuration: $_"
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Update-ConfigValue {
    param(
        [string]$Key,
        $Value
    )
    
    $script:config[$Key] = $Value
    Save-Configuration -Config $script:config
}

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
    
    # Show current environment if set
    if ($script:currentEnvironment) {
        Write-Host ""
        Write-ColorOutput Green "📍 Current Environment: $script:currentEnvironment"
    }
    if ($script:config.LastAuthProfile) {
        Write-ColorOutput Blue "👤 Auth Profile: $($script:config.LastAuthProfile)"
    }
    
    Write-Host ""
    Write-ColorOutput Green "MAIN MENU:"
    Write-Host "  1. 🔐 Manage Authentication"
    Write-Host "  2. 🌍 Select Environment"
    Write-Host "  3. 📱 Download Canvas Apps"
    Write-Host "  4. 📦 Batch Download All Apps"
    Write-Host "  5. 📁 Configure Download Directory"
    Write-Host "  6. ℹ️  Show Current Settings"
    Write-Host "  7. 🔄 Refresh Environment List"
    Write-Host "  8. 🗑️  Clear Saved Settings"
    Write-Host "  9. ❌ Exit"
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
                # Generate a profile name from the environment URL
                $profileName = ($envUrl -replace 'https://', '' -replace '\..*', '')
            } else {
                & $pacPath auth create --environment $envUrl --name $profileName
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-ColorOutput Green "✅ Authentication created successfully!"
                
                # Save to config
                Update-ConfigValue -Key "LastAuthProfile" -Value $profileName
                Update-ConfigValue -Key "LastEnvironmentUrl" -Value $envUrl
                Update-ConfigValue -Key "LastAuthType" -Value "Interactive"
                Update-ConfigValue -Key "LastAuthTime" -Value (Get-Date).ToString()
            }
            
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
            
            $profileName = Read-Host "Profile Name (optional)"
            if ([string]::IsNullOrWhiteSpace($profileName)) {
                $profileName = "sp_" + ($appId.Substring(0, 8))
            }
            
            & $pacPath auth create --tenant $tenantId --applicationId $appId --clientSecret $secret --environment $envUrl --name $profileName
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-ColorOutput Green "✅ Service Principal authentication created!"
                
                # Save to config (don't save secret)
                Update-ConfigValue -Key "LastAuthProfile" -Value $profileName
                Update-ConfigValue -Key "LastEnvironmentUrl" -Value $envUrl
                Update-ConfigValue -Key "LastTenantId" -Value $tenantId
                Update-ConfigValue -Key "LastAppId" -Value $appId
                Update-ConfigValue -Key "LastAuthType" -Value "ServicePrincipal"
                Update-ConfigValue -Key "LastAuthTime" -Value (Get-Date).ToString()
            }
            
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
    $envOutput = & $pacPath env list 2>&1 | Out-String
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput Red "❌ Error: Unable to fetch environments. Please check authentication."
        Write-Host $envOutput
        Read-Host "Press Enter to continue"
        return $null
    }
    
    # Parse the environment list to extract environment details
    $lines = $envOutput -split "`n"
    $environments = @()
    $inTable = $false
    
    foreach ($line in $lines) {
        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        
        # Look for environment entries (they typically have URLs or GUIDs)
        if ($line -match "https://[^\s]+") {
            # Extract URL and other details from the line
            $envUrl = $matches[0]
            $envName = ""
            $envId = ""
            $uniqueName = ""
            
            # Try to extract environment ID (GUID pattern)
            if ($line -match "([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})") {
                $envId = $matches[1]
            }
            
            # Try to extract display name (usually first part of the line)
            $parts = $line -split '\s{2,}'
            if ($parts.Count -gt 0) {
                # First non-empty part that's not a URL or GUID
                foreach ($part in $parts) {
                    $trimmed = $part.Trim()
                    if ($trimmed -and -not ($trimmed -match "^https://" -or $trimmed -match "^[a-f0-9]{8}-")) {
                        $envName = $trimmed
                        break
                    }
                }
            }
            
            # Extract unique name from URL if possible
            if ($envUrl -match "https://([^\.]+)\.") {
                $uniqueName = $matches[1]
            }
            
            $environments += @{
                Name = if ($envName) { $envName } else { $uniqueName }
                Id = if ($envId) { $envId } else { $envUrl }
                Url = $envUrl
                UniqueName = $uniqueName
                FullLine = $line.Trim()
            }
        }
        # Alternative: Look for lines with environment IDs without URLs
        elseif ($line -match "([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})") {
            $envId = $matches[1]
            $parts = $line -split '\s{2,}'
            $envName = if ($parts.Count -gt 0) { $parts[0].Trim() } else { "Environment" }
            
            $environments += @{
                Name = $envName
                Id = $envId
                Url = ""
                UniqueName = ""
                FullLine = $line.Trim()
            }
        }
    }
    
    # If no environments found, show raw output and ask for manual input
    if ($environments.Count -eq 0) {
        Write-ColorOutput Yellow "Could not parse environment list. Here's the raw output:"
        Write-Host $envOutput
        Write-Host ""
        Write-ColorOutput Yellow "Please enter the Environment ID or URL manually:"
        $selectedEnv = Read-Host "Environment"
    }
    else {
        # Display environments with numbers - COMPACT VIEW
        Write-ColorOutput Green "Available Environments:"
        Write-Host ""
        
        # Display in columns for better use of space
        $columnWidth = 40
        for ($i = 0; $i -lt $environments.Count; $i++) {
            $env = $environments[$i]
            $number = "{0,2}." -f ($i + 1)
            $displayName = if ($env.Name) { $env.Name } else { $env.UniqueName }
            
            # Truncate long names to fit in column
            if ($displayName.Length -gt ($columnWidth - 4)) {
                $displayName = $displayName.Substring(0, $columnWidth - 7) + "..."
            }
            
            # Format the line with number and name
            Write-Host $number -NoNewline -ForegroundColor Yellow
            Write-Host " $displayName" -ForegroundColor Cyan
        }
        
        Write-Host ""
        
        # Check if there's a current/active environment
        $currentEnvLine = $lines | Where-Object { $_ -match "\*" -or $_ -match "Active" -or $_ -match "Current" }
        if ($currentEnvLine) {
            Write-ColorOutput Blue "📍 Currently selected environment is marked with * or Active"
            Write-Host ""
        }
        
        Write-ColorOutput Yellow "Select an environment by number (1-$($environments.Count)):"
        Write-Host "Or enter 'D' to show detailed info for all environments"
        Write-Host "Or enter 'M' to manually input an Environment ID/URL"
        Write-Host "Or enter 'C' to cancel"
        Write-Host ""
        
        $selection = Read-Host "Your choice"
        
        if ($selection -eq 'C' -or $selection -eq 'c') {
            Write-ColorOutput Yellow "Environment selection cancelled."
            Read-Host "Press Enter to continue"
            return $null
        }
        elseif ($selection -eq 'D' -or $selection -eq 'd') {
            # Show detailed view
            Write-Host ""
            Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
            Write-ColorOutput Yellow "DETAILED ENVIRONMENT INFORMATION"
            Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
            Write-Host ""
            
            for ($i = 0; $i -lt $environments.Count; $i++) {
                $env = $environments[$i]
                Write-Host "$($i + 1). " -NoNewline -ForegroundColor Yellow
                Write-Host "$($env.Name)" -ForegroundColor Cyan
                if ($env.Url) {
                    Write-Host "   URL: $($env.Url)" -ForegroundColor Gray
                }
                if ($env.Id -and $env.Id -ne $env.Url) {
                    Write-Host "   ID: $($env.Id)" -ForegroundColor Gray
                }
                Write-Host ""
            }
            
            Write-Host "Press Enter to return to selection menu..." -ForegroundColor Yellow
            Read-Host
            
            # Recursive call to show the menu again
            return Select-Environment
        }
        elseif ($selection -eq 'M' -or $selection -eq 'm') {
            Write-Host ""
            Write-ColorOutput Yellow "Enter the Environment ID or URL manually:"
            $selectedEnv = Read-Host "Environment"
        }
        elseif ($selection -match '^\d+$') {
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $environments.Count) {
                $selectedEnv = $environments[$index].Id
                Write-Host ""
                Write-ColorOutput Green "Selected: $($environments[$index].Name)"
            }
            else {
                Write-ColorOutput Red "❌ Invalid selection. Please choose a number between 1 and $($environments.Count)"
                Read-Host "Press Enter to continue"
                return $null
            }
        }
        else {
            Write-ColorOutput Red "❌ Invalid input"
            Read-Host "Press Enter to continue"
            return $null
        }
    }
    
    # Select the environment
    Write-Host ""
    Write-ColorOutput Cyan "Selecting environment..."
    & $pacPath env select --environment $selectedEnv
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✅ Environment selected successfully!"
        $script:currentEnvironment = $selectedEnv
        
        # Save to config
        Update-ConfigValue -Key "LastEnvironment" -Value $selectedEnv
        Update-ConfigValue -Key "LastEnvironmentTime" -Value (Get-Date).ToString()
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
    $lines = $appsOutput -split "`n"
    $apps = @()
    $dashLineFound = $false
    
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        
        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
        
        # Look for the header separator (dashes)
        if ($trimmed -match '^-+$') {
            $dashLineFound = $true
            continue
        }
        
        # Skip lines until we've passed the header
        if (-not $dashLineFound) { continue }
        
        # Skip footer lines
        if ($trimmed -match '^Press Enter|^No canvas|^Active auth|^Environment ID') { continue }
        
        # Parse app lines (format: AppName    Owner Name    Date)
        # The date is always at the end in MM/DD/YYYY format
        if ($trimmed -match '(.+?)\s{2,}(.+?)\s{2,}(\d{1,2}/\d{1,2}/\d{4})') {
            $appName = $matches[1].Trim()
            $owner = $matches[2].Trim()
            $date = $matches[3].Trim()
            
            # Skip if this is actually the header row
            if ($appName -eq "Name" -or $appName -eq "Canvas App Name") { continue }
            
            $apps += @{
                Id = "name:$appName"
                Name = $appName
                Date = $date
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
    Write-Host "  1. 📥 Download specific app"
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
                $displayText = "{0,3}. {1}" -f ($i + 1), $apps[$i].Name
                Write-Host $displayText -ForegroundColor Cyan
                if ($apps[$i].Date) {
                    Write-Host "      Modified: $($apps[$i].Date)" -ForegroundColor Gray
                }
            }
            Write-Host ""
            $selection = Read-Host "Enter app number (1-$($apps.Count))"
            
            if ($selection -match '^\d+$') {
                $index = [int]$selection - 1
                if ($index -ge 0 -and $index -lt $apps.Count) {
                    $selectedApp = $apps[$index]
                    
                    # Since we're using app names now, use the name-based download
                    Write-ColorOutput Yellow "Downloading: $($selectedApp.Name)"
                    Download-SingleAppByName -AppName $selectedApp.Name
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
    
    # Show the apps that will be downloaded in a compact format
    Write-Host ""
    Write-ColorOutput Green "Apps to download:"
    Write-Host ""
    
    # Display apps in a cleaner format
    $index = 1
    foreach ($app in $Apps) {
        # Format the app name with index
        $displayLine = "{0,3}. {1,-40} {2}" -f $index, $app.Name, $(if($app.Date) { "($($app.Date))" } else { "" })
        Write-Host $displayLine -ForegroundColor Cyan
        $index++
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
        
        # PAC CLI supports downloading by app name
        & $pacPath canvas download --environment $script:currentEnvironment --app "$($app.Name)" --path $filePath 2>&1 | Out-Null
        
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
    Write-ColorOutput Yellow "📊 DOWNLOAD SUMMARY"
    Write-ColorOutput Green "════════════════════════════════════════════════════════════════"
    Write-Host ""
    Write-Host "Environment: $script:currentEnvironment" -ForegroundColor Cyan
    Write-Host "Total Apps: $($Apps.Count)" -ForegroundColor White
    Write-ColorOutput Green "✅ Downloaded: $successCount"
    if ($failCount -gt 0) {
        Write-ColorOutput Red "❌ Failed: $failCount"
    }
    Write-Host "Download Location: $script:downloadDirectory" -ForegroundColor Gray
    Write-Host ""
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
            
            # Save to config
            Update-ConfigValue -Key "DownloadDirectory" -Value $newPath
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
    
    Write-ColorOutput Green "════════════════════════════════════════════════════════════════"
    Write-ColorOutput Yellow "SAVED CONFIGURATION:"
    Write-ColorOutput Green "════════════════════════════════════════════════════════════════"
    
    if ($script:config -and $script:config.Count -gt 0) {
        Write-Host ""
        Write-Host "📝 Configuration File: $configPath" -ForegroundColor Cyan
        Write-Host ""
        
        if ($script:config.LastAuthProfile) {
            Write-Host "🔐 Saved Auth Profile: $($script:config.LastAuthProfile)" -ForegroundColor White
            Write-Host "   Type: $($script:config.LastAuthType)" -ForegroundColor Gray
            Write-Host "   Last Used: $($script:config.LastAuthTime)" -ForegroundColor Gray
        }
        
        if ($script:config.LastEnvironment) {
            Write-Host ""
            Write-Host "🌍 Saved Environment: $($script:config.LastEnvironment)" -ForegroundColor White
            Write-Host "   Last Used: $($script:config.LastEnvironmentTime)" -ForegroundColor Gray
        }
        
        if ($script:config.LastTenantId) {
            Write-Host ""
            Write-Host "🏢 Saved Tenant ID: $($script:config.LastTenantId)" -ForegroundColor White
        }
        
        if ($script:config.LastAppId) {
            Write-Host "📱 Saved App ID: $($script:config.LastAppId)" -ForegroundColor White
        }
        
        if ($script:config.DownloadDirectory) {
            Write-Host ""
            Write-Host "📁 Saved Download Dir: $($script:config.DownloadDirectory)" -ForegroundColor White
        }
    } else {
        Write-Host ""
        Write-Host "  No saved configuration found" -ForegroundColor Gray
        Write-Host "  Settings will be saved as you use the app" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-ColorOutput Green "════════════════════════════════════════════════════════════════"
    Write-Host ""
    
    Read-Host "Press Enter to continue"
}

# Load configuration
$script:config = Load-Configuration

# Initialize config as hashtable if it's empty
if (-not $script:config -or $script:config.GetType().Name -ne "Hashtable") {
    $script:config = @{}
}

# Initialize variables with saved values or defaults
$script:currentEnvironment = if ($script:config.LastEnvironment) { $script:config.LastEnvironment } else { "" }
$script:downloadDirectory = if ($script:config.DownloadDirectory) { $script:config.DownloadDirectory } else { Join-Path (Get-Location) "downloads" }

# Save initial config if it doesn't exist
if (-not (Test-Path $configPath)) {
    $script:config.DownloadDirectory = $script:downloadDirectory
    $script:config.ConfigVersion = "1.0"
    $script:config.CreatedDate = (Get-Date).ToString()
    Save-Configuration -Config $script:config
}

# Create download directory if it doesn't exist
if (!(Test-Path $script:downloadDirectory)) {
    New-Item -ItemType Directory -Path $script:downloadDirectory -Force | Out-Null
}

# Auto-apply saved settings on startup
if ($script:config -and ($script:config.LastAuthProfile -or $script:config.LastEnvironment)) {
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-ColorOutput Yellow "     🔄 LOADING SAVED CONFIGURATION"
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-Host ""
    
    if ($script:config.LastAuthProfile) {
        Write-Host "📝 Last Auth Profile: $($script:config.LastAuthProfile)" -ForegroundColor Green
        Write-Host "   Type: $($script:config.LastAuthType)" -ForegroundColor Gray
        Write-Host "   Last Used: $($script:config.LastAuthTime)" -ForegroundColor Gray
        
        # Try to activate the saved auth profile
        Write-Host ""
        Write-Host "Activating saved authentication profile..." -ForegroundColor Cyan
        & $pacPath auth select --name $script:config.LastAuthProfile 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput Green "✅ Authentication profile activated"
        } else {
            Write-ColorOutput Yellow "⚠️  Could not activate saved profile. You may need to re-authenticate."
        }
    }
    
    if ($script:config.LastEnvironment) {
        Write-Host ""
        Write-Host "🌍 Last Environment: $($script:config.LastEnvironment)" -ForegroundColor Green
        Write-Host "   Last Used: $($script:config.LastEnvironmentTime)" -ForegroundColor Gray
        
        # Auto-select the saved environment
        Write-Host ""
        Write-Host "Auto-selecting saved environment..." -ForegroundColor Cyan
        & $pacPath env select --environment $script:config.LastEnvironment 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput Green "✅ Environment selected"
            $script:currentEnvironment = $script:config.LastEnvironment
        } else {
            Write-ColorOutput Yellow "⚠️  Could not select saved environment. Please select manually."
            $script:currentEnvironment = ""
        }
    }
    
    if ($script:config.DownloadDirectory) {
        Write-Host ""
        Write-Host "📁 Download Directory: $($script:config.DownloadDirectory)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
    Write-Host ""
    Write-Host "Press Enter to continue to main menu..." -ForegroundColor Yellow
    Read-Host
}

# Main program loop
# Main program loop
while ($true) {
    Show-MainMenu
    $choice = Read-Host "Enter your choice (1-9)"
    
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
                            # Save to config
                            Update-ConfigValue -Key "LastAuthProfile" -Value $profileName
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
            Write-Host "Environment: $script:currentEnvironment" -ForegroundColor Gray
            $appsOutput = & $pacPath canvas list --environment $script:currentEnvironment 2>&1 | Out-String
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput Red "❌ Error: Unable to fetch apps"
                Read-Host "Press Enter to continue"
                continue
            }
            
            # Parse the PAC CLI output
            $lines = $appsOutput -split "`n"
            $apps = @()
            
            # Skip header lines and parse actual app entries
            $headerFound = $false
            $dashLineFound = $false
            
            foreach ($line in $lines) {
                $trimmed = $line.Trim()
                
                # Skip empty lines
                if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
                
                # Look for the header separator (dashes)
                if ($trimmed -match '^-+$') {
                    $dashLineFound = $true
                    continue
                }
                
                # Skip lines until we've passed the header
                if (-not $dashLineFound) { continue }
                
                # Skip footer lines
                if ($trimmed -match '^Press Enter|^No canvas|^Active auth|^Environment ID') { continue }
                
                # Parse app lines (format: AppName    Owner Name    Date)
                # The date is always at the end in MM/DD/YYYY format
                if ($trimmed -match '(.+?)\s{2,}(.+?)\s{2,}(\d{1,2}/\d{1,2}/\d{4})') {
                    $appName = $matches[1].Trim()
                    $owner = $matches[2].Trim()  
                    $date = $matches[3].Trim()
                    
                    # Skip if this is actually the header row
                    if ($appName -eq "Name" -or $appName -eq "Canvas App Name") { continue }
                    
                    $apps += @{
                        Id = "name:$appName"
                        Name = $appName
                        Date = $date
                    }
                }
            }
            
            Write-Host ""
            
            if ($apps.Count -gt 0) {
                Write-Host ""
                Write-ColorOutput Green "Found $($apps.Count) app(s) to download"
                Download-AllApps -Apps $apps
            } else {
                Write-ColorOutput Yellow "No apps found to download."
                Write-Host ""
                Write-ColorOutput Yellow "Debug Info:"
                Write-Host "Environment: $script:currentEnvironment" -ForegroundColor Gray
                Write-Host "Raw output lines: $($lines.Count)" -ForegroundColor Gray
                Write-Host ""
                Write-Host "Would you like to see the raw output? (Y/N)" -ForegroundColor Yellow
                $showRaw = Read-Host
                if ($showRaw -eq 'Y' -or $showRaw -eq 'y') {
                    Write-Host ""
                    Write-Host "Raw PAC CLI Output:" -ForegroundColor Cyan
                    Write-Host $appsOutput
                }
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
            # Clear saved settings
            Clear-Host
            Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
            Write-ColorOutput Yellow "     🗑️  CLEAR SAVED SETTINGS"
            Write-ColorOutput Cyan "════════════════════════════════════════════════════════════════"
            Write-Host ""
            
            if (Test-Path $configPath) {
                Write-ColorOutput Yellow "This will clear all saved settings including:"
                Write-Host "  - Authentication profiles references"
                Write-Host "  - Last used environment"
                Write-Host "  - Download directory preference"
                Write-Host "  - Tenant and app IDs (if saved)"
                Write-Host ""
                Write-ColorOutput Red "Note: This does NOT remove PAC CLI authentication profiles."
                Write-Host "To remove those, use option 1 → 3 (Delete Authentication Profile)"
                Write-Host ""
                
                $confirm = Read-Host "Are you sure you want to clear saved settings? (Y/N)"
                
                if ($confirm -eq 'Y' -or $confirm -eq 'y') {
                    Remove-Item $configPath -Force
                    $script:config = @{}
                    $script:currentEnvironment = ""
                    $script:downloadDirectory = Join-Path (Get-Location) "downloads"
                    
                    Write-Host ""
                    Write-ColorOutput Green "✅ Saved settings cleared!"
                } else {
                    Write-Host ""
                    Write-ColorOutput Yellow "Settings not cleared."
                }
            } else {
                Write-ColorOutput Yellow "No saved settings found."
            }
            
            Read-Host "Press Enter to continue"
        }
        "9" {
            Clear-Host
            Write-ColorOutput Green "Thank you for using Power Platform MSAPP Downloader!"
            Write-ColorOutput Yellow "Configuration saved for next time."
            Write-ColorOutput Yellow "Goodbye! 👋"
            exit
        }
        default {
            Write-ColorOutput Red "Invalid choice. Please try again."
            Start-Sleep -Seconds 2
        }
    }
}