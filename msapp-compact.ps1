# Place & run this file in folder with old MSAPP extracted folder
# Make sure no other folders here except above folder and NewMSAPP folder
# This script compresses an extracted Power Apps folder back into an .msapp file format

# Create backup folder structure with timestamp
# Create a "file-backups" folder if it doesn't exist
$backupRoot = ".\file-backups"
If(!(Test-Path -Path $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot | Out-Null
}

# Create timestamped subfolder for this backup session
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupFolder = "$backupRoot\$timestamp"
New-Item -ItemType Directory -Path $backupFolder | Out-Null

# Get AppName from old MSAPP extracted folder name - fix to exclude file-backups folder
$folders = Get-ChildItem -Directory -Exclude "NewMSAPP", "*RECYCLE.BIN", "file-backups" | Select-Object -ExpandProperty Name

# Verify we found exactly one app folder
if ($folders.Count -eq 0) {
    Write-Error "No app folders found! Please make sure you're running this script in the correct directory."
    exit 1
} elseif ($folders.Count -gt 1) {
    Write-Error "Multiple folders found: $($folders -join ', '). Please ensure only one app folder exists in this directory."
    exit 1
}

# Set AppName to the single folder we found
$AppName = $folders

# Create NewMSAPP folder if it doesn't exist
$NewMSAPP = ".\NewMSAPP"
If(!(Test-Path -Path $NewMSAPP)) { 
    New-Item -ItemType Directory -Path $NewMSAPP | Out-Null
}

# Delete MSAPP file in NewMSAPP folder if it exists
If (Test-Path -Path "$NewMSAPP\$AppName.msapp") {
    # Backup the existing MSAPP file before deletion
    New-Item -ItemType Directory -Path "$backupFolder\NewMSAPP" -ErrorAction SilentlyContinue | Out-Null
    Copy-Item -Path "$NewMSAPP\$AppName.msapp" -Destination "$backupFolder\NewMSAPP\$AppName.msapp" -ErrorAction SilentlyContinue
    # Remove the existing file
    Remove-Item -Path "$NewMSAPP\$AppName.msapp"
}

# Backup the extracted app folder before compression
Copy-Item -Path ".\$AppName" -Destination "$backupFolder\$AppName" -Recurse -ErrorAction SilentlyContinue

# Compress & change extension for new MSAPP file in NewMSAPP folder
Write-Host "Compressing folder '$AppName' into MSAPP file..."
Compress-Archive -Path ".\$AppName\*" -DestinationPath "$NewMSAPP\$AppName.zip" -Update
Rename-Item -Path "$NewMSAPP\$AppName.zip" -NewName "$AppName.msapp"
Write-Host "Successfully created: $NewMSAPP\$AppName.msapp"

# Create a README file documenting the changes
$backupDetails = "- ${AppName} (Extracted app folder)`r`n"

# Check for existing MSAPP file
if (Test-Path -Path "$backupFolder\NewMSAPP\$AppName.msapp") {
    $backupDetails += "- NewMSAPP\${AppName}.msapp (Existing MSAPP file)"
}

# Use the prepared variables in the here-string to avoid parsing issues
$readmeContent = @"
# Backup from MSAPP Compress Operation ($timestamp)

## Files Backed Up:
$backupDetails

## Changes Made by Script:
1. Compressed the extracted app folder ($AppName) back into an MSAPP file:
   - Created a ZIP archive from the folder contents
   - Renamed the ZIP file to have .msapp extension
   - Placed the resulting file in the NewMSAPP folder as '${AppName}.msapp'

This backup was created automatically by the 2MSAPPcompress.ps1 script.
"@

# Write the content to the README file
$readmeContent | Out-File -FilePath "$backupFolder\README.md" -Encoding UTF8