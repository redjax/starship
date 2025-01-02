<#
.SYNOPSIS
Install & configure the Starship shell.
https://starship.rs

.DESCRIPTION
...

.PARAMETER Debug
Enable debug logging.

.PARAMETER DryRun
Simulate the script and print the commands that would be executed.

.PARAMETER PkgInstaller
The package manager to use.

.EXAMPLE
.\install-starship.ps1 -DryRun -Debug -PkgInstaller scoop
#>
Param(
    [switch]$Debug,
    [switch]$DryRun,
    [string]$PkgInstaller = "winget"   
)

## Enable debug logging if -Debug is passed
If ( $Debug ) {
    $DebugPreference = "Continue"
}

function Test-CommandExists {
    <#
    .SYNOPSIS
    Check if a command exists/executes.

    .PARAMETER Command
    The command to check.

    .EXAMPLE
    Test-CommandExists "winget"
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    $CmdExists = ($null -ne (Get-Command $Command -ErrorAction SilentlyContinue))
    Write-Debug "Command '$Command' exists: $CmdExists."

    return $CmdExists
}

function Install-StarshipScoop {
    <#
    .SYNOPSIS
    Install Starship with Scoop.
    https://scoop.sh
    #>

    If ( $DryRun ) {
        Write-Host "[DryRun] Would have installed Starship with Scoop." -ForegroundColor Magenta
        return
    }

    If ( -Not (Test-CommandExists "scoop") ) {
        Write-Error "Scoop is not installed."
        exit 1
    }

    ## Test if Starship is already installed.
    $StarshipInstalled = Test-CommandExists "starship"
    Write-Debug "Starship installed: $StarshipInstalled."

    If ( $StarshipInstalled ) {
        Write-Host "Starship is already installed." -ForegroundColor Yellow
        return
    }

    ## Install Starship with Scoop.
    Write-Host "Installing Starship with Scoop..." -ForegroundColor Cyan

    try {
        scoop install starship
        return
    }
    catch {
        Write-Error "Failed to install Starship with Scoop."
        return $false
    }
}

function Install-StarshipChocolatey {
    <#
    .SYNOPSIS
    Install Starship with Chocolatey.
    https://chocolatey.org
    #>

    If ( $DryRun ) {
        Write-Host "[DryRun] Would have installed Starship with Chocolatey." -ForegroundColor Magenta
        return
    }

    If ( -Not (Test-CommandExists "choco") ) {
        Write-Error "Chocolatey is not installed."
        exit 1
    }

    ## Test if Starship is already installed.
    $StarshipInstalled = Test-CommandExists "starship"
    Write-Debug "Starship installed: $StarshipInstalled."

    If ( $StarshipInstalled ) {
        Write-Host "Starship is already installed." -ForegroundColor Yellow
        return
    }

    ## Install Starship with Chocolatey.
    Write-Host "Installing Starship with Chocolatey..." -ForegroundColor Cyan

    try {
        choco install starship -y
        return
    }
    catch {
        Write-Error "Failed to install Starship with Chocolatey."
        return $false
    }
}

function Install-StarshipWinget {
    <#
    .SYNOPSIS 
    Install Starship with Winget.
    https://github.com/microsoft/winget-cli
    #>

    If ( $DryRun ) {
        Write-Host "[DryRun] Would have installed Starship with Winget." -ForegroundColor Magenta
        return
    }

    If ( -Not (Test-CommandExists "winget") ) {
        Write-Error "Winget is not installed."
        exit 1
    }

    ## Test if Starship is already installed.
    $StarshipInstalled = Test-CommandExists "starship"
    Write-Debug "Starship installed: $StarshipInstalled."

    If ( $StarshipInstalled ) {
        Write-Host "Starship is already installed." -ForegroundColor Yellow
        return
    }

    ## Install Starship with Winget.
    Write-Host "Installing Starship with Winget..." -ForegroundColor Cyan

    try {
        winget install -e --id Starship.Starship
        return
    }
    catch {
        Write-Error "Failed to install Starship with Winget."
        return $false
    }
}

function Start-StarshipInstall {
    <#
    .SYNOPSIS
    Install Starship with the specified package manager.

    .PARAMETER PkgManager
    The package manager to install Starship with.

    .EXAMPLE
    ## With winget
    Start-StarshipInstall -PkgManager winget

    ## With scoop
    Start-StarshipInstall -PkgManager scoop

    ## With choco
    Start-StarshipInstall -PkgManager choco
    #>
    Param(
        [Parameter(Mandatory = $true)]
        [string]$PkgManager
    )

    If ( $DryRun ) {
        Write-Host "[DryRun] Would have installed Starship with $PkgManager." -ForegroundColor Magenta
        return
    }

    Write-Host "Installing Starship with $PkgManager..." -ForegroundColor Cyan
    If ( $PkgManager -eq "scoop" ) {
        Install-StarshipScoop
    }
    elseif ( $PkgManager -eq "choco" ) {
        Install-StarshipChocolatey
    }
    elseif ( $PkgManager -eq "winget" ) {
        Install-StarshipWinget
    }
    else {
        Write-Error "Unknown package manager: $PkgManager"
        exit 1
    }
}

function Set-StarshipInPSProfile {
    <#
    .SYNOPSIS
    Set Starship as the shell in the PowerShell profile.

    .DESCRIPTION
    Searches the Powershell $PROFILE for this line:
        Invoke-Expression (&starship init powershell)
    
    If it does not exist, appends it to the end of the $PROFILE to launch
    Starship on Powershell init.

    .EXAMPLE
    Set-StarshipInPSProfile
    #>

    ## Check if Powershell $PROFILE exists
    $ProfileExists = ( Test-Path -Path $PROFILE )
    Write-Debug "Profile '$PROFILE' exists: $ProfileExists."

    ## Define the Starship initialization block
    $StarshipInitBlock = @"

## Initialize Starship shell
If ( Get-Command starship ) {
  try {
    Invoke-Expression (&starship init powershell)
  } catch {
    ## Show error when verbose logging is enabled
    #  Write-Verbose "The 'starship' command was not found. Skipping initialization." -Verbose
  }
}
"@

    If ( -Not $ProfileExists ) {
        Write-Warning "The Powershell profile does not exist at path: $PROFILE."
        $ProfileContent = $null
    }
    else {
        Write-Host "Reading Powershell profile from: $($PROFILE)" -ForegroundColor Cyan
        ## Read $PROFILE contents into variable
        try {
            $ProfileContent = Get-Content -Path $PROFILE -ErrorAction SilentlyContinue
            Write-Debug "Loaded `$PROFILE contents"
        }
        catch {
            Write-Error "Failed to read the Powershell profile at path: $PROFILE. Details: $($_.Exception.Message)"
            exit 1
        }
    }

    If ( -Not $ProfileExists ) {
        $InitLineExists = $false
        Write-Warning "Could not search `$PROFILE for Starship init line because `$PROFILE does not exist yet."
    }
    else {
        ## Check for the Starship init line
        $InitLineExists = $ProfileContent -match "Invoke-Expression\s+\(\&starship\s+init\s+powershell\)"

        If ( $null -ne $InitLineExists ) {
            Write-Host "`nStarship initialization found in `$PROFILE." -ForegroundColor Cyan
            If ( -Not $DryRun ) {
                return
            }
        }
        else {
            Write-Warning "`nStarship initialization not found in `$PROFILE. It will be added."
        }
    }

    If ( $DryRun ) {
        $ProfilePath = $PROFILE
        $ProfileExists = ( Test-Path $ProfilePath )

        Write-Host @"

[DryRun]
`$PROFILE path: $( If ( $null -eq $PROFILE) { "| `$PROFILE path could not be determined. Script would most likely error."} else { "$($PROFILE)"})
`$PROFILE exists: $ProfileExists $(If ( -Not $ProfileExists ) { "| A new Powershell profile would be initialized." } )
Found Starship init line in `$PROFILE: $InitLineExists $( If ( -Not $InitLineExists ) { "| Starship init line would be added to Powershell profile." } )

"@ -ForegroundColor Magenta

        return
    }

    If (-Not $InitLineExists) {
        Write-Host "`nAdding Starship initialization to the PowerShell profile..." -ForegroundColor Cyan
        try {
            Add-Content -Path $PROFILE -Value $StarshipInitBlock
            Write-Host "Starship initialization added to the PowerShell profile." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to add Starship initialization to the PowerShell profile."
            exit 1
        }
    }
}

function main {
    Write-Host @"

    [ Starship shell setup script | Package Manager: $($PkgInstaller) ]
    
    Script will install & configure Starship & its dependencies.
    $('-' * 60)

"@ -ForegroundColor Green
    
    ## Show dry run message when -DryRun is passed
    If ( $DryRun ) {
        Write-Host @"
    [ Dry Run Enabled ]
    DryRun is enabled. No actions that would modify the system will occur.
    
    Instead, a message describing what would have happened will print.
    The message will look like:
        '[DryRun] Would have <action> [optional extra info]'

"@ -ForegroundColor Magenta
    }

    ## Show message when debugging is enabled
    If ( $Debug ) {
        Write-Host @"
    [ Debug Mode Enabled ]
    Debug mode is enabled. Debug messages will print.

"@ -ForegroundColor Yellow
    }

    Write-Host "[ Install ]`n" -ForegroundColor Green
    ## Install Starship if not installed
    If ( -Not (Test-CommandExists "starship") ) {
        try {
            Start-StarshipInstall -PkgManager $PkgInstaller
        }
        catch {
            Write-Error "Failed to install Starship."
            exit 1
        }
    }
    else {
        Write-Host "Starship is already installed." -ForegroundColor Cyan
    }

    Write-Host "`n[ Configure ]`n" -ForegroundColor Green
    ## Add Starship init to Powershell $PROFILE
    Set-StarshipInPSProfile
}


main