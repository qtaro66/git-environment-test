#requires -Version 5.1
<#
.SYNOPSIS
  Read-only verification of the Windows development environment.

.DESCRIPTION
  Verifies VS Code, Git, Python, Node.js, npm/npx, WSL2, Docker,
  Git configuration, PowerShell execution policy, and required VS Code extensions.

  This script does not intentionally change system/user configuration.
  It creates and removes a temporary Python virtual environment as a functional test.
#>

$ErrorActionPreference = "Continue"
$script:Failures = 0
$script:Warnings = 0

function Write-Pass {
    param([string]$Name, [string]$Value)
    Write-Host ("[PASS] {0,-28} {1}" -f $Name, $Value) -ForegroundColor Green
}

function Write-Fail {
    param([string]$Name, [string]$Value)
    Write-Host ("[FAIL] {0,-28} {1}" -f $Name, $Value) -ForegroundColor Red
    $script:Failures++
}

function Write-Warn {
    param([string]$Name, [string]$Value)
    Write-Host ("[WARN] {0,-28} {1}" -f $Name, $Value) -ForegroundColor Yellow
    $script:Warnings++
}

function Test-CommandExists {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-CommandText {
    param(
        [Parameter(Mandatory=$true)][string]$Exe,
        [string[]]$Arguments = @()
    )
    try {
        $output = & $Exe @Arguments 2>&1
        return (($output | ForEach-Object { $_.ToString() }) -join "`n").Trim()
    }
    catch {
        return ""
    }
}

function First-NonEmptyLine {
    param([string]$Text)
    if (-not $Text) { return $null }
    return ($Text -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1).Trim()
}

Write-Host ""
Write-Host "Development Environment Verification" -ForegroundColor White
Write-Host "====================================" -ForegroundColor White
Write-Host ""

Write-Host "Checking WinGet..."
if (Test-CommandExists "winget") {
    $text = Invoke-CommandText "winget" @("--version")
    $line = First-NonEmptyLine $text
    if ($line) { Write-Pass "WinGet" $line } else { Write-Warn "WinGet" "found, version unavailable" }
} else { Write-Fail "WinGet" "not found" }

Write-Host "Checking VS Code..."
if (Test-CommandExists "code") {
    $text = Invoke-CommandText "code" @("--version")
    $line = First-NonEmptyLine $text
    if ($line) { Write-Pass "VS Code" $line } else { Write-Warn "VS Code" "CLI found, version unavailable" }
} else { Write-Fail "VS Code" "code command not found" }

Write-Host "Checking Git..."
if (Test-CommandExists "git") {
    $text = Invoke-CommandText "git" @("--version")
    $line = First-NonEmptyLine $text
    if ($line) { Write-Pass "Git" $line } else { Write-Warn "Git" "found, version unavailable" }
} else { Write-Fail "Git" "not found" }

Write-Host "Checking Python..."
if (Test-CommandExists "python") {
    $text = Invoke-CommandText "python" @("--version")
    $line = First-NonEmptyLine $text
    if ($line) { Write-Pass "Python" $line } else { Write-Warn "Python" "found, version unavailable" }

    $pipText = Invoke-CommandText "python" @("-m","pip","--version")
    $pipLine = First-NonEmptyLine $pipText
    if ($pipLine) { Write-Pass "pip" $pipLine } else { Write-Fail "pip" "python -m pip failed" }

    Write-Host "Testing Python virtual environment..."
    $venvPath = Join-Path $env:TEMP ("verify-dev-venv-" + [guid]::NewGuid().ToString("N"))
    try {
        & python -m venv $venvPath 2>&1 | Out-Null
        $venvPython = Join-Path $venvPath "Scripts\python.exe"
        if (Test-Path $venvPython) { Write-Pass "Python venv" "creation OK" }
        else { Write-Fail "Python venv" "creation failed" }
    } catch {
        Write-Fail "Python venv" $_.Exception.Message
    } finally {
        Remove-Item $venvPath -Recurse -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Fail "Python" "not found"
}

Write-Host "Checking Node.js..."
if (Test-CommandExists "node") {
    $line = First-NonEmptyLine (Invoke-CommandText "node" @("--version"))
    if ($line) { Write-Pass "Node.js" $line } else { Write-Warn "Node.js" "found, version unavailable" }
} else { Write-Fail "Node.js" "not found" }

if (Test-CommandExists "npm") {
    $line = First-NonEmptyLine (Invoke-CommandText "npm" @("--version"))
    if ($line) { Write-Pass "npm" $line } else { Write-Fail "npm" "command failed" }
} else { Write-Fail "npm" "not found" }

if (Test-CommandExists "npx") {
    $line = First-NonEmptyLine (Invoke-CommandText "npx" @("--version"))
    if ($line) { Write-Pass "npx" $line } else { Write-Fail "npx" "command failed" }
} else { Write-Fail "npx" "not found" }

Write-Host "Checking PowerShell policy..."
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq "RemoteSigned") {
    Write-Pass "PS execution policy" "CurrentUser=RemoteSigned"
} elseif ($policy -eq "Undefined") {
    Write-Warn "PS execution policy" "CurrentUser=Undefined"
} else {
    Write-Warn "PS execution policy" "CurrentUser=$policy"
}

Write-Host "Checking WSL..."
if (Test-CommandExists "wsl") {
    $wslVersionText = Invoke-CommandText "wsl" @("--version")
    $wslVersionLine = First-NonEmptyLine $wslVersionText
    if ($wslVersionLine) { Write-Pass "WSL" $wslVersionLine }
    else { Write-Warn "WSL" "present, version unavailable" }

    $wslStatusText = Invoke-CommandText "wsl" @("--status")

    # Normalize possible UTF-16 / embedded NUL output seen from wsl.exe in Windows PowerShell.
    $wslStatusNormalized = ($wslStatusText -replace "`0","") -replace "\s+"," "
    if ($wslStatusNormalized -match "(?i)Default Version\s*:\s*2") {
        Write-Pass "WSL default version" "2"
    } else {
        Write-Warn "WSL default version" "could not confirm Version 2"
    }
} else {
    Write-Fail "WSL" "not found"
}

Write-Host "Checking Docker..."
if (Test-CommandExists "docker") {
    $dockerLine = First-NonEmptyLine (Invoke-CommandText "docker" @("--version"))
    if ($dockerLine) { Write-Pass "Docker CLI" $dockerLine }
    else { Write-Warn "Docker CLI" "found, version unavailable" }

    $serverText = Invoke-CommandText "docker" @("info","--format","{{.ServerVersion}}")
    $serverLine = First-NonEmptyLine $serverText
    if ($serverLine -and $serverLine -notmatch "(?i)error|cannot connect|failed") {
        Write-Pass "Docker Engine" ("Server " + $serverLine)
    } else {
        Write-Warn "Docker Engine" "Docker Desktop may not be running"
    }

    $composeText = Invoke-CommandText "docker" @("compose","version")
    $composeLine = First-NonEmptyLine $composeText
    if ($composeLine -and $composeLine -match "(?i)docker compose version") {
        Write-Pass "Docker Compose" $composeLine
    } else {
        Write-Fail "Docker Compose" "not available"
    }
} else {
    Write-Fail "Docker CLI" "not found"
}

Write-Host "Checking Git configuration..."
if (Test-CommandExists "git") {
    $branch = (Invoke-CommandText "git" @("config","--global","init.defaultBranch")).Trim()
    if ($branch -eq "main") { Write-Pass "Git default branch" "main" }
    else { Write-Warn "Git default branch" ("expected main; got '" + $branch + "'") }

    $name = (Invoke-CommandText "git" @("config","--global","user.name")).Trim()
    if ($name) { Write-Pass "Git user.name" $name } else { Write-Warn "Git user.name" "not configured" }

    $email = (Invoke-CommandText "git" @("config","--global","user.email")).Trim()
    if ($email) { Write-Pass "Git user.email" "configured" } else { Write-Warn "Git user.email" "not configured" }

    $helper = (Invoke-CommandText "git" @("config","--show-origin","--get-all","credential.helper")).Trim()
    if ($helper) { Write-Pass "Git credential helper" ($helper -replace "`r?`n","; ") }
    else { Write-Warn "Git credential helper" "not configured" }
}

$extensionFile = Join-Path $PSScriptRoot "vscode-extensions.txt"
Write-Host "Checking VS Code extensions..."
if ((Test-CommandExists "code") -and (Test-Path $extensionFile)) {
    $installed = @((& code --list-extensions 2>$null) | ForEach-Object { $_.ToString().Trim().ToLowerInvariant() })
    foreach ($ext in Get-Content $extensionFile) {
        $ext = $ext.Trim()
        if (-not $ext) { continue }
        if ($installed -contains $ext.ToLowerInvariant()) {
            Write-Pass $ext "installed"
        } else {
            Write-Fail $ext "missing"
        }
    }
} elseif (-not (Test-Path $extensionFile)) {
    Write-Warn "VS Code extensions" "vscode-extensions.txt not found beside script"
} else {
    Write-Warn "VS Code extensions" "VS Code CLI unavailable"
}

Write-Host ""
Write-Host "===================================="
if ($script:Failures -eq 0) {
    Write-Host "Environment Status: READY" -ForegroundColor Green
} else {
    Write-Host "Environment Status: NOT READY ($script:Failures failure(s))" -ForegroundColor Red
}
if ($script:Warnings -gt 0) {
    Write-Host "Warnings: $script:Warnings" -ForegroundColor Yellow
}
Write-Host ""

exit $script:Failures
