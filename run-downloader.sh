#!/bin/bash
# Launcher for Power Platform MSAPP Downloader

# Check if PowerShell is installed
if ! command -v pwsh &> /dev/null; then
    echo "❌ PowerShell Core is not installed."
    echo ""
    echo "To install PowerShell Core on Ubuntu/Debian:"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y powershell"
    echo ""
    echo "Or via snap:"
    echo "  sudo snap install powershell --classic"
    exit 1
fi

# Check if PAC CLI is installed
if [ ! -f "$HOME/bin/pac/tools/pac" ]; then
    echo "❌ PAC CLI not found at $HOME/bin/pac/tools/pac"
    echo "Please ensure PAC CLI is installed first."
    exit 1
fi

# Run the PowerShell script
echo "🚀 Starting Power Platform MSAPP Downloader..."
echo ""
pwsh ./download-msapps.ps1