function Get-UserCredential {
    <#
    .SYNOPSIS
        Prompts the user for their username and password and creates a PSCredential object.

    .DESCRIPTION
        This cmdlet generates a PSCredential object using a username and password entered by the user via the console. 
        The username can be provided in various formats including domain\username or just username.
        If a domain parameter is provided, only the username needs to be entered.
        If no domain is specified, the current user's domain will be used as default.

    .PARAMETER Domain
        Optional domain name to use for authentication. If provided, the user only needs to enter their username.
        If not provided, the user can enter domain\username or just username (defaulting to current domain).

    .OUTPUTS
        [System.Management.Automation.PSCredential]
        Returns a PSCredential object containing the username and password.

    .EXAMPLE
        $Credential = Get-UserCredential
        # User is prompted for username and password
        # Username examples: "corp\jdoe", "domain\username", or just "username"

    .EXAMPLE
        $Credential = Get-UserCredential -Domain "corp"
        # User only needs to enter username (e.g., "jdoe")
        # Final credential will be "corp\jdoe"

    .EXAMPLE
        $Credential = Get-UserCredential -Domain "corp"
        Write-Host "Username: $($Credential.UserName)"
        Creates a credential object with the specified domain.

    .NOTES
        This cmdlet is useful for scenarios where credentials are required for authentication, such as mapping network drives.
        
        Username format options:
        - With -Domain parameter: Enter just "username" 
        - Without -Domain parameter: Enter "domain\username" or "username" (uses current domain as default)

    .LINK
        https://learn.microsoft.com/en-us/powershell/scripting
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCredential])]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Domain
    )

    # Display format information to the user
    Write-Host "Enter your credentials for network authentication." -ForegroundColor Cyan
    
    if ($Domain) {
        Write-Host "Using domain: $Domain" -ForegroundColor Green
        Write-Host "Please enter just your username (without domain)." -ForegroundColor Yellow
    } else {
        Write-Host "Username format options:" -ForegroundColor Yellow
        Write-Host "  - With domain: domain\username (e.g., logon\jdoe)" -ForegroundColor Gray
        Write-Host "  - Without domain: username (will use '$env:USERDOMAIN' as default domain)" -ForegroundColor Gray
    }
    Write-Host ""

    # Prompt the user for their username
    if ($Domain) {
        $InputUsername = Read-Host "Enter username"
    } else {
        $InputUsername = Read-Host "Enter username"
    }
    
    # Validate username input
    if ([string]::IsNullOrWhiteSpace($InputUsername)) {
        Write-Host "Username cannot be empty." -ForegroundColor Red
        throw "Username cannot be empty."
    }

    # Process username based on domain parameter and input format
    if ($Domain) {
        # Domain parameter provided - use it with the username
        # Check if user accidentally included domain in username
        if ($InputUsername.Contains('\')) {
            Write-Host "Warning: Domain parameter provided but username contains '\'. Using domain parameter." -ForegroundColor Yellow
            $InputUsername = $InputUsername.Split('\')[-1]  # Take only the username part
        }
        $Username = "$Domain\$InputUsername"
    } elseif ($InputUsername.Contains('\')) {
        # No domain parameter but username contains domain
        $Username = $InputUsername
    } else {
        # No domain parameter and no domain in username - use current user's domain as default
        $Username = "$env:USERDOMAIN\$InputUsername"
        Write-Host "Using domain '$env:USERDOMAIN' for username: $Username" -ForegroundColor Yellow
    }

    # Prompt the user for their password
    $Password = Read-Host -AsSecureString "Enter password for $Username"

    # Convert the secure string to a PSCredential object
    try {
        $Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)
        Write-Host "Credential object created successfully for user: $Username" -ForegroundColor Green
        return $Credential
    } catch {
        Write-Host "Failed to create credential object: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Map-NetworkDrive {
    <#
    .SYNOPSIS
        Maps a network drive to a specified drive letter with validation and error handling.

    .DESCRIPTION
        This cmdlet maps a network drive to a specified drive letter using the `New-PSDrive` cmdlet. 
        It checks if the drive is already correctly mapped and only remaps if necessary.

    .PARAMETER DriveLetter
        The drive letter to map (single alphabetic character, e.g., "V", "X", "Z").

    .PARAMETER NetworkPath
        The UNC path to the network share (e.g., "\\server\share").

    .PARAMETER LogPath
        The path to the log file for recording operations using PSLogger.

    .PARAMETER Credential
        Optional. A PSCredential object for authentication when mapping the drive.

    .OUTPUTS
        [bool]
        Returns $true if the mapping was successful, $false otherwise.

    .EXAMPLE
        Map-NetworkDrive -DriveLetter "V" -NetworkPath "\\server\share" -LogPath "C:\Logs\drive.log"

    .EXAMPLE
        $Credential = Get-UserCredential
        Map-NetworkDrive -DriveLetter "X" -NetworkPath "\\nas\data" -LogPath "C:\Logs\drive.log" -Credential $Credential
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 1)]
        [ValidateScript({[char]::IsLetter($_)})]
        [string]$DriveLetter,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_.StartsWith("\\") -and $_.Length -gt 2})]
        [string]$NetworkPath,

        [Parameter(Mandatory = $true)]
        [string]$LogPath,

        [Parameter(Mandatory = $false)]
        [PSCredential]$Credential
    )

    $DriveLetter = $DriveLetter.ToUpper()
    Write-LogInfo -LogPath $LogPath -Message "Mapping drive '$DriveLetter' to '$NetworkPath'"
    
    try {
        # Check existing drive mapping
        $existingDrive = Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue
        
        if ($existingDrive -and $existingDrive.DisplayRoot -eq $NetworkPath) {
            Write-LogInfo -LogPath $LogPath -Message "Drive '$DriveLetter' already correctly mapped"
            return $true
        }
        
        # Remove existing drive if mapped to different location
        if ($existingDrive) {
            Write-LogInfo -LogPath $LogPath -Message "Remapping drive '$DriveLetter' from '$($existingDrive.DisplayRoot)'"
            Remove-PSDrive -Name $DriveLetter -Force -ErrorAction Stop
        }

        # Create mapping parameters
        $params = @{
            Name = $DriveLetter
            PSProvider = 'FileSystem'
            Root = $NetworkPath
            ErrorAction = 'Stop'
        }
        
        if ($Credential) { 
            $params.Credential = $Credential 
        }

        # Map the drive
        if ($PSCmdlet.ShouldProcess("Drive $DriveLetter", "Map to $NetworkPath")) {
            $null = New-PSDrive @params
            Write-LogInfo -LogPath $LogPath -Message "Successfully mapped drive '$DriveLetter'"
            Write-Host "Drive '$DriveLetter' mapped to '$NetworkPath'" -ForegroundColor Green
            return $true
        }
        
        return $false
    }
    catch {
        $errorMsg = "Failed to map drive '$DriveLetter': $($_.Exception.Message)"
        Write-LogError -LogPath $LogPath -Message $errorMsg -Exception $_.Exception
        Write-Host $errorMsg -ForegroundColor Red
        return $false
    }
}

Export-ModuleMember -Function Get-UserCredential, Map-NetworkDrive