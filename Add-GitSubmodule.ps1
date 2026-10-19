# Universal Git Submodule Helper for Windows PowerShell
# Save as Add-GitSubmodule.ps1 and run from PowerShell.
# This script never changes the parent repository's origin automatically.

$ErrorActionPreference = "Stop"

function Read-RequiredValue([string]$Prompt) {
    while ($true) {
        $value = Read-Host $Prompt
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value.Trim().Trim('"')
        }
        Write-Host "A value is required." -ForegroundColor Yellow
    }
}

function Invoke-GitChecked([string[]]$GitArgs, [string]$WorkingDirectory) {
    Push-Location $WorkingDirectory
    try {
        & git @GitArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Git command failed: git $($GitArgs -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host "`n=== Universal Git Submodule Helper ===" -ForegroundColor Cyan
Write-Host "This script adds a remote repository as a submodule of an existing parent repository."
Write-Host "It will not change the parent repository's remote URL.`n"

$parentInput = Read-RequiredValue "Enter the FULL path to the parent Git repository folder"
$parentPath = [System.IO.Path]::GetFullPath($parentInput)

if (-not (Test-Path -LiteralPath $parentPath -PathType Container)) {
    throw "Parent folder does not exist: $parentPath"
}

$parentRoot = (& git -C $parentPath rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0) {
    throw "The selected parent folder is not inside a Git repository."
}
$parentRoot = [System.IO.Path]::GetFullPath(($parentRoot | Select-Object -First 1).Trim())

$parentOrigin = (& git -C $parentRoot remote get-url origin 2>$null)
if ($LASTEXITCODE -eq 0) {
    Write-Host "`nParent repository root: $parentRoot"
    Write-Host "Parent origin: $parentOrigin"
} else {
    Write-Host "`nParent repository root: $parentRoot"
    Write-Host "No 'origin' remote is configured in the parent repository." -ForegroundColor Yellow
}

$repoUrl = Read-RequiredValue "`nEnter the submodule repository URL (HTTPS or SSH)"
if ($repoUrl -notmatch '^(https://|ssh://|git@)[^ ]+\.git/?$' -and
    $repoUrl -notmatch '^(https://|ssh://|git@)[^ ]+$') {
    Write-Host "Warning: URL format is unusual. Git will validate it." -ForegroundColor Yellow
}

$relativePath = Read-RequiredValue "Enter the desired submodule path RELATIVE to the parent repo (spaces allowed)"
$relativePath = $relativePath.Replace('\', '/').Trim('/')

if ([System.IO.Path]::IsPathRooted($relativePath) -or $relativePath -match '(^|/)\.\.(/|$)') {
    throw "Submodule path must be relative to the parent repository and cannot contain '..'."
}

$targetPath = Join-Path $parentRoot ($relativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar))

# Ensure the target is inside the parent repository.
$rootFull = [System.IO.Path]::GetFullPath($parentRoot).TrimEnd('\') + '\'
$targetFull = [System.IO.Path]::GetFullPath($targetPath)
if (-not $targetFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Target path must be inside the parent repository."
}

# Confirm remote is accessible and has at least one commit.
Write-Host "`nChecking remote repository..." -ForegroundColor Cyan
& git ls-remote $repoUrl HEAD
if ($LASTEXITCODE -ne 0) {
    throw "Cannot access the remote repository. Check URL, authentication, and permissions."
}

$remoteHead = (& git ls-remote $repoUrl HEAD 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($remoteHead -join ""))) {
    throw "The remote appears to have no HEAD commit (often an empty repository). Create and push an initial commit first."
}

if (Test-Path -LiteralPath $targetPath) {
    $existingItems = @(Get-ChildItem -LiteralPath $targetPath -Force -ErrorAction SilentlyContinue)
    if ($existingItems.Count -gt 0) {
        Write-Host "`nTarget path already exists and contains files:" -ForegroundColor Yellow
        Get-ChildItem -LiteralPath $targetPath -Force | Select-Object Mode, Name
        throw "Target path is not empty. Back up/relocate its contents and rerun. The script will not delete files."
    } else {
        Write-Host "`nTarget path exists but is empty: $targetPath" -ForegroundColor Yellow
        $confirm = Read-Host "Remove this EMPTY folder so Git can create the submodule there? (yes/no)"
        if ($confirm -cne "yes") {
            throw "Cancelled by user."
        }
        Remove-Item -LiteralPath $targetPath
    }
}

# Detect an existing submodule registration at the same path.
$gitModulesPath = Join-Path $parentRoot ".gitmodules"
if (Test-Path -LiteralPath $gitModulesPath) {
    $registeredPaths = @(& git -C $parentRoot config -f .gitmodules --get-regexp '\.path$' 2>$null)
    foreach ($line in $registeredPaths) {
        if ($line -match '^\S+\s+(.+)$' -and $Matches[1].Trim() -eq $relativePath) {
            throw "That path is already registered in .gitmodules. Inspect/fix the existing submodule rather than adding it again."
        }
    }
}

Write-Host "`nAdding submodule at: $relativePath" -ForegroundColor Cyan
Invoke-GitChecked -GitArgs @("submodule", "add", $repoUrl, $relativePath) -WorkingDirectory $parentRoot

Write-Host "`nSubmodule added successfully." -ForegroundColor Green
& git -C $parentRoot submodule status
Write-Host "`nParent repository status:"
& git -C $parentRoot status --short

$commitChoice = Read-Host "`nStage .gitmodules and the submodule reference, then commit them to the parent? (yes/no)"
if ($commitChoice -ceq "yes") {
    & git -C $parentRoot add -- .gitmodules $relativePath
    if ($LASTEXITCODE -ne 0) { throw "Could not stage the submodule changes." }

    $message = Read-Host "Commit message (press Enter for 'Add Git submodule')"
    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = "Add Git submodule"
    }

    & git -C $parentRoot commit -m $message
    if ($LASTEXITCODE -ne 0) {
        throw "Commit failed. Review git status; no push was attempted."
    }

    $pushChoice = Read-Host "Push the parent repository's current branch to its existing origin? (yes/no)"
    if ($pushChoice -ceq "yes") {
        $branch = (& git -C $parentRoot branch --show-current).Trim()
        if ([string]::IsNullOrWhiteSpace($branch)) {
            throw "Could not determine the current branch."
        }
        & git -C $parentRoot push origin $branch
        if ($LASTEXITCODE -ne 0) {
            throw "Push failed. Verify that the parent origin is correct and your account has permission."
        }
    }
}

Write-Host "`nFinished. The parent origin was not changed by this script." -ForegroundColor Green
