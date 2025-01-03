<#
.SYNOPSIS
Install & configure the Starship shell.
https://starship.rs

.DESCRIPTION
Install & configure Starship & its dependencies. Installs the FiraCode NerdFont by default.

.PARAMETER Debug
Enable debug logging.

.PARAMETER DryRun
Simulate the script and print the commands that would be executed.

.PARAMETER PkgInstaller
The package manager to use.

.PARAMETER StarshipProfile
The Starship profile to use. This should be the name of a .toml file in the repository's configs/ directory. You do not need to include the .toml extension.
If not specified, the _default profile will be used.

.PARAMETER NerdFont
The name of the NerdFont to install. Defaults to FiraMono, installed with the Scoop package manager (scoop must be installed).

.PARAMETER Overwrite
Overwrite the Starship config file if it already exists.

.PARAMETER ShowProfiles
Print available profiles and exit.

.PARAMETER SwitchProfile
Switch to the specified Starship profile. Skips all installations & prompts user for profile name instead

.PARAMETER Help
Print help menu

.EXAMPLE
.\install-starship.ps1 -DryRun -Debug -PkgInstaller scoop
#>
Param(
    [switch]$Debug,
    [switch]$Verbose,
    [switch]$DryRun,
    [switch]$Overwrite,
    [string]$PkgInstaller = "winget",
    [string]$StarshipProfile = "_default",
    [string]$NerdFont = "FiraMono",
    [switch]$ShowProfiles,
    [switch]$SwitchProfile,
    [switch]$Help
)

## Enable debug logging if -Debug is passed
If ( $Debug ) {
    $DebugPreference = "Continue"
}

## Enable verbose logging if -Verbose is passed
If ( $Verbose ) {
    $VerbosePreference = "Continue"

    Write-Verbose "[ Verbose Mode ] Verbose logging enabled. Additional logging will print.`n"
}

###########
# Globals #
###########

## Set location to path where script was launched from
$CWD = "$($PWD)"
Write-Verbose "Script launched from path: $($CWD)"

## Get the full path of the script being executed
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
## Get the parent directory of the script directory
$THIS_DIR = Split-Path -Parent $ScriptDirectory

Write-Verbose "Script parent: $($ScriptDirectory)"
Write-Verbose "Script location: $($THIS_DIR)"

## Set path to repository root
$REPO_ROOT = Split-Path -Parent $THIS_DIR
Write-Verbose "Repository root: $($REPO_ROOT)"

## Set path to user's $HOME
$UserHome = "$($env:USERPROFILE)"
Write-Verbose "User home path: $($UserHome)"

## Path to .config
$DotConfigDir = "$($UserHome)\.config"
Write-Verbose ".config path: $($DotConfigDir) [exists: $( Test-Path -Path $DotConfigDir )]"

## Path to Starship configs/ directory
$StarshipRepoConfigDir = "$($CWD)\configs"
Write-Verbose "Starship configs path: $($StarshipRepoConfigDir)"

## Path to $HOME/.config/starship.toml
$StarshipTomlFile = "$($DotConfigDir)\starship.toml"
Write-Verbose "Starship config path: $($StarshipTomlFile) [exists: $( Test-Path -Path $StarshipTomlFile )]"

## Valid package managers
$ValidPackageManagers = @("winget", "choco", "scoop")

## Supported NerdFonts and their package names for scoop & choco
$ValidNerdFonts = @"
{
    "FiraMono": {
        "scoop": "FiraMono-NF",
        "choco": "nerd-font-FiraMono"
    },
    "FiraCode": {
        "scoop": "FiraCode-NF",
        "choco": "nerd-font-FiraCode"
    },
    "HackMono": {
        "scoop": "Hack-NF-Mono",
        "choco": "nerdfont-hack"
    },
    "IosevkaTerm": {
        "scoop": "IosevkaTerm-NF-Mono",
        "choco": "nerd-fonts-IosevkaTerm"
    },
    "UbuntuMono": {
        "scoop": "UbuntuMono-NF-Mono",
        "choco": "nerd-fonts-UbuntuMono"
    }
}
"@

## Load fonts JSON data
$FontsJson = $ValidNerdFonts | ConvertFrom-Json
if ( $Debug ) {
    Write-Debug "NerdFont JSON data:"
    $FontsJson | Format-List

    Write-Debug "FontsJson Keys: $($FontsJson.PSObject.Properties.Name -join ', ')"
}

#############
# Functions #
#############

function Show-Help() {
    Write-Host "`n`t[ Starship Installer | Help ]`n" -ForegroundColor Green
    
    Write-Host "[ Usage ]" -ForegroundColor Cyan
    Write-Host "$ .\install-starship.ps1" -NoNewline ; Write-Host " [options]`n" -ForegroundColor Magenta

    Write-Host "[Options]" -ForegroundColor Magenta
    Write-Host "-Debug" -ForegroundColor Magenta -NoNewline ; Write-Host ": Enable debug logging."
    Write-Host "-DryRun" -ForegroundColor Magenta -NoNewline ; Write-Host " Simulate the script and print the commands that would be executed."
    Write-Host "-Verbose" -ForegroundColor Magenta -NoNewline ; Write-Host " Enable verbose logging."
    Write-Host "-Overwrite" -ForegroundColor Magenta -NoNewline ; Write-Host " Overwrite the Starship config file if it already exists."
    Write-Host "-ShowProfiles" -ForegroundColor Magenta -NoNewline ; Write-Host " Print available profiles and exit."
    Write-Host "-SwitchProfile" -ForegroundColor Magenta -NoNewline ; Write-Host " Switch to a different Starship profile."

    Write-Host "`n[ Examples ]" -ForegroundColor DarkYellow
    Write-Host "$ .\install-starship.ps1" -ForegroundColor Yellow -NoNewline ; Write-Host " -DryRun -Debug" -ForegroundColor Magenta -NoNewline ; Write-Host "  # Print commands that would have been executed, with debug logging enabled" -ForegroundColor DarkGreen
    Write-Host "$ .\install-starship.ps1" -ForegroundColor Yellow  -NoNewline ; Write-Host " -ShowProfiles" -ForegroundColor Magenta -NoNewline ; Write-Host "  # Print available profiles" -ForegroundColor DarkGreen
    Write-Host "$ .\install-starship.ps1" -ForegroundColor Yellow -NoNewline ; Write-Host " -SwitchProfile -StarshipProfile" -ForegroundColor Magenta -NoNewline ; Write-Host " minimal" -ForegroundColor Blue -NoNewline ; Write-Host "  # Will use the ./configs/minimal.toml file" -ForegroundColor DarkGreen
}

Function Test-IsAdministrator {
    <#
    .SYNOPSIS
    Check if the current user is an administrator.
    #>

    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
    Write-Verbose "Command '$Command' exists: $CmdExists."

    return $CmdExists
}

function Test-ValidPackageManager() {
    Param(
        [Parameter(Mandatory = $true)]
        $PkgManager
    )

    ## Return $True/$False if $PkgManager is in $ValidPackageManagers
    return $ValidPackageManagers -contains $PkgManager
}

function Test-ScoopPackageExists() {
    <#
    .SYNOPSIS
    Check if a Scoop package exists.

    .PARAMETER PackageName
    The name of the package to check.

    .EXAMPLE
    Test-ScoopPackageExists -PackageName "starship"
    #>
    Param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    if ( -Not $PackageName ) {
        Write-Error "Cannot test if Scoop package exists, package name is `$null/empty."
        exit 1
    }

    if ( scoop list | Select-String -Pattern "$PackageName" ) {
        Write-Debug "Scoop package '$PackageName' is installed."
        return $true
    }
    else {
        Write-Debug "Scoop package '$PackageName' is not installed."
        return $false
    }
}

function Test-ChocoPackageExists() {
    <#
    .SYNOPSIS
    Check if a Chocolatey package exists.

    .PARAMETER PackageName
    The name of the package to check.

    .EXAMPLE
    Test-ChocoPackageExists -PackageName "starship"
    #>
    Param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )
    if (choco list --local-only | Select-String -Pattern "$PackageName") {
        Write-Host "Chocolatey package '$PackageName' is installed."
    }
    else {
        Write-Host "Chocolatey package '$PackageName' is not installed."
    }
}

function Invoke-ElevatedCommand {
    param (
        [string]$Command
    )

    # Check if the script is running as admin
    $isAdmin = [bool](New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        # Prompt to run as administrator if not already running as admin
        $arguments = "-Command `"& {$command}`""
        Write-Debug "Running command: Start-Process powershell -ArgumentList $($arguments) -Verb RunAs"

        try {
            Start-Process powershell -ArgumentList $arguments -Verb RunAs
            return $true  # Indicate that the script was elevated and the command will run
        }
        catch {
            Write-Error "Error executing command as admin. Details: $($_.Exception.Message)"
        }
    }
    else {
        # If already running as admin, execute the command
        Invoke-Expression $command
        return $false  # Indicate that the command was run without elevation
    }
}

function Show-StarshipProfiles {
    Param (
        [string]$DirectoryPath = "$($REPO_ROOT)/configs"
    )

    ## Check if Starship configs directory can be found in repo
    if ( -not ( Test-Path -Path $DirectoryPath -PathType Container ) ) {
        Write-Error "Could not find Starship configs directory at path: '$DirectoryPath'"
        exit 1
    }

    ## Get all .toml files in the directory
    $TomlFiles = Get-ChildItem -Path $DirectoryPath -Filter *.toml -File

    if ($TomlFiles.Count -eq 0) {
        Write-Error "No Starship profile .toml files found in '$DirectoryPath'."
        exit 1
    }

    ## Display the list of .toml files
    Write-Host "`n [ Available Starship Profiles ]`n" -ForegroundColor Cyan
    $TomlFiles | ForEach-Object {
        ## Remove the .toml extension from the filename before displaying
        $ProfileName = $_.BaseName
        Write-Host "- $ProfileName" -ForegroundColor Green
    }

    Write-Host "`n[USAGE] Re-run the script with -StarshipProfile <profile-name>,
where <profile-name> is one from the list above,
or omit the -StarshipProfile parameter to use the _default profile." -ForegroundColor Cyan
    exit 0
}

function Select-StarshipProfileFromList {
    ## Define the path to the configs directory
    $ConfigDir = "$($REPO_ROOT)/configs"

    ## Get all .toml files in the configs directory
    $tomlFiles = Get-ChildItem -Path $ConfigDir -Filter *.toml

    if ($tomlFiles.Count -eq 0) {
        Write-Host "No .toml files found in the 'configs' directory." -ForegroundColor Red
        return
    }

    ## Display a numbered list to the user with the .toml extension omitted
    $tomlFiles | ForEach-Object {
        $profileName = $_.BaseName  # Get the file name without extension
        Write-Host "$($tomlFiles.IndexOf($_) + 1). $profileName"
    }

    ## Ask the user to select a profile
    try{
        $selection = Read-Host "Select a profile by number (press Enter for default)"
    } catch {
        Write-Error "Failed to read user input. Details: $($_.Exception.Message)"
        exit 1
    }

    ## If no selection is made (Enter is pressed), default to "_default"
    if ($selection -eq "") {
        $selection = "_default"
        Write-Host "No selection made. Defaulting to profile: $selection"
    }

    ## Validate user input if a number was entered
    if ($selection -ne "_default") {
        ## Validate user input
        if ( $selection -lt 1 -or $selection -gt $tomlFiles.Count ) {
            Write-Host "Invalid selection, please try again." -ForegroundColor Red
            return
        }

        ## Get the selected file, remove extension from the selected file name
        $selectedProfile = $tomlFiles[$selection - 1].BaseName
    }

    return $selectedProfile
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

    If ( -Not ( Test-CommandExists "$($PkgManager)" ) ) {
        Write-Error "Package manager '$($PkgManager)' is not installed."
        exit 1
    }

    ## Test if Starship is already installed.
    $StarshipInstalled = Test-CommandExists "starship"
    Write-Debug "Starship installed: $StarshipInstalled."

    If ( $StarshipInstalled ) {
        Write-Host "Starship is already installed." -ForegroundColor Cyan
        return
    }

    Write-Host "Installing Starship with $PkgManager..." -ForegroundColor Cyan
    switch ($PkgInstaller) {

        "scoop" {

            ## Install Starship with Scoop.
            try {
                scoop install starship
                return
            }
            catch {
                Write-Error "Failed to install Starship with Scoop."
                return $false
            }
        }

        "choco" {
            ## Install Starship with Chocolatey.
            try {
                choco install starship -y
                return
            }
            catch {
                Write-Error "Failed to install Starship with Chocolatey."
                return $false
            }
        }

        "winget" {
            ## Install Starship with Winget.
            try {
                winget install -e --id Starship.Starship
                return
            }
            catch {
                Write-Error "Failed to install Starship with Winget."
                return $false
            }
        }

        default { Write-Error "Unknown package manager: $PkgInstaller" ; exit 1 }
    }
}

function Start-NerdFontInstall() {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$PkgManager,
        [string]$FontName = "FiraMono"
    )

    If ( $DryRun ) {
        Write-Host "[DryRun] Would have installed a Nerd Font with $( if ($PkgManager -eq "winget") {"scoop"} else { $PkgManager })." -ForegroundColor Magenta
        return
    }

    if ( $PkgManager -eq "winget" ) {
        Write-Warning "Installing NerdFonts with winget is not supported. Setting package manager to 'scoop'. If scoop is not installed, script will exit."
        $PkgManager = "scoop"
    }

    Write-Debug "NerdFont: '$($FontName)', package manager: $PkgManager"

    If ( -Not ( Test-CommandExists "$($PkgManager)" ) ) {
        Write-Error "Package manager '$($PkgManager)' is not installed."
        exit 1
    }

    switch ($PkgManager) {

        "scoop" {
            Write-Debug "Using scoop package manager"

            ## Test if nerdfont is already installed.
            $NerdFontInstalled = Test-ScoopPackageExists -PackageName $FontName
            Write-Debug "NerdFont '$($FontName)' installed: $NerdFontInstalled."

            If ( $NerdFontInstalled ) {
                Write-Host "NerdFont '$($FontName)' is already installed." -ForegroundColor Cyan
                return
            }

            ## Check if the FontName exists in the JSON data
            if ( -not $FontsJson.PSObject.Properties.Name -contains $FontName ) {
                Write-Error "Font '$FontName' not found in the mapping."
                return $null
            }

            ## Retrieve font object from JSON
            $FontDetails = $FontsJson.$FontName
            Write-Debug "NerdFont '$($FontName)' details: $FontDetails."

            Write-Host "Installing NerdFont '$($FontName)' with scoop" -ForegroundColor Cyan

            ## Install NerdFont with Scoop.
            try {
                scoop install $FontDetails.scoop
                return
            }
            catch {
                Write-Error "Failed to install Starship with Scoop."
                return $false
            }
        }

        "choco" {
            Write-Debug "Using chocolatey package manager"

            ## Test if nerdfont is already installed.
            $NerdFontInstalled = Test-ChocoPackageExists -PackageName $FontName
            Write-Debug "NerdFont '$($FontName)' installed: $NerdFontInstalled."

            If ( $NerdFontInstalled ) {
                Write-Host "NerdFont '$($FontName)' is already installed." -ForegroundColor Cyan
                return
            }

            ## Check if the FontName exists in the JSON data
            if ( -not $FontsJson.PSObject.Properties.Name -contains $FontName ) {
                Write-Error "Font '$FontName' not found in the mapping."
                return $null
            }

            ## Retrieve font object from JSON
            $FontDetails = $FontsJson.$FontName
            Write-Debug "NerdFont '$($FontName)' details: $FontDetails."

            Write-Host "Installing NerdFont '$($FontName)' with chocolatey" -ForegroundColor Cyan

            ## Install NerdFont with Chocolatey.
            try {
                choco install $fontDetails.choco -y
                return
            }
            catch {
                Write-Error "Failed to install NerdFont with Chocolatey."
                return $false
            }
        }

        "winget" {
            Write-Error "NerdFonts are not available for install with winget. Use scoop or chocolatey."
            exit 1
        }

        default { Write-Error "Unknown package manager: $PkgInstaller" ; exit 1 }
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
        ## $PROFILE does not exist, do not try to read
        Write-Warning "The Powershell profile does not exist at path: $PROFILE."
        $ProfileContent = $null
    }
    else {
        ## $PROFILE exists
        Write-Host "Reading Powershell profile from: $($PROFILE)" -ForegroundColor Cyan

        ## Read $PROFILE contents into variable
        try {
            $ProfileContent = Get-Content -Path $PROFILE -ErrorAction SilentlyContinue
            Write-Verbose "Loaded `$PROFILE contents from path: $($PROFILE)"
        }
        catch {
            Write-Error "Failed to read the Powershell profile at path: $PROFILE. Details: $($_.Exception.Message)"
            exit 1
        }
    }

    If ( -Not $ProfileExists ) {
        ## Set $InitLineExists to false because $PROFILE does not exist
        $InitLineExists = $false
        Write-Warning "Could not search `$PROFILE for Starship init line because `$PROFILE does not exist yet."
    }
    else {
        ## Check for the Starship init line in the $PROFILE
        $InitLineExists = $ProfileContent -match "Invoke-Expression\s+\(\&starship\s+init\s+powershell\)"

        If ( $null -ne $InitLineExists ) {
            ## Starship init line is in file
            Write-Host "Starship initialization found in `$PROFILE." -ForegroundColor Cyan
            If ( -Not $DryRun ) {
                ## Return immediately on DryRun
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

    If (-Not (Test-Path -Path $PROFILE)) {
        ## $PROFILE does not exist, initialize empty $PROFILE
        Write-Warning "PowerShell profile does not exist. Creating a new profile..."
        try {
            New-Item -Path $PROFILE -ItemType File -Force
        }
        catch {
            Write-Error "Failed to create a new Powershell profile. Details: $($_.Exception.Message)"
            exit 1
        }
    }

    If (-Not $InitLineExists) {
        ## Starship init line does not exist in $PROFILE, add it
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

function Select-StarshipProfile {
    <#
    .SYNOPSIS
    Select Starship profile from the configs directory.

    .DESCRIPTION
    Select a Starship profile .toml file matching the name of the profile passed to the script. If a matching
    profile is not found, the script will exit.

    .EXAMPLE
    Select-StarshipProfile -StarshipProfile "minimal"
    #>
    Param(
        [Parameter(Mandatory = $true)]
        [string]$StarshipTomlFile
    )

    ## Set path to Starship TOML profile
    $StarshipProfilePath = "$($StarshipRepoConfigDir)\$($StarshipProfile).toml"

    If ( -Not ( Test-Path -Path $StarshipProfilePath ) ) {
        ## Starship profile does not exist
        Write-Error "Starship profile does not exist at path: $StarshipProfilePath"
        return $false
    }

    ## Matching Starship profile found, return profile
    return $StarshipProfilePath
}

function New-StarshipProfileSymlink {
    <#
    .SYNOPSIS
    Create a symlink to the selected Starship profile.

    .DESCRIPTION
    Create a symlink to the selected Starship profile in the user's home directory.

    .EXAMPLE
    New-StarshipProfileSymlink -StarshipProfile "minimal"
    #>
    Param(
        [Parameter(Mandatory = $true)]
        [string]$StarshipProfile,
        [switch]$Overwrite = $true
    )

    If ( $DryRun ) {
        Write-Host "[DryRun] Would have created a symlink to Starship profile: $StarshipProfile" -ForegroundColor Magenta
        return
    }
    else {
        ## Check if the starship config already exists
        If ( Test-Path $StarshipTomlFile ) {
            ## Get details about the existing file
            $Item = Get-Item $StarshipTomlFile

            ## Check if the path is a junction/symlink
            If ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                Write-Host "Path is already a junction or symlink: $StarshipTomlFile" -ForegroundColor Cyan
                if ( -Not $Overwrite ) {
                    return
                }
                else {
                    Write-Warning "-Overwrite parameter detected. Removing existing junction to create new one."
                    try {
                        ## Remove existing junction if it exists and -Overwrite is passed to the script
                        Remove-Item -Path $StarshipTomlFile -Force
                    }
                    catch {
                        Write-Error "Failed to remove existing junction at path: $StarshipTomlFile. Details: $($_.Exception.Message)"
                        exit 1
                    }
                }
            }
            else {

                ## Path is a regular file
                Write-Warning "Path already exists: $StarshipTomlFile. Moving to $StarshipTomlFile.bak"
                If (Test-Path "$StarshipTomlFile.bak") {
                    ## Remove existing starship.toml backup
                    Write-Warning "$StarshipTomlFile.bak already exists. Overwriting backup."
                    Remove-Item "$StarshipTomlFile.bak" -Force
                }

                try {
                    ## Move existing starship.toml file to a backup to starship.toml
                }
                catch {
                    Write-Error "Error moving $StarshipTomlFile to $StarshipTomlFile.bak. Details: $($_.Exception.Message)"
                    exit 1
                }
            }
        }
    }

    ## Set expression to symlink config
    $SymlinkExpression = "New-Item -ItemType SymbolicLink -Path $StarshipTomlFile -Target $StarshipProfile"

    Write-Host "Creating symlink from $StarshipProfile -> $StarshipTomlFile" -ForegroundColor Cyan

    If ( -Not ( Test-IsAdministrator ) ) {
        Write-Warning "Script was not run as administrator. Running symlink command as administrator."

        try {
            Invoke-ElevatedCommand -Command "$($SymlinkExpression)" | Out-Null
        }
        catch {
            Write-Error "Error creating symlink from $StarshipProfile to $StarshipTomlFile. Details: $($_.Exception.Message)"
        }
    }
    else {
        try {
            Invoke-Expression $SymlinkCommand
        }
        catch {
            Write-Error "Error creating symlink from $StarshipProfile to $StarshipTomlFile. Details: $($_.Exception.Message)"
            exit 1
        }
    }
}

function Switch-StarshipProfile() {
    Param(
        [string]$StarshipProfile = $StarshipProfile
    )

    Write-Debug "-SwitchProfile parameter detected, skipping execution & just switching profile"

    Write-Debug "`$StarshipProfile=$StarshipProfile"
    if ( ( $null -eq $StarshipProfile ) -or ( $StarshipProfile -eq "" ) ) {
        Write-Host "No Starship profile specified with -StarshipProfile parameter.
Please select one from the list, or hit Enter to use the _default profile.`n" -ForegroundColor Cyan

        try {
            $SelectedProfile = Select-StarshipProfileFromList
            Write-Debug "Selected Starship profile: $SelectedProfile"
        } catch {
            Write-Error "Failed to select Starship profile. Details: $($_.Exception.Message)"
            exit 1
        }

        if ( ( $null -eq $SelectedProfile ) ) {
            Write-Debug "No profile selected. Using _default profile."
            $SelectedProfile = "_default"
        }

        $StarshipProfile = $SelectedProfile

        Write-Host "Using profile: $StarshipProfile" -ForegroundColor Green
    }

    Write-Host "Selecting Starship profile '$StarshipProfile' from configs directory" -ForegroundColor Cyan
    ## Set path to Starship TOML profile
    $StarshipProfile = Select-StarshipProfile -StarshipTomlFile $StarshipTomlFile
    Write-Host "Selected Starship profile: $StarshipProfile" -ForegroundColor Cyan

    ## Do symlinking in Switch-StarshipProfile when -SwitchProfile is used
    if ( $SwitchProfile ) { 
        Write-Host "`n[ Configure | Starship profile symlink ]`n" -ForegroundColor Green

        ## Create Starship profile symlink
        try {
            New-StarshipProfileSymlink -StarshipProfile "$($REPO_ROOT)/configs/$StarshipProfile.toml"
        }
        catch {
            Write-Error "Failed to create symlink to Starship profile. Details: $($_.Exception.Message)"
            exit 1
        }

        Write-Host "Switched Starship profile to $StarshipProfile" -ForegroundColor Green
        exit 0
    }
}

##############
# Entrypoint #
##############

function main {
    ## If -Help detected, skip execution & print help menu
    If ( $Help ) {
        Write-Debug "-Help parameter detected, show help & exit"
        Show-Help
        exit 0
    }

    ## If -ShowProfiles detected, skip execution and just print profiles
    If ( $ShowProfiles ) {
        Write-Debug "-ShowProfiles parameter detected, show available profiles & exit"
        Show-StarshipProfiles
        exit 0
    }

    ## If -SwitchProfile detected, skip portions of execution to just switch profile
    If ( $SwitchProfile ) {
        Write-Host "`n[ Configure | Starship profile selection ]`n" -ForegroundColor Green
        Switch-StarshipProfile -StarshipProfile $StarshipProfile
        exit 0
    }

    If ( $DryRun  ) {
        Write-Verbose "[DryRun] Skipping check for existing Starship profile. On executions without -DryRun, script exist immediately if an existing configuration is detected and no -Overwrite parameter was passed."
    }
    else {
        If ( Test-Path -Path $StarshipTomlFile ) {
            Write-Warning "Existing Starship profile detected."

            If ( -Not $Overwrite ) {
                ## If existing starship.toml detected, and -Overwrite was not passed, exit immediately
                Write-Warning "Script will exit. If you want to continue even when an existing Starship configuration is detected, run the script with -Overwrite."
                exit 0
            }
        }
    }

    If ( -Not ( Test-ValidPackageManager $PkgInstaller) ) {
        Write-Error "Invalid package manager: '$PkgInstaller'. Must be one of: $ValidPackageManagers"
        exit 1
    }

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

    Write-Host "[ Install | Starship ]`n" -ForegroundColor Green
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

    Write-Host "`n[ Install | NerdFont ]`n" -ForegroundColor Green
    ## Install NerdFont
    try {
        Start-NerdFontInstall -PkgManager $PkgInstaller -FontName $NerdFont
    }
    catch {
        Write-Error "Error installing NerdFont. Details: $($_.Exception.Message)"
        exit 1
    }

    Write-Host "`n[ Configure | Starship profile selection ]`n" -ForegroundColor Green
    Switch-StarshipProfile -StarshipProfile $StarshipProfile

    Write-Host "`n[ Configure | Starship profile symlink ]`n" -ForegroundColor Green
    ## Create Starship profile symlink
    try {
        New-StarshipProfileSymlink -StarshipProfile "$($REPO_ROOT)/configs/$StarshipProfile.toml"
    }
    catch {
        Write-Error "Failed to create symlink to Starship profile. Details: $($_.Exception.Message)"
        exit 1
    }

    Write-Host "`n[ Configure | Starship init line in Powershell `$PROFILE ]`n" -ForegroundColor Green
    ## Add Starship init to Powershell $PROFILE
    Set-StarshipInPSProfile
}

try {
    main
    Write-Host "`n[SUCCESS] Starship installed & profile configured." -ForegroundColor Green
}
catch {
    Write-Error "Starship setup script failed. Details: $($_.Exception.Message)"
    exit 1
}
