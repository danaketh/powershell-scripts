<#
.SYNOPSIS
Cleans up local branches whose remote tracking branches no longer exist.

.DESCRIPTION
Removes local branches that have a remote tracking branch configured,
but that remote branch has been deleted. Does not delete local-only branches
or protected root branches (main, master, dev, devel, develop).

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
PS> Git-CleanupBranches.ps1
#>

$protectedBranches = @('main', 'master', 'dev', 'devel', 'develop')

Write-Host "Fetching and pruning remote references..."
git fetch --prune

$currentBranch = git branch --show-current

$branches = git branch -vv --format="%(refname:short)|%(upstream:short)" | ForEach-Object {
    $parts = $_ -split '\|'
    [PSCustomObject]@{
        Local    = $parts[0].Trim()
        Upstream = $parts[1].Trim()
    }
}

foreach ($branch in $branches) {
    if ($branch.Local -eq $currentBranch) {
        Write-Host "Skipping current branch: $($branch.Local)" -ForegroundColor Cyan
        continue
    }

    if ($protectedBranches -contains $branch.Local) {
        Write-Host "Skipping protected branch: $($branch.Local)" -ForegroundColor Cyan
        continue
    }

    if ([string]::IsNullOrWhiteSpace($branch.Upstream)) {
        Write-Host "Skipping local-only branch: $($branch.Local)" -ForegroundColor Yellow
        continue
    }

    $upstreamExists = git rev-parse --verify --quiet $branch.Upstream 2>$null
    if (-not $upstreamExists) {
        Write-Host "Deleting branch with gone remote: $($branch.Local) (was tracking $($branch.Upstream))" -ForegroundColor Red
        git branch -D $branch.Local
    } else {
        Write-Host "Keeping branch: $($branch.Local) (tracking $($branch.Upstream))" -ForegroundColor Green
    }
}

Write-Host "`nCleanup complete!" -ForegroundColor Green
