# AaTurpin.PSNetworkDriveMapper

A PowerShell module for mapping network drives with credential management and validation. Provides secure credential handling and robust drive mapping functionality with comprehensive error handling and logging support.

## Features

- **Secure Credential Management**: Automatically handles user credentials with secure password prompting
- **Robust Drive Mapping**: Maps network drives with validation and error handling
- **Smart Remapping**: Automatically detects existing mappings and only remaps when necessary
- **Comprehensive Logging**: Integrates with AaTurpin.PSLogger for detailed operation logging
- **Enterprise Ready**: Designed for enterprise environments with proper validation and error handling

## Installation

Install the module from the PowerShell Gallery:

```powershell
Install-Module -Name AaTurpin.PSNetworkDriveMapper -Scope CurrentUser
```

Or for all users (requires admin privileges):

```powershell
Install-Module -Name AaTurpin.PSNetworkDriveMapper -Scope AllUsers
```

## Prerequisites

- **PowerShell 5.1** or later
- **AaTurpin.PSLogger** module (automatically installed as a dependency)
- Windows operating system

## Quick Start

### Basic Drive Mapping

```powershell
# Import the module
Import-Module AaTurpin.PSNetworkDriveMapper

# Map a network drive without credentials (uses current user context)
Map-NetworkDrive -DriveLetter "V" -NetworkPath "\\server\share" -LogPath "C:\Logs\drive.log"

# Map a network drive with credentials
$credential = Get-UserCredential
Map-NetworkDrive -DriveLetter "X" -NetworkPath "\\nas\data" -LogPath "C:\Logs\drive.log" -Credential $credential
```

### Getting User Credentials

```powershell
# Prompt for credentials using current username
$credential = Get-UserCredential
# This will prompt: "Enter your password" and create credentials for "logon\[current_username]"
```

## Functions

### Get-UserCredential

Prompts the user for their password and creates a PSCredential object using the current user's username in the format "logon\$env:USERNAME".

**Syntax:**
```powershell
Get-UserCredential
```

**Returns:** `[System.Management.Automation.PSCredential]`

**Example:**
```powershell
$credential = Get-UserCredential
Write-Host "Username: $($credential.UserName)"
# Output: Username: logon\johndoe
```

### Map-NetworkDrive

Maps a network drive to a specified drive letter with validation and error handling.

**Syntax:**
```powershell
Map-NetworkDrive [-DriveLetter] <string> [-NetworkPath] <string> [-LogPath] <string> [[-Credential] <PSCredential>] [-WhatIf] [-Confirm]
```

**Parameters:**
- `DriveLetter`: Single alphabetic character (e.g., "V", "X", "Z")
- `NetworkPath`: UNC path to the network share (e.g., "\\server\share")
- `LogPath`: Path to the log file for recording operations
- `Credential`: Optional PSCredential object for authentication

**Returns:** `[bool]` - True if mapping was successful, false otherwise

**Examples:**
```powershell
# Map without credentials
$success = Map-NetworkDrive -DriveLetter "V" -NetworkPath "\\server\share" -LogPath "C:\Logs\drive.log"

# Map with credentials
$credential = Get-UserCredential
$success = Map-NetworkDrive -DriveLetter "X" -NetworkPath "\\nas\data" -LogPath "C:\Logs\drive.log" -Credential $credential

# Test what would happen without actually mapping
Map-NetworkDrive -DriveLetter "Y" -NetworkPath "\\server\test" -LogPath "C:\Logs\drive.log" -WhatIf
```

## Advanced Usage

### Enterprise Deployment Script

```powershell
# Enterprise drive mapping script
Import-Module AaTurpin.PSNetworkDriveMapper
Import-Module AaTurpin.PSLogger

$logPath = "C:\Logs\$(Get-Date -Format 'yyyy-MM-dd')_drive_mapping.log"
$credential = Get-UserCredential

# Define drive mappings
$driveMappings = @(
    @{ Letter = "V"; Path = "\\server01\engineering" },
    @{ Letter = "W"; Path = "\\server02\shared" },
    @{ Letter = "X"; Path = "\\nas01\archives" }
)

Write-LogInfo -LogPath $logPath -Message "Starting enterprise drive mapping process"

foreach ($mapping in $driveMappings) {
    try {
        $success = Map-NetworkDrive -DriveLetter $mapping.Letter -NetworkPath $mapping.Path -LogPath $logPath -Credential $credential
        
        if ($success) {
            Write-Host "✓ Successfully mapped drive $($mapping.Letter): $($mapping.Path)" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to map drive $($mapping.Letter): $($mapping.Path)" -ForegroundColor Red
        }
    }
    catch {
        Write-LogError -LogPath $logPath -Message "Critical error mapping drive $($mapping.Letter)" -Exception $_.Exception
        Write-Host "✗ Critical error mapping drive $($mapping.Letter): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-LogInfo -LogPath $logPath -Message "Enterprise drive mapping process completed"
```

### Validation and Error Handling

```powershell
# Comprehensive validation example
function Test-DriveMapping {
    param(
        [string]$DriveLetter,
        [string]$NetworkPath,
        [string]$LogPath
    )
    
    try {
        # Validate parameters
        if (-not [char]::IsLetter($DriveLetter) -or $DriveLetter.Length -ne 1) {
            throw "Invalid drive letter: must be a single alphabetic character"
        }
        
        if (-not $NetworkPath.StartsWith("\\")) {
            throw "Invalid network path: must be a UNC path starting with \\"
        }
        
        # Test network connectivity
        if (-not (Test-Path $NetworkPath -ErrorAction SilentlyContinue)) {
            Write-LogWarning -LogPath $LogPath -Message "Network path may not be accessible: $NetworkPath"
        }
        
        # Attempt mapping
        $credential = Get-UserCredential
        $result = Map-NetworkDrive -DriveLetter $DriveLetter -NetworkPath $NetworkPath -LogPath $LogPath -Credential $credential
        
        return $result
    }
    catch {
        Write-LogError -LogPath $LogPath -Message "Drive mapping validation failed" -Exception $_.Exception
        return $false
    }
}

# Usage
$success = Test-DriveMapping -DriveLetter "V" -NetworkPath "\\server\share" -LogPath "C:\Logs\validation.log"
```

## Integration with Other AaTurpin Modules

### Using with AaTurpin.PSConfig

```powershell
# Load configuration and map drives
Import-Module AaTurpin.PSConfig
Import-Module AaTurpin.PSNetworkDriveMapper

$logPath = "C:\Logs\config_mapping.log"
$config = Read-SettingsFile -LogPath $logPath
$credential = Get-UserCredential

# Map drives from configuration
foreach ($driveMapping in $config.driveMappings) {
    $success = Map-NetworkDrive -DriveLetter $driveMapping.letter -NetworkPath $driveMapping.path -LogPath $logPath -Credential $credential
    
    if (-not $success) {
        Write-LogError -LogPath $logPath -Message "Failed to map configured drive: $($driveMapping.letter) -> $($driveMapping.path)"
    }
}
```

## Troubleshooting

### Common Issues

**Issue: "Access Denied" errors**
```powershell
# Solution: Ensure credentials are correct and user has access
$credential = Get-UserCredential
# Enter correct password when prompted
```

**Issue: Drive already mapped to different location**
```powershell
# The module automatically handles this by removing existing mapping first
# Check logs for details about remapping operations
```

**Issue: Network path not accessible**
```powershell
# Test connectivity first
Test-Path "\\server\share" -ErrorAction SilentlyContinue

# Check network connectivity
Test-NetConnection server -Port 445  # SMB port
```

**Issue: PowerShell execution policy**
```powershell
# Set execution policy to allow module execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Debug Mode

Enable verbose logging for troubleshooting:

```powershell
# Enable verbose output
$VerbosePreference = "Continue"

# Map drive with detailed logging
Map-NetworkDrive -DriveLetter "V" -NetworkPath "\\server\share" -LogPath "C:\Logs\debug.log" -Verbose

# Check detailed logs
Get-Content "C:\Logs\debug.log" | Select-Object -Last 20
```

## Security Considerations

- **Credential Storage**: Credentials are not stored permanently; they must be entered each session
- **Logging**: Passwords are never logged; only usernames and operation results are recorded
- **Validation**: All input parameters are validated to prevent injection attacks
- **Error Handling**: Detailed error information is logged without exposing sensitive data

## Performance Notes

- **Smart Mapping**: Only remaps drives when necessary, improving performance
- **Credential Reuse**: Get credentials once and reuse for multiple mappings
- **Logging Efficiency**: Uses thread-safe logging from AaTurpin.PSLogger module

## Contributing

This module is part of the AaTurpin PowerShell module suite. For issues, feature requests, or contributions, please visit the project repository.

## License

This module is licensed under the MIT License. See the project repository for full license details.

## Version History

- **1.0.0**: Initial release with core network drive mapping functionality

## Related Modules

- **AaTurpin.PSLogger**: Provides thread-safe logging capabilities
- **AaTurpin.PSConfig**: Configuration management for drive mappings
- **AaTurpin.PSPowerControl**: Power management during long operations

## Support

For support and documentation, visit the project repository or check the PowerShell Gallery page for this module.