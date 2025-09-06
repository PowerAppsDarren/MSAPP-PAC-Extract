# 🐛 Bug Fix Summary - MSAPP Downloader Parsing Issue

## Issue Identified
**Date:** September 6, 2025  
**Severity:** Critical - Completely prevented app downloads

### Problem Description
The PowerShell script `download-msapps.ps1` was unable to detect any canvas apps even when they were clearly listed. The script would show:
- "No canvas apps found in this environment" 
- "No apps found to download"

### Root Cause
The script's parsing logic was looking for GUID patterns that weren't present in the PAC CLI output:
```powershell
# OLD CODE - Expected format:
# [GUID-ID]    [App Name]
if ($line -match "^[a-f0-9\-]{36}\s+")
```

But the actual PAC CLI output was:
```
[App Name]    [Owner]    [Date]
```

## Fix Applied

### 1. Enhanced Parsing Logic
Added multiple parsing strategies to handle different output formats:
- **Strategy 1:** Look for GUID patterns (backward compatibility)
- **Strategy 2:** Parse name-owner-date format (current format)
- **Strategy 3:** Fallback to extract any app-like lines

### 2. JSON Output Support
Added support for `--output json` flag to get structured data:
```powershell
$detailedList = & $pacPath canvas list --environment $env --output json
$appsJson = $detailedList | ConvertFrom-Json
```

### 3. Number-Based Selection
Changed from entering App IDs to selecting apps by number:
```
Select an app by number:
  1. Darrens Home Page
     Owner: Darren Neese
  2. Hello World App
     Owner: Darren Neese
```

### 4. Download by Name Fallback
Created `Download-SingleAppByName` function for when App IDs aren't available.

### 5. Improved Batch Download
- Shows all apps before downloading
- Attempts to fetch real IDs using JSON output
- Falls back to downloading by name if needed

## Files Modified
1. **`download-msapps.ps1`** - Main script with fixes
2. **`test-pac-output.ps1`** - New diagnostic script
3. **`BUG-FIX-SUMMARY.md`** - This documentation

## Testing Instructions

### Run Diagnostic Script
```bash
pwsh ./test-pac-output.ps1
```
This will show you:
- PAC CLI version
- Authentication status
- Raw output formats
- JSON parsing results

### Test the Fixed Script
```bash
./run-downloader.sh
# Or
pwsh ./download-msapps.ps1
```

1. Select **1** for Authentication
2. Select **2** to choose environment
3. Select **3** or **4** to download apps
4. Apps should now be properly detected and selectable

## What to Do If Issues Persist

1. **Run the diagnostic script** and save the output
2. **Check JSON support**: The script now tries JSON output which is more reliable
3. **Manual workaround**: If needed, get App IDs manually:
   ```bash
   ~/bin/pac/tools/pac canvas list --output json | jq '.[] | {id: .Name, name: .DisplayName}'
   ```

## Improvements Made

✅ **Flexible parsing** - Handles multiple output formats  
✅ **Better user experience** - Number-based selection instead of copying GUIDs  
✅ **Fallback mechanisms** - Multiple ways to download apps  
✅ **Diagnostic tooling** - Test script to verify PAC CLI output  
✅ **Visual feedback** - Shows apps before batch download  

## Prevention for Future

- Always test with real PAC CLI output before assuming format
- Add diagnostic/debug modes to scripts
- Use structured output (JSON) when available
- Implement multiple parsing strategies for robustness