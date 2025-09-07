# Power Platform MSAPP Downloader

An interactive PowerShell script for downloading Canvas Apps from your Power Platform environment.

## 🚀 Quick Start

```bash
# Run the downloader
./run-downloader.sh

# Or directly with PowerShell
pwsh download-msapps.ps1
```

## 📋 Prerequisites

✅ **Installed:**
- .NET SDK 8.0
- PAC CLI (at `~/bin/pac/tools/pac`)
- PowerShell Core 7.5.2

## 🎯 Features

### Main Menu Options:

1. **🔐 Manage Authentication**
   - Create new authentication profiles (Interactive or Service Principal)
   - Switch between authentication profiles
   - Delete authentication profiles
   - View current authentication status
   - **Settings automatically saved for next session**

2. **🌍 Select Environment**
   - List all available Power Platform environments
   - Select the active environment for operations
   - Automatically fetches environment details
   - **Last used environment is remembered**

3. **📱 Download Canvas Apps**
   - View all canvas apps in selected environment
   - Download individual apps by number selection
   - Automatic filename sanitization with timestamps
   - Option to extract apps immediately after download

4. **📦 Batch Download All Apps**
   - Download all canvas apps from environment at once
   - Progress tracking for batch operations
   - Summary report of successful/failed downloads
   - Option to bulk extract all downloaded apps

5. **📁 Configure Download Directory**
   - Set custom download location
   - Create directories if they don't exist
   - Default: `./downloads` folder
   - **Directory preference is saved**

6. **ℹ️ Show Current Settings**
   - Display PAC CLI location
   - Show download directory
   - Current environment details
   - Active authentication profile
   - Count of downloaded and extracted apps
   - **View all saved configuration settings**

7. **🔄 Refresh Environment List**
   - Re-fetch the list of available environments

8. **🗑️ Clear Saved Settings** *(NEW)*
   - Remove all saved preferences
   - Reset to default settings
   - Does NOT delete PAC CLI auth profiles

9. **❌ Exit**
   - Close the application
   - Configuration is automatically saved

## 📁 Directory Structure

```
downloads/                          # Default download directory
├── AppName_2025-09-06_14-30-00.msapp    # Downloaded MSAPP files
├── extracted_AppName_2025-09-06_14-30-00/  # Extracted app sources
│   ├── CanvasManifest.json
│   ├── Components/
│   ├── Controls/
│   └── ...
```

## 🔐 Authentication Setup

### Interactive Authentication (Recommended)
1. Select "Manage Authentication" → "Create New Authentication"
2. Choose "Interactive (Browser-based)"
3. Enter your environment URL (e.g., `https://org12345.crm.dynamics.com`)
4. Browser will open for Microsoft login
5. Complete authentication in browser

### Service Principal Authentication
1. Create an App Registration in Azure AD
2. Grant appropriate permissions to Power Platform
3. Select "Service Principal" authentication
4. Provide:
   - Tenant ID
   - Application (Client) ID
   - Client Secret
   - Environment URL

## 💡 Usage Examples

### Download Single App
1. Run the script: `./run-downloader.sh`
2. Select "1" for Authentication (if not already authenticated)
3. Select "2" to choose your environment
4. Select "3" for Download Canvas Apps
5. Choose option "1" and enter the App ID

### Batch Download All Apps
1. Authenticate and select environment (steps 1-3 above)
2. Select "4" for Batch Download All Apps
3. Confirm the download
4. Optionally extract all apps after download

### Extract Downloaded Apps
The script offers automatic extraction after download, or you can manually extract:
```bash
~/bin/pac/tools/pac canvas unpack --msapp "AppName.msapp" --sources "AppName_extracted"
```

## 🎨 Features

- **Color-coded output** for better visibility
- **Interactive menus** with numbered options
- **Automatic filename sanitization** (removes special characters)
- **Timestamp tracking** for version management
- **Batch operations** with progress tracking
- **Error handling** with clear error messages
- **Settings persistence** within session

## ⚠️ Troubleshooting

### Authentication Issues
- Ensure you have appropriate permissions in Power Platform
- Check if your environment URL is correct
- For Service Principal, verify app registration permissions

### Download Failures
- Check network connectivity
- Verify environment selection
- Ensure authentication token hasn't expired
- Check if app exists and you have access

### PowerShell Errors
- Ensure PowerShell Core is installed: `pwsh --version`
- Check PAC CLI is accessible: `~/bin/pac/tools/pac help`

## 📝 Notes

- Downloaded files include timestamp to prevent overwrites
- Extracted apps maintain the full Power Fx structure
- The script creates a `downloads` folder automatically
- All operations are logged to console for debugging

## 🔄 Updates

To update PAC CLI to the latest version:
```bash
# Download latest NuGet package
cd ~/bin/pac
wget https://www.nuget.org/api/v2/package/Microsoft.PowerApps.CLI.Core.linux-x64 -O pac-new.nupkg
unzip -o pac-new.nupkg
```

## 📚 Additional Resources

- [PAC CLI Documentation](https://aka.ms/PowerPlatformCLI)
- [Power Platform Build Tools](https://github.com/microsoft/powerplatform-build-tools/discussions)
- [Canvas Apps Overview](https://docs.microsoft.com/en-us/powerapps/maker/canvas-apps/)