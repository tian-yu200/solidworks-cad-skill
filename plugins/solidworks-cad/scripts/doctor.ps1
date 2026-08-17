[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$script:Failures = 0

function Write-Check([string]$Name, [bool]$Passed, [string]$Detail, [bool]$Optional = $false) {
    if ($Passed) {
        Write-Host ("[PASS] {0}: {1}" -f $Name, $Detail)
    } elseif ($Optional) {
        Write-Host ("[INFO] {0}: {1}" -f $Name, $Detail)
    } else {
        Write-Host ("[FAIL] {0}: {1}" -f $Name, $Detail)
        $script:Failures++
    }
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$pluginRoot = (Resolve-Path (Join-Path $scriptRoot "..")).Path
$dataRoot = if ($env:CLAUDE_PLUGIN_DATA) {
    [Environment]::ExpandEnvironmentVariables($env:CLAUDE_PLUGIN_DATA)
} else {
    Join-Path $env:LOCALAPPDATA "solidworks-cad-plugin"
}
$manifestPath = Join-Path $dataRoot "runtime\runtime.json"
$skillPath = Join-Path $pluginRoot "skills\solidworks-cad\SKILL.md"
$serverPath = Join-Path $pluginRoot "mcp-server-solidworks\adapters\dsh\server.py"
$schemaPath = Join-Path $pluginRoot "mcp-server-solidworks\cad-planner\contracts\feature-graph.schema.json"

$isWindowsHost = ($env:OS -eq "Windows_NT")
Write-Check "Windows" $isWindowsHost "SolidWorks requires Windows."
Write-Check "Bundled Skill" (Test-Path -LiteralPath $skillPath -PathType Leaf) $skillPath
Write-Check "Bundled MCP" (Test-Path -LiteralPath $serverPath -PathType Leaf) $serverPath
Write-Check "Feature Graph schema" (Test-Path -LiteralPath $schemaPath -PathType Leaf) $schemaPath
Write-Check "Runtime manifest" (Test-Path -LiteralPath $manifestPath -PathType Leaf) $manifestPath

$runtime = $null
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    try { $runtime = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json } catch { }
}

if ($runtime) {
    $pythonOk = Test-Path -LiteralPath $runtime.python -PathType Leaf
    $executionOk = Test-Path -LiteralPath $runtime.executionExe -PathType Leaf
    $interopPath = Join-Path $runtime.solidWorksInstallDir "api\redist\SolidWorks.Interop.sldworks.dll"
    Write-Check "Python runtime" $pythonOk $runtime.python
    Write-Check "Execution service" $executionOk $runtime.executionExe
    Write-Check "SolidWorks API" (Test-Path -LiteralPath $interopPath -PathType Leaf) $interopPath

    if ($pythonOk -and (Test-Path -LiteralPath $serverPath -PathType Leaf)) {
        $adapterRoot = Split-Path -Parent $serverPath
        $code = 'import json, server; print(json.dumps(sorted(t.name for t in server.mcp._tool_manager.list_tools())))'
        Push-Location $adapterRoot
        try {
            $toolJson = & $runtime.python -c $code 2>$null
            $tools = $toolJson | ConvertFrom-Json
            $expected = @("apply_document_edits", "confirm_action", "drawing_workflow", "finish_job", "inspect_state", "request_confirmation", "save_or_export", "start_job", "submit_feature_graph")
            $actual = @($tools)
            $matches = ($LASTEXITCODE -eq 0 -and $actual.Count -eq 9 -and (Compare-Object $expected $actual).Count -eq 0)
            Write-Check "MCP tool surface" $matches ((@($actual) -join ", ") + " (expected exactly 9)")
        } catch {
            Write-Check "MCP tool surface" $false $_.Exception.Message
        } finally {
            Pop-Location
        }
    }
} else {
    Write-Check "Python runtime" $false "Run scripts\install.ps1 first."
    Write-Check "Execution service" $false "Run scripts\install.ps1 first."
    Write-Check "SolidWorks API" $false "Run scripts\install.ps1 first."
}

$solidWorksProcess = Get-Process -Name "SLDWORKS" -ErrorAction SilentlyContinue | Select-Object -First 1
Write-Check "SolidWorks process" ($null -ne $solidWorksProcess) "It may be launched automatically on first MCP use." $true

$portOpen = $false
try {
    $client = [System.Net.Sockets.TcpClient]::new()
    $result = $client.BeginConnect("127.0.0.1", 5000, $null, $null)
    $portOpen = $result.AsyncWaitHandle.WaitOne(500) -and $client.Connected
    $client.Close()
} catch { }
Write-Check "Execution port 5000" $portOpen "It opens automatically on first CAD tool use." $true

if ($script:Failures -gt 0) {
    Write-Host "Doctor found $script:Failures required check(s) that need attention."
    exit 1
}
Write-Host "All required checks passed."
