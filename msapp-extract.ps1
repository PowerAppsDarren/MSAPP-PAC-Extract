# Place & run this file in folder with old MSAPP file
# Make sure no other .msapp files here except above file
# This script extracts the contents of a Power Apps .msapp file to prepare it for version control

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

# Get AppName from old MSAPP file
# Using Get-Item cmdlet to retrieve file information from the current directory
# The wildcard "*" matches any characters while "-Include "*.msapp"" filters for only .msapp files
# The BaseName property returns just the filename without the extension
$AppName = (Get-Item -Path "*" -Include "*.msapp").BaseName

# Backup MSAPP file before any operations
Copy-Item -Path ".\$AppName.msapp" -Destination "$backupFolder\$AppName.msapp" -ErrorAction SilentlyContinue

# Delete old MSAPP extracted folder if it exists
# Test-Path checks if the specified path exists in the filesystem
# ".\$AppName" refers to a folder with the same name as the .msapp file in the current directory
If (Test-Path -Path ".\$AppName") {
    # Backup the folder before deletion if it exists
    Copy-Item -Path ".\$AppName" -Destination "$backupFolder\$AppName" -Recurse -ErrorAction SilentlyContinue
    # Remove-Item deletes the specified item (folder in this case)
    # -Recurse parameter ensures all subfolders and files within that folder are also deleted
    # This prevents conflicts with previously extracted content
    Remove-Item -Path ".\$AppName" -Recurse
}

# Change extension & extract old MSAPP file to folder with same name
# Rename-Item cmdlet changes the name or extension of an item
# MSAPP files are actually ZIP files with a different extension, so we convert it first
# ".\$AppName.msapp" is the source file path and ".\$AppName.zip" is the destination
Rename-Item -Path ".\$AppName.msapp" -NewName ".\$AppName.zip"

# Expand-Archive extracts all files from the specified ZIP archive
# This creates a folder with the same name as the ZIP file and extracts all contents there
# The folder structure will contain all the components of the Power App
Expand-Archive -Path ".\$AppName.zip"

# Remove old MSAPP file to make room for future files saved from Power Apps
# This deletes the temporary ZIP file we created earlier since it's no longer needed
# Clearing this file prevents confusion with any new MSAPP files that may be exported later
Remove-Item -Path ".\$AppName.zip"

# Create a README file documenting the changes
# First prepare variables for conditional content
$backupDetails = "- $AppName.msapp (Original MSAPP file)`r`n"
if (Test-Path -Path "$backupFolder\$AppName") {
    $backupDetails += "- $AppName\ (Existing extracted folder)"
}

$readmeContent = @"
# Backup from MSAPP Extract Operation ($timestamp)

## Files Backed Up:
$backupDetails

## Changes Made by Script:
1. Extracted the MSAPP file ($AppName.msapp) by:
   - Converting it to a ZIP file temporarily
   - Extracting the ZIP contents to a folder named '$AppName'
   - Removing the temporary ZIP file
   - Original MSAPP file was also removed

This backup was created automatically by the 1MSAPPextract.ps1 script.
"@

$readmeContent | Out-File -FilePath "$backupFolder\README.md" -Encoding UTF8