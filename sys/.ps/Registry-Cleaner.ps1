
# __usage_lib_page:
# Executes .cs\RegistryCleaner.cs as a script
#
# Params:
#   RegistryBackupHome - Dierctory for backup
#   RegistryBackupToKeep - Backup files to keep
# Usage in script:
#   powershell -NoProfile -ExecutionPolicy Bypass -File ".\.ps\Registry-Cleaner.ps1" -RegistryBackupHome "<home>" -RegistryBackupToKeep "<keep>" # Relative call

param(
    [Parameter(Mandatory=$true)]
    [string]$RegistryBackupHome,
    
    [Parameter(Mandatory=$true)]
    [string]$RegistryBackupToKeep
)

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Yellow
    
    try {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -RegistryBackupHome `"$RegistryBackupHome`" -RegistryBackupToKeep `"$RegistryBackupToKeep`"" -Verb RunAs
        exit
    } catch {
        Write-Host "Script execution was skipped - Administrator privileges are required to proceed" -ForegroundColor Red
        exit
    }
}

try {
    $env:REGISTRY_BACKUP_HOME = $RegistryBackupHome
    $env:REGISTRY_BACKUP_TO_KEEP = $RegistryBackupToKeep

    Write-Host "REGISTRY_BACKUP_HOME: $($env:REGISTRY_BACKUP_HOME)" -ForegroundColor Cyan
    Write-Host "REGISTRY_BACKUP_TO_KEEP: $($env:REGISTRY_BACKUP_TO_KEEP)" -ForegroundColor Cyan
    Write-Host "SCRIPTS_HOME: $($env:SCRIPTS_HOME)" -ForegroundColor Cyan

    $scriptPath = Join-Path $env:SCRIPTS_HOME "sys\.cs\RegistryCleaner.cs"
    dotnet run $scriptPath

    Write-Host "Registry cleanup completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
    exit
}
