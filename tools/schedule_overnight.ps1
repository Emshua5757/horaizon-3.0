# schedule_overnight.ps1
# -------------------------------------------------------
# Creates a Windows Task Scheduler job that runs the
# horAIzon overnight agent at 22:00 (10 PM) every night.
#
# Run this ONCE as Administrator:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\tools\schedule_overnight.ps1
# -------------------------------------------------------

$taskName   = "horAIzon-OvernightAgent"
$repoRoot   = "c:\horaizon-3.0"
$python     = (Get-Command python).Source
$script     = "$repoRoot\tools\overnight_agent.py"
$logFile    = "$repoRoot\_architecture\progress\agent_logs\scheduler.log"
$startTime  = "22:00"

# Remove existing task if present
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "[schedule] Removed existing task: $taskName"
}

# Build the action — runs: python tools/overnight_agent.py --all
$action = New-ScheduledTaskAction `
    -Execute $python `
    -Argument "--all" `
    -WorkingDirectory $repoRoot

# Trigger: daily at 22:00
$trigger = New-ScheduledTaskTrigger -Daily -At $startTime

# Settings: wake the computer if sleeping, run if missed
$settings = New-ScheduledTaskSettingsSet `
    -WakeToRun `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -ExecutionTimeLimit "08:00:00" `
    -MultipleInstances IgnoreNew

# Principal: run as current user
$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType S4U `
    -RunLevel Highest

# Register the task
Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "horAIzon 3.0 overnight coding agent — runs all pending TASK-XXX files via aider+Ollama" `
    -Force

Write-Host ""
Write-Host "========================================"
Write-Host " Scheduled Task Created:"
Write-Host "   Name:    $taskName"
Write-Host "   Runs at: $startTime daily"
Write-Host "   Command: python $script --all"
Write-Host "   Logs:    $logFile"
Write-Host "========================================"
Write-Host ""
Write-Host "To run RIGHT NOW (test):"
Write-Host "   Start-ScheduledTask -TaskName '$taskName'"
Write-Host ""
Write-Host "To view status:"
Write-Host "   Get-ScheduledTaskInfo -TaskName '$taskName'"
Write-Host ""
Write-Host "To remove:"
Write-Host "   Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"
