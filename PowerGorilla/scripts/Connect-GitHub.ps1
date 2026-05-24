#!/usr/bin/env pwsh
<#
    Connect Power Gorilla to a GitHub repository by configuring the local Git remote.
#>

[CmdletBinding()]
param(
    [string]$Root,
    [Parameter(Mandatory=$true)]
    [string]$RepositoryUrl
)

$ErrorActionPreference = 'Stop'

function Get-GitRoot {
    param([string]$Path)
    $current = (Resolve-Path -LiteralPath $Path).Path
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $current '.git')) { return $current }
        $parent = Split-Path -Parent $current
        if ($parent -eq $current) { return $null }
        $current = $parent
    }
}

if ([string]::IsNullOrWhiteSpace($Root)) {
    if ($PSScriptRoot) {
        $Root = Split-Path -Parent $PSScriptRoot
    } else {
        $Root = (Get-Location).Path
    }
}

$repoRoot = Get-GitRoot -Path $Root
if (-not $repoRoot) {
    throw "No Git repository found under $Root or any parent directory. Initialize git in the repo root first."
}

Push-Location $repoRoot
try {
    $existing = git remote get-url origin 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($existing)) {
        if ($existing -ne $RepositoryUrl) {
            git remote set-url origin $RepositoryUrl
            Write-Host "Updated origin remote to $RepositoryUrl" -ForegroundColor Green
        } else {
            Write-Host "Origin remote already set to $RepositoryUrl" -ForegroundColor Yellow
        }
    } else {
        git remote add origin $RepositoryUrl
        Write-Host "Added origin remote to $RepositoryUrl" -ForegroundColor Green
    }
} finally {
    Pop-Location
}

Write-Host "Run 'git push -u origin master' or your branch name after authenticating to GitHub." -ForegroundColor Cyan
