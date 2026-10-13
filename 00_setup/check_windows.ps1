
$ErrorActionPreference = "Continue"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " DeepStream GPU Pipeline - Windows Check" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "[1] Operating System"
Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, OSArchitecture |
    Format-List

Write-Host "[2] NVIDIA GPU and Driver"
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
    nvidia-smi
} else {
    Write-Host "nvidia-smi not found on Windows." -ForegroundColor Yellow
    Write-Host "The NVIDIA driver/GPU may be unavailable in this environment."
}

Write-Host "`n[3] WSL Installation"
if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
    wsl.exe --status
    Write-Host "`nInstalled WSL distributions:"
    wsl.exe --list --verbose
} else {
    Write-Host "WSL is not installed or is not available in PATH." -ForegroundColor Yellow
}

Write-Host "`n[4] Docker Installation"
if (Get-Command docker.exe -ErrorAction SilentlyContinue) {
    docker.exe --version
    Write-Host "`nDocker server status:"
    docker.exe info --format '{{.ServerVersion}}'
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Docker Desktop may not be running." -ForegroundColor Yellow
    }
} else {
    Write-Host "Docker is not installed or is not available in PATH." -ForegroundColor Yellow
}

Write-Host "`n[5] Project Assets"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

$Assets = @(
    "01_input\PNNL_Parking_LOT(1).avi",
    "02_models\yolo11m.onnx"
)

foreach ($Asset in $Assets) {
    $AssetPath = Join-Path $ProjectRoot $Asset
    if (Test-Path $AssetPath) {
        Write-Host "FOUND: $Asset" -ForegroundColor Green
    } else {
        Write-Host "MISSING: $Asset" -ForegroundColor Yellow
    }
}

Write-Host "`nWindows checks completed."
Write-Host "This check does not install drivers or prove DeepStream compatibility."
