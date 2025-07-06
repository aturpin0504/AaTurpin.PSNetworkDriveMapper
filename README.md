# AaTurpin.PSNetworkDriveMapper

A PowerShell module for mapping network drives with credential management and validation. Provides secure credential handling, robust drive mapping functionality, and batch drive mapping operations with comprehensive error handling and logging support.

## Features

- **Flexible Credential Management**: Supports multiple username formats with optional domain specification
- **Secure Password Handling**: Uses secure password prompting with automatic domain detection
- **Robust Drive Mapping**: Maps network drives with validation and error handling
- **Batch Drive Mapping**: Process multiple drive mappings with shared credential handling
- **Smart Remapping**: Automatically detects existing mappings and only remaps when necessary
- **Interactive Prompting**: User-friendly credential prompting with retry logic
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

### Batch Drive Mapping

```powershell
# Define multiple drive mappings
$driveMappings = @(
    @{ letter = "V"; path = "\\server\share1" },
    @{ letter = "W"; path = "\\server\share2" },
    @{ letter = "X"; path = "\\nas\data" }
)

# Map all drives with interactive credential prompting
Initialize-DriveMappings -DriveMappings $driveMappings -LogPath "C:\Logs\drive.log"
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

### Initialize-DriveMappings

Maps multiple network drives with optional credential prompting and shared credential handling.

**Syntax:**
```powershell
Initialize-DriveMappings [-DriveMappings] <array> [-LogPath] <string>
```

**Parameters:**
- `DriveMappings`: Array of drive mapping objects with 'letter' and 'path' properties
- `LogPath`: Path to the log file for recording operations

**Behavior:**
- Attempts to map each drive without credentials first
- Prompts for credentials on failures (once per session, reused for all drives)
- Throws an exception if any mappings fail after retry attempts
- Provides detailed console feedback and comprehensive logging

**Examples:**

**Basic batch mapping:**
```powershell
$mappings = @(
    @{ letter = "V"; path = "\\server\engineering" },
    @{ letter = "W"; path = "\\server\shared" },
    @{ letter = "X"; path = "\\nas\archives" }
)

Initialize-DriveMappings -DriveMappings $mappings -LogPath "C:\Logs\drive.log"
```

**With configuration from AaTurpin.PSConfig:**
```powershell
$settings = Read-SettingsFile -SettingsPath "settings.json" -LogPath $logPath
Initialize-DriveMappings -DriveMappings $settings.driveMappings -LogPath $logPath
```

**Error handling:**
```powershell
try {
    Initialize-DriveMappings -DriveMappings $mappings -LogPath $logPath
    Write-Host "All drives mapped successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Drive mapping failed: $($_.Exception.Message)" -ForegroundColor Red
    # Handle the error (e.g., exit, retry, etc.)
    exit 1
}
```

## Advanced Usage

### Enterprise Deployment Script

```powershell
# Enterprise drive mapping script with error handling
Import-Module AaTurpin.PSNetworkDriveMapper
Import-Module AaTurpin.PSLogger

$logPath = "C:\Logs\$(Get-Date -Format 'yyyy-MM-dd')_drive_mapping.log"

# Define enterprise drive mappings
$enterpriseMappings = @(
    @{ letter = "V"; path = "\\server01\engineering" },
    @{ letter = "W"; path = "\\server02\shared" },
    @{ letter = "X"; path = "\\nas01\archives" },
    @{ letter = "Y"; path = "\\backup\daily" }
)

Write-LogInfo -LogPath $logPath -Message "Starting enterprise drive mapping process"

try {
    # Use batch mapping with automatic credential handling
    Initialize-DriveMappings -DriveMappings $enterpriseMappings -LogPath $logPath
    
    Write-Host "✓ All enterprise drives mapped successfully!" -ForegroundColor Green
    Write-LogInfo -LogPath $logPath -Message "Enterprise drive mapping completed successfully"
}
catch {
    Write-LogError -LogPath $logPath -Message "Enterprise drive mapping failed" -Exception $_.Exception
    Write-Host "✗ Enterprise drive mapping failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Graceful degradation or exit
    Read-Host "Press Enter to exit"
    exit 1
}
```

### Mixed Individual and Batch Mapping

```powershell
# Combine individual and batch mapping approaches
Import-Module AaTurpin.PSNetworkDriveMapper

$logPath = "C:\Logs\mixed_mapping.log"

# Map critical drives individually with specific error handling
try {
    Write-Host "Mapping critical drive V:..." -ForegroundColor Yellow
    $credential = Get-UserCredential -Domain "corp"
    $success = Map-NetworkDrive -DriveLetter "V" -NetworkPath "\\critical\data" -LogPath $logPath -Credential $credential
    
    if (-not $success) {
        throw "Critical drive V: mapping failed"
    }
    
    Write-Host "✓ Critical drive V: mapped successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ Critical drive mapping failed, cannot continue" -ForegroundColor Red
    exit 1
}

# Map additional drives in batch
$additionalMappings = @(
    @{ letter = "W"; path = "\\server\shared" },
    @{ letter = "X"; path = "\\nas\backup" },
    @{ letter = "Y"; path = "\\archive\old" }
)

try {
    Write-Host "`nMapping additional drives..." -ForegroundColor Yellow
    Initialize-DriveMappings -DriveMappings $additionalMappings -LogPath $logPath
    Write-Host "✓ Additional drives mapped successfully" -ForegroundColor Green
}
catch {
    Write-Host "⚠ Some additional drives failed to map, but continuing with critical drive available" -ForegroundColor Yellow
    Write-LogWarning -LogPath $logPath -Message "Additional drive mapping partially failed: $($_.Exception.Message)"
}
```

### Integration with Configuration Files

```powershell
# Load configuration and use batch mapping
Import-Module AaTurpin.PSConfig
Import-Module AaTurpin.PSNetworkDriveMapper

$logPath = "C:\Logs\config_mapping.log"

try {
    # Read configuration file
    $config = Read-SettingsFile -SettingsPath "settings.json" -LogPath $logPath
    
    if ($config.driveMappings.Count -eq 0) {
        Write-Host "No drive mappings configured in settings.json" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "Found $($config.driveMappings.Count) drive mappings in configuration" -ForegroundColor Cyan
    
    # Use batch mapping for all configured drives
    Initialize-DriveMappings -DriveMappings $config.driveMappings -LogPath $logPath
    
    Write-Host "✓ All configured drives mapped successfully!" -ForegroundColor Green
}
catch {
    Write-LogError -LogPath $logPath -Message "Configuration-based drive mapping failed" -Exception $_.Exception
    Write-Host "✗ Drive mapping failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
```

### Custom Credential Scenarios

```powershell
# Different domains for different drives
function Initialize-MultiDomainDrives {
    param(
        [array]$CorporateDrives,
        [array]$DevelopmentDrives,
        [string]$LogPath
    )
    
    try {
        # Map corporate drives
        if ($CorporateDrives.Count -gt 0) {
            Write-Host "Mapping corporate drives..." -ForegroundColor Cyan
            Initialize-DriveMappings -DriveMappings $CorporateDrives -LogPath $LogPath
        }
        
        # Map development drives (may need different credentials)
        if ($DevelopmentDrives.Count -gt 0) {
            Write-Host "`nMapping development drives..." -ForegroundColor Cyan
            Initialize-DriveMappings -DriveMappings $DevelopmentDrives -LogPath $LogPath
        }
        
        Write-Host "✓ All multi-domain drives mapped successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Multi-domain drive mapping failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Usage
$corpDrives = @(
    @{ letter = "V"; path = "\\corp-server\shared" },
    @{ letter = "W"; path = "\\corp-nas\data" }
)

$devDrives = @(
    @{ letter = "X"; path = "\\dev-server\projects" },
    @{ letter = "Y"; path = "\\dev-nas\builds" }
)

Initialize-MultiDomainDrives -CorporateDrives $corpDrives -DevelopmentDrives $devDrives -LogPath "C:\Logs\multi_domain.log"
```

## Integration with Other AaTurpin Modules

### Using with AaTurpin.PSConfig

```powershell
# Streamlined configuration-based setup
Import-Module AaTurpin.PSConfig
Import-Module AaTurpin.PSNetworkDriveMapper

$logPath = "C:\Logs\config_setup.log"

# Read configuration and initialize drives in one step
$config = Read-SettingsFile -SettingsPath "settings.json" -LogPath $logPath
Initialize-DriveMappings -DriveMappings $config.driveMappings -LogPath $logPath
```

### Complete Automated Setup Script

```powershell
# Complete automated setup with comprehensive error handling
Import-Module AaTurpin.PSConfig
Import-Module AaTurpin.PSNetworkDriveMapper
Import-Module AaTurpin.PSPowerControl

$logPath = "C:\Logs\automated_setup.log"

try {
    Write-LogInfo -LogPath $logPath -Message "Starting automated network drive setup"
    
    # Prevent system sleep during setup
    Disable-Sleep -LogPath $logPath
    
    # Read configuration
    Write-Host "Reading configuration..." -ForegroundColor Cyan
    $config = Read-SettingsFile -SettingsPath "settings.json" -LogPath $logPath
    
    # Initialize all drive mappings with batch processing
    Write-Host "Initializing drive mappings..." -ForegroundColor Cyan
    Initialize-DriveMappings -DriveMappings $config.driveMappings -LogPath $logPath
    
    Write-Host "✓ Automated setup completed successfully!" -ForegroundColor Green
    Write-LogInfo -LogPath $logPath -Message "Automated setup completed successfully"
}
catch {
    Write-LogError -LogPath $logPath -Message "Automated setup failed" -Exception $_.Exception
    Write-Host "✗ Setup failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    # Re-enable system sleep
    Enable-Sleep -LogPath $logPath
}
```

## Batch Mapping Benefits

The new `Initialize-DriveMappings` function provides several advantages over individual mapping:

### Credential Efficiency
- **Single Credential Prompt**: Get credentials once, use for all drives
- **Smart Retry Logic**: Prompts only when needed, not for every drive
- **User-Friendly**: Clear prompts with easy yes/no decisions

### Error Handling
- **Comprehensive Logging**: Detailed logs for each mapping attempt
- **Aggregate Reporting**: See all successes and failures at once
- **Fail-Fast Behavior**: Stops immediately if any mapping fails (configurable)

### Enterprise Features
- **Batch Processing**: Handle dozens of drives efficiently
- **Configuration Integration**: Works seamlessly with AaTurpin.PSConfig
- **Automated Deployment**: Perfect for login scripts and automation

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

**Issue: "Access Denied" errors during batch mapping**
```powershell
# Solution: Ensure correct domain and credentials
# The batch function will prompt for credentials automatically
# Make sure the domain name is correct when prompted
```

**Issue: Some drives map, others fail**
```powershell
# The Initialize-DriveMappings function will show exactly which drives failed
# Check the logs for detailed error information per drive
Get-Content "C:\Logs\drive.log" | Select-String "ERROR"
```

**Issue: Batch mapping stops on first failure**
```powershell
# This is by design for reliability
# If you need to continue with partial failures, use individual Map-NetworkDrive calls
```

**Issue: Credential prompt appears multiple times**
```powershell
# This happens when initial mapping without credentials fails
# The function will ask once if you want to provide credentials
# Answer 'Y' to provide credentials that will be used for all subsequent drives
```

**Issue: Wrong domain format**
```powershell
# Check current domain
Write-Host "Current domain: $env:USERDOMAIN"

# Use specific domain
$credential = Get-UserCredential -Domain $env:USERDOMAIN
```

**Issue: Network path not accessible**
```powershell
# Test connectivity first
Test-Path "\\server\share" -ErrorAction SilentlyContinue

# Check network connectivity
Test-NetConnection server -Port 445  # SMB port
```

### Debug Mode

Enable verbose logging for troubleshooting:

```powershell
# Enable verbose output
$VerbosePreference = "Continue"

# Use batch mapping with detailed logging
Initialize-DriveMappings -DriveMappings $mappings -LogPath "C:\Logs\debug.log" -Verbose

# Check detailed logs
Get-Content "C:\Logs\debug.log" | Select-Object -Last 20
```

### Testing Batch Mapping

```powershell
# Test batch mapping with a small set first
function Test-BatchMapping {
    $testMappings = @(
        @{ letter = "T"; path = "\\server\test1" },
        @{ letter = "U"; path = "\\server\test2" }
    )
    
    try {
        Initialize-DriveMappings -DriveMappings $testMappings -LogPath "C:\Logs\test.log"
        Write-Host "✓ Batch mapping test successful" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Batch mapping test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Run test before production mapping
if (Test-BatchMapping) {
    # Proceed with full mapping
    Initialize-DriveMappings -DriveMappings $productionMappings -LogPath $logPath
}
```

## Security Considerations

- **Credential Storage**: Credentials are not stored permanently; they must be entered each session
- **Secure Input**: Passwords are entered securely and never displayed
- **Batch Security**: In batch mode, credentials are reused in memory only for the duration of the operation
- **Logging**: Passwords are never logged; only usernames and operation results are recorded
- **Domain Validation**: Input validation prevents domain injection attacks
- **Error Handling**: Detailed error information is logged without exposing sensitive data

## Performance Notes

- **Batch Efficiency**: `Initialize-DriveMappings` is significantly faster than individual mappings for multiple drives
- **Smart Mapping**: Only remaps drives when necessary, improving performance
- **Credential Reuse**: Get credentials once and reuse for multiple mappings in batch mode
- **Domain Optimization**: Pre-specifying domain reduces user input complexity
- **Logging Efficiency**: Uses thread-safe logging from AaTurpin.PSLogger module

## Contributing

This module is part of the AaTurpin PowerShell module suite. For issues, feature requests, or contributions, please visit the project repository.

## License

This module is licensed under the MIT License. See the project repository for full license details.

## Version History

- **1.1.0**: Added Initialize-DriveMappings function for batch drive mapping operations with shared credential handling and comprehensive error reporting
- **1.0.0**: Initial release with flexible credential management and robust drive mapping functionality

## Related Modules

- **AaTurpin.PSLogger**: Provides thread-safe logging capabilities
- **AaTurpin.PSConfig**: Configuration management for drive mappings
- **AaTurpin.PSPowerControl**: Power management during long operations
- **AaTurpin.PSSnapshotManager**: Network share snapshot and comparison tools

## Support

For support and documentation, visit the project repository or check the PowerShell Gallery page for this module.