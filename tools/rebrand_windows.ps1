# =============================================================================
# horAIzon 3.0 — Windows Rebranding Script
# Re-applies custom window title and executable metadata after `flutter create`
# =============================================================================

$ErrorActionPreference = "Stop"

$MainCpp = "client_flutter/windows/runner/main.cpp"
$RunnerRc = "client_flutter/windows/runner/Runner.rc"

if (-not (Test-Path $MainCpp)) {
    Write-Warning "main.cpp not found at $MainCpp. Run from repo root after TASK-008 scaffold."
    exit 1
}

# 1. Update Window Title in main.cpp
(Get-Content $MainCpp) -replace 'L"client_flutter"', 'L"horAIzon 3.0"' | Set-Content $MainCpp
Write-Host "Updated window title in $MainCpp to 'horAIzon 3.0'"

# 2. Update Executable Metadata in Runner.rc
if (Test-Path $RunnerRc) {
    (Get-Content $RunnerRc) -replace 'VALUE "FileDescription", "client_flutter"', 'VALUE "FileDescription", "horAIzon 3.0"' `
                             -replace 'VALUE "ProductName", "client_flutter"', 'VALUE "ProductName", "horAIzon 3.0"' | Set-Content $RunnerRc
    Write-Host "Updated metadata in $RunnerRc to 'horAIzon 3.0'"
}

Write-Host "Windows rebranding complete!"
