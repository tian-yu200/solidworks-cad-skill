[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

try {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $pluginRoot = (Resolve-Path (Join-Path $scriptRoot "..")).Path
    $dataRoot = if ($env:CLAUDE_PLUGIN_DATA) {
        [Environment]::ExpandEnvironmentVariables($env:CLAUDE_PLUGIN_DATA)
    } else {
        Join-Path $env:LOCALAPPDATA "solidworks-cad-plugin"
    }
    $runtimeManifest = Join-Path $dataRoot "runtime\runtime.json"
    $installer = Join-Path $scriptRoot "install.ps1"

    $runtime = $null
    if (Test-Path -LiteralPath $runtimeManifest -PathType Leaf) {
        $runtime = Get-Content -LiteralPath $runtimeManifest -Raw | ConvertFrom-Json
    }
    if (-not $runtime -or
        $runtime.version -ne "1.1.0" -or
        $runtime.pluginRoot -ne $pluginRoot -or
        -not (Test-Path -LiteralPath $runtime.python -PathType Leaf) -or
        -not (Test-Path -LiteralPath $runtime.executionExe -PathType Leaf)) {
        & $installer -Quiet
        if ($LASTEXITCODE -ne 0) { throw "Automatic runtime installation failed." }
        $runtime = Get-Content -LiteralPath $runtimeManifest -Raw | ConvertFrom-Json
    }

    $server = Join-Path $pluginRoot "mcp-server-solidworks\adapters\dsh\server.py"
    if (-not (Test-Path -LiteralPath $server -PathType Leaf)) {
        throw "Bundled MCP entry point is missing: $server"
    }

    $env:EXECUTION_EXE_PATH = $runtime.executionExe
    $env:SOLIDWORKS_INSTALL_DIR = $runtime.solidWorksInstallDir
    if (-not $env:DSH_SOLIDWORKS_STATE_ROOT) {
        $env:DSH_SOLIDWORKS_STATE_ROOT = Join-Path $dataRoot "state"
    }
    if (-not $env:DSH_SOLIDWORKS_BACKUP_ROOT) {
        $env:DSH_SOLIDWORKS_BACKUP_ROOT = Join-Path $dataRoot "backups"
    }
    New-Item -ItemType Directory -Force -Path $env:DSH_SOLIDWORKS_STATE_ROOT | Out-Null
    New-Item -ItemType Directory -Force -Path $env:DSH_SOLIDWORKS_BACKUP_ROOT | Out-Null

    Push-Location (Split-Path -Parent $server)
    try {
        & $runtime.python $server
        exit $LASTEXITCODE
    } finally {
        Pop-Location
    }
} catch {
    [Console]::Error.WriteLine("[solidworks-cad] MCP startup failed: $($_.Exception.Message)")
    exit 1
}
