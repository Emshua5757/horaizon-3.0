# horAIzon 3.0 Instant Deployment Script
# Cross-compiles shua_governor & shua_resume on Windows and deploys to Pi 5 over SSH

param (
    [string]$PiHost = "192.168.254.108",
    [string]$PiUser = "shua"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 [1/4] Cross-compiling shua_resume (Go ARM64)..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\shua_resume"
$env:GOOS = "linux"
$env:GOARCH = "arm64"
$env:CGO_ENABLED = "0"
go build -buildvcs=false -o "$PSScriptRoot\bin\shua_resume" ./cmd
Remove-Item env:GOOS
Remove-Item env:GOARCH
Remove-Item env:CGO_ENABLED

Write-Host "🚀 [2/4] Cross-compiling shua_governor (Rust ARM64)..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\shua_governor"
cargo build --release --target aarch64-unknown-linux-gnu
Copy-Item "$PSScriptRoot\shua_governor\target\aarch64-unknown-linux-gnu\release\shua_governor.exe" "$PSScriptRoot\bin\shua_governor" -ErrorAction SilentlyContinue
if (-not (Test-Path "$PSScriptRoot\bin\shua_governor")) {
    Copy-Item "$PSScriptRoot\shua_governor\target\aarch64-unknown-linux-gnu\release\shua_governor" "$PSScriptRoot\bin\shua_governor"
}

Write-Host "📦 [3/4] Copying binaries to Raspberry Pi 5 ($PiUser@$PiHost)..." -ForegroundColor Yellow
scp "$PSScriptRoot\bin\shua_resume" "$PSScriptRoot\bin\shua_governor" "${PiUser}@${PiHost}:/tmp/"

Write-Host "⚡ [4/4] Restarting services on Raspberry Pi 5..." -ForegroundColor Green
ssh "${PiUser}@${PiHost}" "sudo systemctl stop shua-governor 2>/dev/null; sudo fuser -k 7700/tcp 2>/dev/null; pkill -9 shua_governor 2>/dev/null; pkill -9 shua_resume 2>/dev/null; sudo cp /tmp/shua_resume /usr/local/bin/shua_resume; sudo cp /tmp/shua_governor /usr/local/bin/shua_governor; sudo chmod +x /usr/local/bin/shua_resume /usr/local/bin/shua_governor; /usr/local/bin/shua_governor"

Set-Location $PSScriptRoot
