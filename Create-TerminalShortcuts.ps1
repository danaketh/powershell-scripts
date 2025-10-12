<#
.SYNOPSIS
Creates terminal shortcuts for directories.

.DESCRIPTION
Puts a shortcut to a specific directory on your desktop,
so you can launch Terminal in there with ease.

.PARAMETER Paths
List of directories for which to create the links.

.PARAMETER Here
Create link from current directory.

.PARAMETER NameTemplate
Template for naming the link(s).

.PARAMETER AllUsers
Put the link to desktop of all users. Requires admin.

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
PS> Create-TerminalShortcuts.ps1 -Paths C:\Projects,C:\Repos

.EXAMPLE
PS> Create-TerminalShortcuts.ps1 -Here

.EXAMPLE
PS> Create-TerminalShortcuts.ps1 -Here -AllUsers -NameTemplate "Dev - {0}"
#>
param(
  [Parameter(Mandatory = $true, ParameterSetName = 'Paths')]
  [string[]] $Paths,
  [Parameter(Mandatory = $true, ParameterSetName = 'Here')]
  [switch] $Here,
  [string] $NameTemplate = 'Terminal - {0}',
  [switch] $AllUsers
)

$desktop = if ($AllUsers) { Join-Path $env:Public 'Desktop' } else { [Environment]::GetFolderPath('Desktop') }
$wtPath = (Get-Command wt.exe -ErrorAction SilentlyContinue)?.Source
if (-not $wtPath) { $wtPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\wt.exe' }
$useWt  = Test-Path $wtPath
$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source
$ps   = (Get-Command powershell.exe -ErrorAction SilentlyContinue)?.Source
$shell = New-Object -ComObject WScript.Shell

$pathsToProcess = if ($Here) {
  @(Get-Location | Select-Object -ExpandProperty Path)
} else {
  $Paths
}

foreach ($p in $pathsToProcess) {
  try {
    $full = (Resolve-Path -LiteralPath $p).Path
  } catch {
    Write-Warning "Path not found: $p"
    continue
  }

  $name = [string]::Format($NameTemplate, (Split-Path $full -Leaf))
  $lnk  = Join-Path $desktop "$name.lnk"

  $sc = $shell.CreateShortcut($lnk)

  if ($useWt) {
    $sc.TargetPath      = $wtPath
    $sc.Arguments       = '--window 0 new-tab -d "' + $full + '"'
    $sc.WorkingDirectory= ''
    $sc.IconLocation    = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe,0"
  } else {
    $target = $pwsh ?? $ps
    if (-not $target) { throw "No shell found (pwsh/powershell.exe)"; }

    $sc.TargetPath       = $target
    $sc.Arguments        = "-NoExit"
    $sc.WorkingDirectory = $full
    $sc.IconLocation     = "$target,0"
  }

  $sc.Save()
  Write-Host "Created: $lnk"
}
