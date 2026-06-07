# User's custom PowerShell profile (from backup)
$env:Path += ";C:\Users\user\.local\bin"
$env:MY_CUSTOM_VAR = "from-backup-ps1"
$env:EDITOR = "code"

# Aliases
Set-Alias ll Get-ChildItem
Set-Alias gs git status

# Welcome message
Write-Host "Welcome back, user!"
