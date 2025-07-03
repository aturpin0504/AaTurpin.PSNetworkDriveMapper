function Get-UserCredential {
    <#
    .SYNOPSIS
        Prompts the user for their password and creates a PSCredential object.

    .DESCRIPTION
        This cmdlet generates a PSCredential object using the current user's username and a password entered securely via the console. 
        The username is automatically set to "logon\$env:USERNAME".

    .OUTPUTS
        [System.Management.Automation.PSCredential]
        Returns a PSCredential object containing the username and password.

    .EXAMPLE
        $Credential = Get-UserCredential
        Write-Host "Username: $($Credential.UserName)"
        Write-Host "Password: $($Credential.GetNetworkCredential().Password)"
        Creates a credential object for the current user and displays the username and password.

    .NOTES
        This cmdlet is useful for scenarios where credentials are required for authentication, such as mapping network drives.

    .LINK
        https://learn.microsoft.com/en-us/powershell/scripting
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCredential])]
    param()

    # Define the username as logon\$env:USERNAME
    $Username = "logon\$env:USERNAME"

    # Prompt the user for their password
    $Password = Read-Host -AsSecureString "Enter your password"

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