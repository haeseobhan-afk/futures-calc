$ErrorActionPreference = 'SilentlyContinue'
Get-Process TickCalc | Stop-Process -Force
Remove-Item (Join-Path $env:LOCALAPPDATA 'TickCalc') -Recurse -Force
Remove-Item (Join-Path ([Environment]::GetFolderPath('Desktop')) '틱 손익 계산기.lnk') -Force
Write-Host '  삭제했어요.' -ForegroundColor Green
