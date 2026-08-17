[CmdletBinding()]
param(
    [string]$Python = "",
    [string]$SolidWorksInstallDir = "",
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Status([string]$Message) {
    if (-not $Quiet) {
        [Console]::Error.WriteLine("[solidworks-cad] $Message")
    }
}

function Resolve-CommandPath([string]$Name) {
    if (-not $Name) { return $null }
    if (Test-Path -LiteralPath $Name -PathType Leaf) {
        return (Resolve-Path -LiteralPath $Name).Path
    }
    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }
    return $null
}

function Resolve-PythonCommand([string]$Requested) {
    if ($Requested) {
        $resolved = Resolve-CommandPath $Requested
        if (-not $resolved) { throw "Python executable was not found: $Requested" }
        return @{ Exe = $resolved; Args = @() }
    }

    $launcher = Resolve-CommandPath "py.exe"
    if ($launcher) {
        & $launcher -3 -c "import sys; print(sys.executable)" *> $null
        if ($LASTEXITCODE -eq 0) {
            return @{ Exe = $launcher; Args = @("-3") }
        }
    }

    $pythonExe = Resolve-CommandPath "python.exe"
    if ($pythonExe) {
        & $pythonExe -c "import sys; print(sys.executable)" *> $null
        if ($LASTEXITCODE -eq 0) {
            return @{ Exe = $pythonExe; Args = @() }
        }
    }
    throw "Python 3.10 or newer is required. Install Python, or pass -Python <path>."
}

function Test-SolidWorksDirectory([string]$Path) {
    if (-not $Path) { return $null }
    $candidate = [Environment]::ExpandEnvironmentVariables($Path.Trim('"'))
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        $candidate = Split-Path -Parent $candidate
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Container)) { return $null }
    $candidate = (Resolve-Path -LiteralPath $candidate).Path.TrimEnd('\')
    $interop = Join-Path $candidate "api\redist\SolidWorks.Interop.sldworks.dll"
    $executable = Join-Path $candidate "SLDWORKS.exe"
    if ((Test-Path -LiteralPath $interop -PathType Leaf) -and
        (Test-Path -LiteralPath $executable -PathType Leaf)) {
        return $candidate
    }
    return $null
}

function Resolve-SolidWorksDirectory([string]$Requested) {
    foreach ($candidate in @($Requested, $env:SOLIDWORKS_INSTALL_DIR)) {
        $resolved = Test-SolidWorksDirectory $candidate
        if ($resolved) { return $resolved }
    }

    $process = Get-Process -Name "SLDWORKS" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($process) {
        try {
            $resolved = Test-SolidWorksDirectory (Split-Path -Parent $process.Path)
            if ($resolved) { return $resolved }
        } catch { }
    }

    $registryRoots = @(
        "HKLM:\SOFTWARE\SolidWorks",
        "HKLM:\SOFTWARE\WOW6432Node\SolidWorks",
        "HKCU:\SOFTWARE\SolidWorks"
    )
    foreach ($root in $registryRoots) {
        if (-not (Test-Path $root)) { continue }
        foreach ($key in Get-ChildItem $root -Recurse -ErrorAction SilentlyContinue) {
            try {
                $properties = Get-ItemProperty $key.PSPath -ErrorAction Stop
                foreach ($name in @("SolidWorks Folder", "InstallDir", "Install Path", "Path")) {
                    $resolved = Test-SolidWorksDirectory $properties.$name
                    if ($resolved) { return $resolved }
                }
            } catch { }
        }
    }

    $programRoots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
    foreach ($root in $programRoots) {
        foreach ($pattern in @("SOLIDWORKS Corp\SOLIDWORKS", "SOLIDWORKS*\SOLIDWORKS")) {
            foreach ($directory in Get-ChildItem -Path (Join-Path $root $pattern) -Directory -ErrorAction SilentlyContinue) {
                $resolved = Test-SolidWorksDirectory $directory.FullName
                if ($resolved) { return $resolved }
            }
        }
    }
    throw "A licensed local SolidWorks installation was not found. Set SOLIDWORKS_INSTALL_DIR or pass -SolidWorksInstallDir."
}

function Resolve-MSBuild {
    if ($env:MSBUILD_EXE_PATH) {
        $resolved = Resolve-CommandPath $env:MSBUILD_EXE_PATH
        if (-not $resolved) { throw "MSBUILD_EXE_PATH does not point to a valid executable." }
        return @{ Exe = $resolved; Kind = "msbuild" }
    }

    $vswhereCandidates = @(
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"),
        (Resolve-CommandPath "vswhere.exe")
    ) | Where-Object { $_ }
    foreach ($vswhere in $vswhereCandidates) {
        if (-not (Test-Path -LiteralPath $vswhere -PathType Leaf)) { continue }
        $found = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe" 2>$null | Select-Object -First 1
        if ($found -and (Test-Path -LiteralPath $found -PathType Leaf)) {
            return @{ Exe = $found; Kind = "msbuild" }
        }
    }

    $pathMSBuild = Resolve-CommandPath "msbuild.exe"
    if ($pathMSBuild -and $pathMSBuild -notmatch "Microsoft\.NET\\Framework") {
        return @{ Exe = $pathMSBuild; Kind = "msbuild" }
    }

    $dotnet = Resolve-CommandPath "dotnet.exe"
    if ($dotnet) { return @{ Exe = $dotnet; Kind = "dotnet" } }

    foreach ($candidate in @(
        "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe",
        "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"
    )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return @{ Exe = $candidate; Kind = "legacy" }
        }
    }
    throw "No compatible C# build tool was found. Install Visual Studio Build Tools or a current .NET SDK."
}

function Resolve-NuGet([string]$ToolsRoot) {
    $resolved = Resolve-CommandPath "nuget.exe"
    if ($resolved) { return $resolved }

    New-Item -ItemType Directory -Force -Path $ToolsRoot | Out-Null
    $target = Join-Path $ToolsRoot "nuget.exe"
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        Write-Status "Downloading the NuGet command-line client..."
        Invoke-WebRequest -UseBasicParsing -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $target
    }
    return $target
}

if (-not $IsWindows -and $PSVersionTable.PSEdition -eq "Core") {
    throw "This plugin requires Windows because SolidWorks is a Windows application."
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$pluginRoot = (Resolve-Path (Join-Path $scriptRoot "..")).Path
$serverRoot = Join-Path $pluginRoot "mcp-server-solidworks"
$dataRoot = if ($env:CLAUDE_PLUGIN_DATA) {
    [Environment]::ExpandEnvironmentVariables($env:CLAUDE_PLUGIN_DATA)
} else {
    Join-Path $env:LOCALAPPDATA "solidworks-cad-plugin"
}
$runtimeRoot = Join-Path $dataRoot "runtime"
$venvRoot = Join-Path $runtimeRoot "venv"
$venvPython = Join-Path $venvRoot "Scripts\python.exe"
$manifestPath = Join-Path $runtimeRoot "runtime.json"
$logPath = Join-Path $runtimeRoot "install.log"
$executionSource = Join-Path $serverRoot "execution\solidworks"
$executionBuildRoot = Join-Path $runtimeRoot "execution-build-v1"
$solutionPath = Join-Path $executionBuildRoot "SolidworksExecution.sln"
$packagesRoot = Join-Path $executionBuildRoot "packages"
$packagesConfig = Join-Path $executionBuildRoot "SolidworksExecution\packages.config"
$executionExe = Join-Path $executionBuildRoot "SolidworksExecution\bin\Release\SolidworksExecution.exe"
$requirementsPath = Join-Path $serverRoot "requirements.txt"

New-Item -ItemType Directory -Force -Path $runtimeRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $dataRoot "state") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $dataRoot "backups") | Out-Null

try {
    if ($Force -or -not (Test-Path -LiteralPath $venvPython -PathType Leaf)) {
        $pythonCommand = Resolve-PythonCommand $Python
        Write-Status "Creating the isolated Python runtime..."
        $venvArgs = if ($Force) { @("-m", "venv", "--clear", $venvRoot) } else { @("-m", "venv", $venvRoot) }
        & $pythonCommand.Exe @($pythonCommand.Args) @venvArgs 2>&1 | Tee-Object -FilePath $logPath -Append | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Python virtual environment creation failed. See $logPath" }
    }

    Write-Status "Installing Python MCP dependencies..."
    & $venvPython -m pip install --disable-pip-version-check --upgrade pip 2>&1 | Tee-Object -FilePath $logPath -Append | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "pip upgrade failed. See $logPath" }
    & $venvPython -m pip install --disable-pip-version-check -r $requirementsPath 2>&1 | Tee-Object -FilePath $logPath -Append | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Python dependency installation failed. See $logPath" }

    $solidWorksRoot = Resolve-SolidWorksDirectory $SolidWorksInstallDir
    $msbuild = Resolve-MSBuild
    $nuget = Resolve-NuGet (Join-Path $runtimeRoot "tools")

    Write-Status "Preparing the local execution-service build tree..."
    New-Item -ItemType Directory -Force -Path $executionBuildRoot | Out-Null
    Copy-Item -Path (Join-Path $executionSource "*") -Destination $executionBuildRoot -Recurse -Force

    Write-Status "Restoring C# dependencies..."
    & $nuget install $packagesConfig -OutputDirectory $packagesRoot -NonInteractive 2>&1 | Tee-Object -FilePath $logPath -Append | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "NuGet restore failed. See $logPath" }

    Write-Status "Building the local SolidWorks execution service..."
    $buildArgs = @(
        $solutionPath,
        "/t:Build",
        "/p:Configuration=Release",
        "/p:Platform=Any CPU",
        "/p:SolidWorksInstallDir=$solidWorksRoot",
        "/nologo",
        "/verbosity:minimal"
    )
    if ($msbuild.Kind -eq "dotnet") {
        $referenceRoot = Join-Path $runtimeRoot "reference-assemblies"
        & $nuget install "Microsoft.NETFramework.ReferenceAssemblies.net48" -Version "1.0.3" -OutputDirectory $referenceRoot -NonInteractive 2>&1 | Tee-Object -FilePath $logPath -Append | Out-Null
        if ($LASTEXITCODE -ne 0) { throw ".NET Framework 4.8 reference assembly installation failed. See $logPath" }
        $targetFrameworkRoot = Join-Path $referenceRoot "Microsoft.NETFramework.ReferenceAssemblies.net48.1.0.3\build"
        $buildArgs += "/p:TargetFrameworkRootPath=$targetFrameworkRoot"
        & $msbuild.Exe msbuild @buildArgs 2>&1 | Tee-Object -FilePath $logPath -Append | Out-Null
    } else {
        & $msbuild.Exe @buildArgs 2>&1 | Tee-Object -FilePath $logPath -Append | Out-Null
    }
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $executionExe -PathType Leaf)) {
        $hint = if ($msbuild.Kind -eq "legacy") { " Install Visual Studio Build Tools or a current .NET SDK; the system MSBuild compiler is too old for this source." } else { "" }
        throw "SolidWorks execution service build failed.$hint See $logPath"
    }

    $manifest = [ordered]@{
        version = "1.1.0"
        installedAt = (Get-Date).ToUniversalTime().ToString("o")
        pluginRoot = $pluginRoot
        serverRoot = $serverRoot
        python = $venvPython
        executionExe = $executionExe
        solidWorksInstallDir = $solidWorksRoot
        buildTool = "$($msbuild.Kind):$($msbuild.Exe)"
    }
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    Write-Status "Installation complete. Runtime manifest: $manifestPath"
} catch {
    [Console]::Error.WriteLine("[solidworks-cad] Installation failed: $($_.Exception.Message)")
    exit 1
}
