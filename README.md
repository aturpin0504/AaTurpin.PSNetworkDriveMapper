# AaTurpin.PSNetworkDriveMapper

A PowerShell module for mapping network drives with credential management and validation. Provides secure credential handling and robust drive mapping functionality with comprehensive error handling and logging support.

## Features

- **Flexible Credential Management**: Supports multiple username formats with optional domain specification
- **Secure Password Handling**: Uses secure password prompting with automatic domain detection
- **Robust Drive Mapping**: Maps network drives with validation and error handling
- **Smart Remapping**: Automatically detects existing mappings and only remaps when necessary
- **Comprehensive Logging**: Integrates with AaTurpin.PSLogger for detailed operation logging
- **Enterprise Ready**: Designed for enterprise environments with proper validation and error handling

## Installation

First, register the NuGet repository if you haven't already:

```powershell
Register-PSRepository -Name "NuGet" -SourceLocation "https://api.nuget.org/v3/index.json" -PublishLocation "https://www.nuget.org/api/v2/package/" -InstallationPolicy Trusted
```

Then install the module:

```powershell
Install-Module -Name AaTurpin.PSNetworkDriveMapper -Repository NuGet -Scope CurrentUser
```

Or for all users (requires administrator privileges):

```powershell
Install-Module -Name AaTurpin.PSNetworkDriveMapper -Repository NuGet -Scope AllUsers
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
# Prompt for credentials with automatic domain detection
$credential = Get-UserCredential
# User can enter: "domain\username" or just "username" (uses current domain)

# Specify domain upfront for cleaner input
$credential = Get-UserCredential -Domain "corp"
# User only needs to enter: "username"
```

## Functions

### Get-UserCredential

Prompts the user for their username and password and creates a PSCredential object. Supports flexible username formats and optional domain specification.

**Syntax:**
```powershell
Get-UserCredential [[-Domain] <string>]
```

**Parameters:**
- `Domain`: Optional domain name. If provided, user only needs to enter username. If not provided, user can enter domain\username or just username (defaults to current domain).

**Returns:** `[System.Management.Automation.PSCredential]`

**Examples:**

**Basic usage (flexible format):**
```powershell
$credential = Get-UserCredential
# User can enter:
#   - "corp\jdoe" (domain\username)
#   - "jdoe" (uses current domain: USERDOMAIN\jdoe)
```

**With domain parameter:**
```powershell
$credential = Get-UserCredential -Domain "corp"
# User only enters: "jdoe"
# Result: "corp\jdoe"
```

**Enterprise scenario:**
```powershell
$credential = Get-UserCredential -Domain "company"
Write-Host "Username: $($credential.UserName)"
# Output: Username: company\jdoe
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
$credential = Get-UserCredential -Domain "corp"
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

# Get credentials once for all mappings
Write-Host "Enter credentials for network drive access:" -ForegroundColor Cyan
$credential = Get-UserCredential -Domain "corp"

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

### Domain-Specific Credential Scenarios

```powershell
# Scenario 1: Multiple domains
function Get-DomainCredentials {
    $credentials = @{}
    
    # Get credentials for different domains
    Write-Host "Setting up credentials for different domains..." -ForegroundColor Cyan
    
    $credentials["corp"] = Get-UserCredential -Domain "corp"
    $credentials["dev"] = Get-UserCredential -Domain "dev"
    
    return $credentials
}

# Usage
$domainCreds = Get-DomainCredentials()
Map-NetworkDrive -DriveLetter "V" -NetworkPath "\\corp.server\share" -LogPath $logPath -Credential $domainCreds["corp"]
Map-NetworkDrive -DriveLetter "W" -NetworkPath "\\dev.server\data" -LogPath $logPath -Credential $domainCreds["dev"]
```

```powershell
# Scenario 2: Interactive domain selection
function Get-InteractiveDomainCredential {
    $domains = @("corp", "dev", "prod", "test")
    
    Write-Host "Available domains:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $domains.Count; $i++) {
        Write-Host "  $($i + 1). $($domains[$i])" -ForegroundColor Gray
    }
    
    $choice = Read-Host "Select domain (1-$($domains.Count))"
    $selectedDomain = $domains[[int]$choice - 1]
    
    return Get-UserCredential -Domain $selectedDomain
}

# Usage
$credential = Get-InteractiveDomainCredential
```

### Validation and Error Handling

```powershell
# Comprehensive validation example
function Test-DriveMapping {
    param(
        [string]$DriveLetter,
        [string]$NetworkPath,
        [string]$LogPath,
        [string]$Domain
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
        
        # Get credentials with appropriate domain
        if ($Domain) {
            $credential = Get-UserCredential -Domain $Domain
        } else {
            $credential = Get-UserCredential
        }
        
        # Attempt mapping
        $result = Map-NetworkDrive -DriveLetter $DriveLetter -NetworkPath $NetworkPath -LogPath $LogPath -Credential $credential
        
        return $result
    }
    catch {
        Write-LogError -LogPath $LogPath -Message "Drive mapping validation failed" -Exception $_.Exception
        return $false
    }
}

# Usage
$success = Test-DriveMapping -DriveLetter "V" -NetworkPath "\\server\share" -LogPath "C:\Logs\validation.log" -Domain "corp"
```

## Integration with Other AaTurpin Modules

### Using with AaTurpin.PSConfig

```powershell
# Load configuration and map drives
Import-Module AaTurpin.PSConfig
Import-Module AaTurpin.PSNetworkDriveMapper

$logPath = "C:\Logs\config_mapping.log"
$config = Read-SettingsFile -LogPath $logPath

# Get credentials once for all drive mappings
Write-Host "Enter network credentials for drive mapping:" -ForegroundColor Cyan
$credential = Get-UserCredential -Domain "corp"

# Map drives from configuration
foreach ($driveMapping in $config.driveMappings) {
    $success = Map-NetworkDrive -DriveLetter $driveMapping.letter -NetworkPath $driveMapping.path -LogPath $logPath -Credential $credential
    
    if (-not $success) {
        Write-LogError -LogPath $logPath -Message "Failed to map configured drive: $($driveMapping.letter) -> $($driveMapping.path)"
    }
}
```

### Automated Setup Script

```powershell
# Complete automated setup matching your settings.json structure
Import-Module AaTurpin.PSConfig
Import-Module AaTurpin.PSNetworkDriveMapper

$logPath = "C:\Logs\automated_setup.log"

try {
    # Read configuration
    $config = Read-SettingsFile -LogPath $logPath
    
    # Get credentials for corporate domain
    Write-Host "Setting up network drives for corporate environment..." -ForegroundColor Cyan
    $credential = Get-UserCredential -Domain "corp"
    
    # Map drives from configuration
    foreach ($driveMapping in $config.driveMappings) {
        Write-Host "Mapping drive $($driveMapping.letter): $($driveMapping.path)" -ForegroundColor Yellow
        
        $success = Map-NetworkDrive -DriveLetter $driveMapping.letter -NetworkPath $driveMapping.path -LogPath $logPath -Credential $credential
        
        if ($success) {
            Write-Host "✓ Drive $($driveMapping.letter): successfully mapped" -ForegroundColor Green
        } else {
            Write-Host "✗ Drive $($driveMapping.letter): mapping failed" -ForegroundColor Red
        }
    }
    
    Write-Host "Drive mapping setup completed. Check logs at: $logPath" -ForegroundColor Cyan
}
catch {
    Write-LogError -LogPath $logPath -Message "Automated setup failed" -Exception $_.Exception
    Write-Host "Setup failed. Check logs for details: $logPath" -ForegroundColor Red
}
```

## Username Format Examples

The `Get-UserCredential` function supports various input formats:

### With Domain Parameter
```powershell
$cred = Get-UserCredential -Domain "corp"
# User enters: "jdoe"
# Result: "corp\jdoe"
```

### Without Domain Parameter
```powershell
$cred = Get-UserCredential
# User can enter any of:
#   1. "corp\jdoe" → Result: "corp\jdoe"
#   2. "jdoe" → Result: "CURRENTDOMAIN\jdoe" (uses $env:USERDOMAIN)
```

### Enterprise Domain Examples
```powershell
# Corporate domains
$cred = Get-UserCredential -Domain "corp"
$cred = Get-UserCredential -Domain "company"

# Other common enterprise formats
$cred = Get-UserCredential -Domain "dev"
$cred = Get-UserCredential -Domain "domain"
```

## Troubleshooting

### Common Issues

**Issue: "Access Denied" errors**
```powershell
# Solution: Ensure correct domain and credentials
$credential = Get-UserCredential -Domain "corp"
# Verify domain name is correct and user has access
```

**Issue: Wrong domain format**
```powershell
# Check current domain
Write-Host "Current domain: $env:USERDOMAIN"

# Use specific domain
$credential = Get-UserCredential -Domain $env:USERDOMAIN
```

**Issue: Username format confusion**
```powershell
# Clear format: specify domain parameter
$credential = Get-UserCredential -Domain "corp"
# Now user only enters username, no domain confusion
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

### Credential Testing

```powershell
# Test credential creation without mapping
function Test-CredentialFormats {
    Write-Host "Testing different credential input formats..." -ForegroundColor Cyan
    
    Write-Host "`n1. With domain parameter:" -ForegroundColor Yellow
    $cred1 = Get-UserCredential -Domain "corp"
    Write-Host "Result: $($cred1.UserName)" -ForegroundColor Green
    
    Write-Host "`n2. Without domain parameter:" -ForegroundColor Yellow
    $cred2 = Get-UserCredential
    Write-Host "Result: $($cred2.UserName)" -ForegroundColor Green
}

Test-CredentialFormats
```

## Security Considerations

- **Credential Storage**: Credentials are not stored permanently; they must be entered each session
- **Secure Input**: Passwords are entered securely and never displayed
- **Logging**: Passwords are never logged; only usernames and operation results are recorded
- **Domain Validation**: Input validation prevents domain injection attacks
- **Error Handling**: Detailed error information is logged without exposing sensitive data

## Performance Notes

- **Smart Mapping**: Only remaps drives when necessary, improving performance
- **Credential Reuse**: Get credentials once and reuse for multiple mappings
- **Domain Optimization**: Pre-specifying domain reduces user input complexity
- **Logging Efficiency**: Uses thread-safe logging from AaTurpin.PSLogger module

## Contributing

This module is part of the AaTurpin PowerShell module suite. For issues, feature requests, or contributions, please visit the project repository.

## License

This module is licensed under the MIT License. See the project repository for full license details.

## Version History

- **1.0.0**: Initial release with flexible credential management and robust drive mapping functionality

## Related Modules

- **AaTurpin.PSLogger**: Provides thread-safe logging capabilities
- **AaTurpin.PSConfig**: Configuration management for drive mappings
- **AaTurpin.PSPowerControl**: Power management during long operations
- **AaTurpin.PSSnapshotManager**: Network share snapshot and comparison tools

## Support

For support and documentation, visit the project repository or check the PowerShell Gallery page for this module.