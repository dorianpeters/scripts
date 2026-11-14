#Requires -Version 5.1
<#
.SYNOPSIS
  Cross-Platform Development Environment Setup (Windows / PowerShell)
.DESCRIPTION
  Windows equivalent of dev_setup.sh. Standardizes tool and runtime management
  using winget and mise.
#>

$ErrorActionPreference = "Stop"

Write-Host "=================================================="
Write-Host "  Windows Development Environment Setup"
Write-Host "=================================================="

# --------------------------------------------------
# OS & Environment Verification
# --------------------------------------------------
$IsWin = ($env:OS -eq "Windows_NT") -or ([System.Environment]::OSVersion.Platform -eq "Win32NT")
if (-not $IsWin) {
    Write-Error "This script is intended for Windows. On Linux or macOS, run ./dev_setup.sh instead."
    exit 1
}

$IsInteractive = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected

# Helper to check if a command exists in PATH
function Test-CommandExists {
    param([Parameter(Mandatory = $true)][string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Helper to refresh PATH in the current PowerShell session from Machine + User registry and standard tool dirs
function Update-SessionPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $combined = @($userPath, $machinePath) -join ";"

    $extraPaths = @(
        (Join-Path $env:LOCALAPPDATA "mise\shims"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"),
        (Join-Path $env:ProgramFiles "Git\cmd"),
        (Join-Path $env:LOCALAPPDATA "Programs\Git\cmd"),
        (Join-Path $env:LOCALAPPDATA "agy\bin"),
        (Join-Path $env:USERPROFILE ".local\bin")
    )

    $pathSet = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
    $finalPaths = New-Object System.Collections.Generic.List[string]

    foreach ($p in ($extraPaths + ($combined -split ";"))) {
        if (-not [string]::IsNullOrWhiteSpace($p)) {
            $trimmed = $p.Trim()
            if ($pathSet.Add($trimmed)) {
                $finalPaths.Add($trimmed)
            }
        }
    }

    $env:PATH = $finalPaths -join ";"
}

# Helper to run external commands and get the first line of output safely
function Get-ToolVersion {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string[]]$Arguments = @("--version"),
        [string]$Fallback = "Not installed"
    )
    if (-not (Test-CommandExists $Command)) {
        return $Fallback
    }
    try {
        $output = & $Command @Arguments 2>$null | Select-Object -First 1
        if (-not [string]::IsNullOrWhiteSpace($output)) {
            return $output.ToString().Trim()
        }
        return $Fallback
    } catch {
        return $Fallback
    }
}

Write-Host "Detected OS: Windows ($([System.Environment]::OSVersion.VersionString))"

if (-not (Test-CommandExists "winget")) {
    Write-Error "winget (Windows Package Manager) was not found. Please install 'App Installer' from the Microsoft Store or https://aka.ms/getwinget and re-run this script."
    exit 1
}

# --------------------------------------------------
# Install Minimal System Dependencies (winget)
# --------------------------------------------------
Write-Host "--------------------------------------------------"
Write-Host "Ensuring system packages via winget (Git, mise, btop4win)"
Write-Host "--------------------------------------------------"

$WingetPackages = @(
    @{ Command = "git";  Id = "Git.Git";               Name = "Git" },
    @{ Command = "mise"; Id = "jdx.mise";              Name = "mise" },
    @{ Command = "btop"; Id = "aristocratos.btop4win"; Name = "btop4win" }
)

foreach ($pkg in $WingetPackages) {
    if (-not (Test-CommandExists $pkg.Command)) {
        Write-Host "Installing $($pkg.Name) ($($pkg.Id)) via winget..."
        winget install --id $pkg.Id -e --accept-source-agreements --accept-package-agreements
        Update-SessionPath
    } else {
        Write-Host "$($pkg.Name) is already installed."
    }
}

Update-SessionPath

# --------------------------------------------------
# mise Verification & PowerShell Profile Configuration
# --------------------------------------------------
Write-Host "--------------------------------------------------"
Write-Host "Checking mise (tool manager)"
Write-Host "--------------------------------------------------"

if (-not (Test-CommandExists "mise")) {
    Write-Error "Error: mise installation failed or is not found in PATH. Try restarting your PowerShell terminal and running this script again."
    exit 1
}

Write-Host "mise version: $(Get-ToolVersion -Command 'mise')"

$PwshActivateLine = '(&mise activate pwsh) | Out-String | Invoke-Expression'
$DocumentsDir = [Environment]::GetFolderPath("MyDocuments")
$ProfilePaths = @(
    $PROFILE
)
if (-not [string]::IsNullOrWhiteSpace($DocumentsDir)) {
    $ProfilePaths += @(
        (Join-Path $DocumentsDir "PowerShell\Microsoft.PowerShell_profile.ps1"),
        (Join-Path $DocumentsDir "WindowsPowerShell\Microsoft.PowerShell_profile.ps1")
    )
}

$UniqueProfiles = $ProfilePaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

foreach ($profPath in $UniqueProfiles) {
    $profDir = Split-Path -Parent $profPath
    if (-not (Test-Path $profDir)) {
        New-Item -ItemType Directory -Path $profDir -Force | Out-Null
    }
    if (-not (Test-Path $profPath)) {
        New-Item -ItemType File -Path $profPath -Force | Out-Null
    }
    $content = Get-Content -Path $profPath -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content) -or ($content -notmatch "mise activate pwsh")) {
        Add-Content -Path $profPath -Value "`n# mise tool manager`n$PwshActivateLine"
        Write-Host "Added mise activation to $profPath"
    }
}

# --------------------------------------------------
# Configure mise Settings
# --------------------------------------------------
Write-Host "--------------------------------------------------"
Write-Host "Configuring mise settings"
Write-Host "--------------------------------------------------"

mise settings set upgrade.auto_prune true
mise settings set yes true
mise settings set all_compile false

Write-Host "mise settings configured: upgrade.auto_prune=true, yes=true, all_compile=false"

# --------------------------------------------------
# Install Developer Tools via mise
# --------------------------------------------------
Write-Host "--------------------------------------------------"
Write-Host "Installing tools via mise"
Write-Host "--------------------------------------------------"

$Tools = @(
    "node@lts",
    "pnpm",
    "aube",
    "uv",
    "gh",
    "eza",
    "fastfetch",
    "bottom"
)

Write-Host "Installing globally: $($Tools -join ' ')"
mise use -g @Tools
mise install

Update-SessionPath

# --------------------------------------------------
# Git Configuration
# --------------------------------------------------
Write-Host "--------------------------------------------------"
Write-Host "Configuring Git"
Write-Host "--------------------------------------------------"

# Priority order:
# 1. Pre-existing environment variables (GIT_NAME / GIT_EMAIL or GIT_AUTHOR_*)
# 2. Local or home .dev_setup.env configuration file
# 3. Existing global git configuration
# 4. Interactive prompt (if running in an interactive session)

$GitName = if ($env:GIT_NAME) { $env:GIT_NAME } else { $env:GIT_AUTHOR_NAME }
$GitEmail = if ($env:GIT_EMAIL) { $env:GIT_EMAIL } else { $env:GIT_AUTHOR_EMAIL }

function Import-DevSetupEnv {
    param([Parameter(Mandatory = $true)][string]$EnvFilePath)
    foreach ($line in (Get-Content -Path $EnvFilePath -ErrorAction SilentlyContinue)) {
        $trimmed = $line.Trim()
        if ($trimmed -eq "" -or $trimmed.StartsWith("#")) { continue }
        if ($trimmed -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            $key = $matches[1]
            $val = $matches[2].Trim()
            if (($val.StartsWith('"') -and $val.EndsWith('"')) -or ($val.StartsWith("'") -and $val.EndsWith("'"))) {
                $val = $val.Substring(1, $val.Length - 2)
            }
            if ($key -eq "GIT_NAME" -and [string]::IsNullOrWhiteSpace($script:GitName)) {
                $script:GitName = $val
            } elseif ($key -eq "GIT_EMAIL" -and [string]::IsNullOrWhiteSpace($script:GitEmail)) {
                $script:GitEmail = $val
            } elseif ($key -eq "GIT_AUTHOR_NAME" -and [string]::IsNullOrWhiteSpace($script:GitName)) {
                $script:GitName = $val
            } elseif ($key -eq "GIT_AUTHOR_EMAIL" -and [string]::IsNullOrWhiteSpace($script:GitEmail)) {
                $script:GitEmail = $val
            }
        }
    }
}

$LoadedFromEnv = $false
$LocalEnvFile = Join-Path $PWD ".dev_setup.env"
$HomeEnvFile = Join-Path $env:USERPROFILE ".dev_setup.env"

if ([string]::IsNullOrWhiteSpace($GitName) -or [string]::IsNullOrWhiteSpace($GitEmail)) {
    if (Test-Path $LocalEnvFile) {
        Write-Host "Loading configuration from $LocalEnvFile"
        Import-DevSetupEnv -EnvFilePath $LocalEnvFile
        $LoadedFromEnv = $true
    } elseif (Test-Path $HomeEnvFile) {
        Write-Host "Loading configuration from $HomeEnvFile"
        Import-DevSetupEnv -EnvFilePath $HomeEnvFile
        $LoadedFromEnv = $true
    }
}

if ([string]::IsNullOrWhiteSpace($GitName) -and (Test-CommandExists "git")) {
    try {
        $existingName = git config --global user.name 2>$null
        if (-not [string]::IsNullOrWhiteSpace($existingName)) {
            $GitName = $existingName.Trim()
        }
    } catch {}
}

if ([string]::IsNullOrWhiteSpace($GitEmail) -and (Test-CommandExists "git")) {
    try {
        $existingEmail = git config --global user.email 2>$null
        if (-not [string]::IsNullOrWhiteSpace($existingEmail)) {
            $GitEmail = $existingEmail.Trim()
        }
    } catch {}
}

if ($IsInteractive) {
    if ([string]::IsNullOrWhiteSpace($GitName)) {
        $GitName = Read-Host "Enter your Git user name"
    }
    if ([string]::IsNullOrWhiteSpace($GitEmail)) {
        $GitEmail = Read-Host "Enter your Git user email"
    }

    if (-not [string]::IsNullOrWhiteSpace($GitName) -and -not [string]::IsNullOrWhiteSpace($GitEmail) -and -not $LoadedFromEnv) {
        $saveEnv = Read-Host "Save these details to ~/.dev_setup.env for future runs? [y/N]"
        if ($saveEnv -match '^[yY]([eE][sS])?$') {
            $envContent = @(
                "GIT_NAME=`"$GitName`"",
                "GIT_EMAIL=`"$GitEmail`""
            ) -join "`n"
            Set-Content -Path $HomeEnvFile -Value $envContent -Encoding UTF8
            Write-Host "Saved configuration to $HomeEnvFile"
        }
    }
}

if (-not [string]::IsNullOrWhiteSpace($GitName)) {
    git config --global user.name "$GitName"
    Write-Host "Configured git user.name: $GitName"
} else {
    $currentName = try { git config --global user.name 2>$null } catch { $null }
    if ([string]::IsNullOrWhiteSpace($currentName)) { $currentName = "unset" }
    Write-Host "Notice: Git user.name not provided. Keeping current: $currentName"
}

if (-not [string]::IsNullOrWhiteSpace($GitEmail)) {
    git config --global user.email "$GitEmail"
    Write-Host "Configured git user.email: $GitEmail"
} else {
    $currentEmail = try { git config --global user.email 2>$null } catch { $null }
    if ([string]::IsNullOrWhiteSpace($currentEmail)) { $currentEmail = "unset" }
    Write-Host "Notice: Git user.email not provided. Keeping current: $currentEmail"
}

if (([string]::IsNullOrWhiteSpace($GitName) -or [string]::IsNullOrWhiteSpace($GitEmail)) -and -not $IsInteractive) {
    Write-Host "Tip: Run in an interactive terminal to be prompted, or specify credentials via:"
    Write-Host "     - Environment variables: `$env:GIT_NAME='...'; `$env:GIT_EMAIL='...'; .\win_setup.ps1"
    Write-Host "     - Configuration file: ~/.dev_setup.env or .dev_setup.env"
}

git config --global init.defaultBranch main
git config --global color.ui auto
git config --global pull.rebase false

# --------------------------------------------------
# GitHub CLI (gh) & SSH Key Setup
# --------------------------------------------------
Write-Host "--------------------------------------------------"
Write-Host "GitHub CLI & SSH Key Setup"
Write-Host "--------------------------------------------------"

$GhAuthed = $false
if (Test-CommandExists "gh") {
    try {
        gh auth status 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $GhAuthed = $true
        }
    } catch {
        $GhAuthed = $false
    }
}

if ($GhAuthed) {
    Write-Host "GitHub CLI is authenticated."
} elseif ($IsInteractive -and (Test-CommandExists "gh")) {
    Write-Host "GitHub CLI is not authenticated."
    $runGhAuth = Read-Host "Would you like to run 'gh auth login' now to authenticate and set up SSH keys? [y/N]"
    if ($runGhAuth -match '^[yY]([eE][sS])?$') {
        gh auth login
    } else {
        Write-Host "Skipping 'gh auth login'."
        Write-Host "Tip: Run 'gh auth login' anytime to authenticate and generate/upload SSH keys to GitHub."
    }
} else {
    Write-Host "Tip: Run 'gh auth login' in an interactive terminal to authenticate and configure SSH keys with GitHub."
}

# --------------------------------------------------
# uv + Python (latest stable)
# --------------------------------------------------
Write-Host "--------------------------------------------------"
Write-Host "Installing Python via uv"
Write-Host "--------------------------------------------------"

uv python install

# --------------------------------------------------
# Antigravity CLI (agy)
# --------------------------------------------------
Write-Host "--------------------------------------------------"
Write-Host "Installing Antigravity CLI (agy)"
Write-Host "--------------------------------------------------"

Invoke-RestMethod -Uri "https://antigravity.google/cli/install.ps1" | Invoke-Expression
Update-SessionPath

# --------------------------------------------------
# Verification
# --------------------------------------------------
Write-Host "--------------------------------------------------"
Write-Host "Verification"
Write-Host "--------------------------------------------------"

Write-Host "mise:      $(Get-ToolVersion -Command 'mise')"
Write-Host "Node:      $(Get-ToolVersion -Command 'node')"
Write-Host "npm:       $(Get-ToolVersion -Command 'npm')"
Write-Host "pnpm:      $(Get-ToolVersion -Command 'pnpm')"
Write-Host "aube:      $(Get-ToolVersion -Command 'aube')"
Write-Host "uv:        $(Get-ToolVersion -Command 'uv')"
Write-Host "Python:    $(Get-ToolVersion -Command 'uv' -Arguments @('run', 'python', '--version'))"
Write-Host "Git:       $(Get-ToolVersion -Command 'git')"
Write-Host "gh:        $(Get-ToolVersion -Command 'gh')"
Write-Host "eza:       $(Get-ToolVersion -Command 'eza' -Fallback 'Installed')"
Write-Host "btop:      $(Get-ToolVersion -Command 'btop' -Fallback 'Installed')"
Write-Host "bottom:    $(Get-ToolVersion -Command 'btm' -Fallback 'Installed')"
Write-Host "fastfetch: $(Get-ToolVersion -Command 'fastfetch' -Fallback 'Installed')"
Write-Host "agy:       $(Get-ToolVersion -Command 'agy' -Fallback 'Installed')"

$FinalGitName = try { git config --global user.name 2>$null } catch { $null }
$FinalGitEmail = try { git config --global user.email 2>$null } catch { $null }
if (-not [string]::IsNullOrWhiteSpace($FinalGitName) -and -not [string]::IsNullOrWhiteSpace($FinalGitEmail)) {
    Write-Host "Git User:  $FinalGitName <$FinalGitEmail>"
}

Write-Host "=================================================="
Write-Host "Setup complete!"
Write-Host "=================================================="
