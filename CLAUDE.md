# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview
This repository contains tools for extracting and compacting Microsoft Power Apps MSAPP files using both PowerShell scripts and Microsoft's PAC CLI tool.

## Key Commands

### Using PAC CLI (Recommended)
```bash
# Extract/unpack an MSAPP file to source files
~/bin/pac/tools/pac canvas unpack --msapp "AppName.msapp" --sources "AppName"

# Pack source files back into an MSAPP file  
~/bin/pac/tools/pac canvas pack --sources "AppName" --msapp "NewMSAPP/AppName.msapp"

# Validate source files
~/bin/pac/tools/pac canvas validate --sources "AppName"

# Download canvas app from Power Platform
~/bin/pac/tools/pac canvas download --environment <env-id> --app <app-id> --path "AppName.msapp"

# List available canvas apps
~/bin/pac/tools/pac canvas list --environment <env-id>
```

### Using PowerShell Scripts (Legacy)
```powershell
# Extract MSAPP file
.\msapp-extract.ps1  # Run in folder with .msapp file

# Compact folder back to MSAPP
.\msapp-compact.ps1  # Run in folder with extracted app folder
```

## Project Structure
```
MSAPP-PAC-Extract/
├── msapp-extract.ps1          # PowerShell script to extract MSAPP files
├── msapp-compact.ps1          # PowerShell script to compress folders to MSAPP
├── file-backups/              # Automatic backup directory with timestamps
├── NewMSAPP/                  # Output directory for compressed MSAPP files
├── Power Fx Coding WalkThrough/  # Example extracted Power App
│   ├── Components/            # App components
│   ├── Controls/              # UI controls
│   ├── References/            # Data sources and themes
│   ├── Resources/             # App resources  
│   └── Properties.json        # App properties
└── ~/bin/pac/tools/pac        # PAC CLI executable location
```

## Architecture & Implementation Details

### MSAPP File Format
- MSAPP files are essentially ZIP archives with a different extension
- Contains JSON files defining app structure, controls, formulas, and resources
- Can be extracted to enable version control and code review

### PowerShell Scripts Workflow
1. **msapp-extract.ps1**: 
   - Creates timestamped backup in `file-backups/`
   - Renames .msapp to .zip
   - Extracts contents to folder with same name
   - Removes temporary .zip file
   - Creates README in backup folder

2. **msapp-compact.ps1**:
   - Creates timestamped backup
   - Compresses app folder to .zip
   - Renames .zip to .msapp
   - Places output in `NewMSAPP/` folder

### PAC CLI Advantages
- Official Microsoft tool with better compatibility
- Preserves Power Fx formulas in readable YAML format
- Supports validation of source files
- Direct integration with Power Platform environments
- Better handling of component references and dependencies

## Important Notes

### PAC CLI Limitations on Linux
- `pac data` commands are Windows-only
- `pac package deploy` and `pac package show` commands are Windows-only
- Most other functionality works cross-platform

### Authentication for PAC CLI
Before using environment-specific commands, authenticate:
```bash
# Interactive authentication
~/bin/pac/tools/pac auth create --environment <environment-url>

# List current auth profiles
~/bin/pac/tools/pac auth list

# Clear authentication
~/bin/pac/tools/pac auth clear
```

### Working with Extracted Apps
- JSON files contain control properties and formulas
- Power Fx formulas are embedded in JSON properties
- Component IDs are numeric references throughout the structure
- Themes and resources are stored in References folder
- Test definitions are in AppTests folder

## Development Workflow

### Extracting and Modifying Apps
1. Place MSAPP file in project root
2. Extract using PAC CLI: `~/bin/pac/tools/pac canvas unpack --msapp "App.msapp" --sources "App"`
3. Make modifications to JSON/YAML files
4. Validate changes: `~/bin/pac/tools/pac canvas validate --sources "App"`
5. Repack: `~/bin/pac/tools/pac canvas pack --sources "App" --msapp "NewMSAPP/App.msapp"`
6. Import back to Power Platform

### Version Control Best Practices
- Always extract MSAPP files before committing
- Use `.gitignore` for:
  - `*.msapp` files (store extracted sources instead)
  - `file-backups/` directory
  - `NewMSAPP/` directory
- Commit extracted source files for proper diff tracking
- Document formula changes in commit messages

## Testing
```bash
# Validate extracted app structure
~/bin/pac/tools/pac canvas validate --sources "AppName"

# Run automated tests (if defined in app)
~/bin/pac/tools/pac test run --path "AppName"
```

## Troubleshooting

### Common Issues
1. **PAC not found**: Ensure PATH includes `~/bin/pac/tools/`
2. **.NET errors**: Verify .NET 8.0 SDK is installed: `dotnet --version`
3. **PowerShell script errors**: Ensure only one .msapp file in directory
4. **Extraction fails**: Check MSAPP file isn't corrupted
5. **Pack fails**: Validate source structure hasn't been corrupted

### Debug Commands
```bash
# Check PAC CLI version
~/bin/pac/tools/pac help

# Verify .NET installation
dotnet --list-sdks

# Test PowerShell availability  
pwsh --version
```