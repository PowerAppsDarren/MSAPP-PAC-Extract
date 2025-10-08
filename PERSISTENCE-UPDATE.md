# 🔄 Configuration Persistence Update

## New Features Added

The MSAPP Downloader script now **remembers your settings** between sessions!

### What Gets Saved:

1. **🔐 Authentication Profile**
   - Last used profile name
   - Authentication type (Interactive/Service Principal)
   - Timestamp of last authentication

2. **🌍 Environment**
   - Last selected environment URL/ID
   - Timestamp of last selection

3. **🏢 Service Principal Details** (if used)
   - Tenant ID
   - Application ID
   - Note: Client secrets are NEVER saved

4. **📁 Download Directory**
   - Your preferred download location

### How It Works:

#### On Startup:
```
════════════════════════════════════════════════════════════════
     🔄 LOADING SAVED CONFIGURATION
════════════════════════════════════════════════════════════════

📝 Last Auth Profile: org12345
   Type: Interactive
   Last Used: 9/6/2025 5:45:00 PM

🌍 Last Environment: https://org12345.crm.dynamics.com
   Last Used: 9/6/2025 5:46:00 PM

📁 Download Directory: /home/user/downloads

Activating saved authentication profile...
✅ Authentication profile activated

Auto-selecting saved environment...
✅ Environment selected
```

#### Configuration File:
Settings are saved in: `msapp-downloader-config.json` (in script directory)

Example config file:
```json
{
  "LastAuthProfile": "org12345",
  "LastEnvironmentUrl": "https://org12345.crm.dynamics.com",
  "LastAuthType": "Interactive",
  "LastAuthTime": "9/6/2025 5:45:00 PM",
  "LastEnvironment": "https://org12345.crm.dynamics.com",
  "LastEnvironmentTime": "9/6/2025 5:46:00 PM",
  "DownloadDirectory": "/home/user/downloads",
  "LastTenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "LastAppId": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
}
```

### New Menu Options:

#### Main Menu Shows Active Settings:
```
════════════════════════════════════════════════════════════════
     🚀 POWER PLATFORM MSAPP DOWNLOADER
════════════════════════════════════════════════════════════════

📍 Current Environment: https://org12345.crm.dynamics.com
👤 Auth Profile: org12345

MAIN MENU:
  1. 🔐 Manage Authentication
  2. 🌍 Select Environment
  3. 📱 Download Canvas Apps
  4. 📦 Batch Download All Apps
  5. 📁 Configure Download Directory
  6. ℹ️  Show Current Settings
  7. 🔄 Refresh Environment List
  8. 🗑️  Clear Saved Settings    ← NEW!
  9. ❌ Exit
```

#### Option 6 - Enhanced Settings Display:
Now shows both current session settings AND saved configuration:
- Current active settings
- Downloaded apps count
- **Saved configuration details**
- Configuration file location

#### Option 8 - Clear Saved Settings (NEW):
- Removes all saved preferences
- Does NOT delete PAC CLI authentication profiles
- Resets to default settings
- Requires confirmation

### Security Notes:

✅ **What IS Saved:**
- Profile names and references
- Environment URLs
- Tenant and App IDs
- Timestamps
- Directory preferences

❌ **What is NOT Saved:**
- Passwords
- Client secrets
- Authentication tokens
- Sensitive credentials

### Benefits:

1. **Faster Startup** - No need to re-authenticate every session
2. **Consistent Experience** - Always uses your preferred settings
3. **Team Friendly** - Each user has their own config file
4. **Secure** - No sensitive data stored
5. **Transparent** - Shows what's being loaded on startup

### Usage Tips:

1. **First Time Setup:**
   - Authenticate once (Option 1)
   - Select environment (Option 2)
   - Settings auto-save for next time

2. **Switching Environments:**
   - Just select a new environment
   - It automatically becomes the new default

3. **Multiple Profiles:**
   - Create different auth profiles for different tenants
   - Script remembers the last one used

4. **Clear Settings:**
   - Use Option 8 if you want to start fresh
   - Or manually delete `msapp-downloader-config.json`

### Troubleshooting:

**If saved settings don't load:**
- Check if `msapp-downloader-config.json` exists
- Verify PAC CLI auth profiles still exist: `pac auth list`
- Re-authenticate if profiles were deleted

**If environment selection fails:**
- The saved environment might no longer be accessible
- Select a new environment manually

**To disable auto-load:**
- Delete the config file before starting
- Or clear settings with Option 8

### File Locations:

- **Config File:** `./msapp-downloader-config.json` (same directory as script)
- **Downloads:** Configurable, saved in config
- **PAC Profiles:** Managed by PAC CLI (not in config file)