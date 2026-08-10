#requires -Version 5.1
<#
.SYNOPSIS
  Prepare a fresh Windows development workstation.

.DESCRIPTION
  Installs missing development tools with WinGet, applies selected safe user-level
  defaults, and installs VS Code extensions from vscode-extensions.txt.

  Designed to be rerunnable. It does not store GitHub/Docker credentials.
#>

$ErrorActionPreference = "Stop"

function Write-Step { param([string]$Text) Write-Host "`n==> $Text" -ForegroundColor Cyan }
function Write-OK   { param([string]$Text) Write-Host "[OK] $Text" -ForegroundColor Green }
function Write-Warn { param([string]$Text) Write-Host "[!] $Text" -ForegroundColor Yellow }

function Test-CommandExists {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Install-PackageIfMissing {
    param(
        [string]$Id,
        [string]$DisplayName,
        [string]$CommandName
    )

    if (Test-CommandExists $CommandName) {
        Write-OK "$DisplayName already available"
        return
    }

    Write-Step "Installing $DisplayName"
    winget install --id $Id -e --source winget --accept-source-agreements --accept-package-agreements
}

Write-Host ""
Write-Host "Development Environment Setup" -ForegroundColor White
Write-Host "=============================" -ForegroundColor White

if (-not (Test-CommandExists "winget")) {
    throw "WinGet was not found. Install/update Microsoft App Installer first."
}
Write-OK "WinGet found"

# PowerShell policy for npm.ps1/npx.ps1 and local .ps1 scripts
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -ne "RemoteSigned") {
    Write-Step "Setting CurrentUser PowerShell execution policy to RemoteSigned"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
} else {
    Write-OK "PowerShell CurrentUser policy already RemoteSigned"
}

# Core apps
Install-PackageIfMissing -Id "Microsoft.VisualStudioCode" -DisplayName "Visual Studio Code" -CommandName "code"
Install-PackageIfMissing -Id "Git.Git" -DisplayName "Git for Windows" -CommandName "git"
Install-PackageIfMissing -Id "Python.Python.3.14" -DisplayName "Python 3.14" -CommandName "python"
Install-PackageIfMissing -Id "OpenJS.NodeJS.LTS" -DisplayName "Node.js LTS" -CommandName "node"
Install-PackageIfMissing -Id "Docker.DockerDesktop" -DisplayName "Docker Desktop" -CommandName "docker"

# Refresh common PATH entries for the current process after installers complete.
$pathsToAdd = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin",
    "C:\Program Files\Git\cmd",
    "C:\Program Files\nodejs",
    "C:\Program Files\Docker\Docker\resources\bin"
)

foreach ($p in $pathsToAdd) {
    if ((Test-Path $p) -and (($env:Path -split ";") -notcontains $p)) {
        $env:Path += ";$p"
    }
}

# Git defaults
if (Test-CommandExists "git") {
    Write-Step "Configuring Git"
    git config --global init.defaultBranch main
    git config --global pull.rebase false

    $name = (& git config --global user.name 2>$null | Select-Object -First 1)
    if (-not $name) {
        $name = Read-Host "Git user.name"
        if ($name) { git config --global user.name "$name" }
    } else {
        Write-OK "Git user.name already configured"
    }

    $email = (& git config --global user.email 2>$null | Select-Object -First 1)
    if (-not $email) {
        Write-Host "Tip: use your GitHub noreply email if privacy is enabled."
        $email = Read-Host "Git user.email"
        if ($email) { git config --global user.email "$email" }
    } else {
        Write-OK "Git user.email already configured"
    }
} else {
    Write-Warn "Git is installed but not visible yet. Reopen PowerShell and rerun setup."
}

# VS Code extensions
$extensionFile = Join-Path $PSScriptRoot "vscode-extensions.txt"
if ((Test-CommandExists "code") -and (Test-Path $extensionFile)) {
    Write-Step "Installing VS Code extensions"
    $installed = @(& code --list-extensions 2>$null | ForEach-Object { $_.ToString().Trim().ToLowerInvariant() })

    foreach ($ext in Get-Content $extensionFile) {
        $ext = $ext.Trim()
        if (-not $ext) { continue }

        if ($installed -contains $ext.ToLowerInvariant()) {
            Write-OK "$ext"
        } else {
            Write-Host "Installing $ext ..."
            & code --install-extension $ext
        }
    }
} else {
    Write-Warn "VS Code CLI or vscode-extensions.txt unavailable. Reopen PowerShell and rerun if needed."
}

Write-Host ""
Write-Host "Setup phase complete." -ForegroundColor Green
Write-Host "Restart Windows if Docker/WSL requests it."
Write-Host "Then run: .\verify-dev.ps1"
Write-Host ""
