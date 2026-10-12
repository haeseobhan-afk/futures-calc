$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ElectronVer = '33.4.11'
$ZipUrl  = "https://github.com/electron/electron/releases/download/v$ElectronVer/electron-v$ElectronVer-win32-x64.zip"
$ZipHash = 'F64C8A5A81D9B420B636FDBA13E180F49D69F2198E1D86A8B01F858B17A9483C'

$Here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dest    = Join-Path $env:LOCALAPPDATA 'TickCalc'
$Exe     = Join-Path $Dest 'TickCalc.exe'
$Marker  = Join-Path $Dest 'electron-version.txt'

Write-Host ''
Write-Host '  해외선물 틱 손익 계산기 설치' -ForegroundColor Cyan
Write-Host '  ------------------------------'

try {
  Get-Process TickCalc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

  $have = (Test-Path $Exe) -and (Test-Path $Marker) -and ((Get-Content $Marker -Raw).Trim() -eq $ElectronVer)
  if (-not $have) {
    $tmp = Join-Path $env:TEMP "electron-$ElectronVer-win32-x64.zip"
    Write-Host '  1/3 프로그램 엔진 내려받는 중 (약 110MB, 1~3분)...'
    Invoke-WebRequest -Uri $ZipUrl -OutFile $tmp -UseBasicParsing
    $h = (Get-FileHash $tmp -Algorithm SHA256).Hash
    if ($h -ne $ZipHash) { throw "내려받은 파일이 공식 파일과 달라요 (해시 불일치). 다시 실행해 주세요." }
    Write-Host '  2/3 압축 푸는 중...'
    if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
    New-Item -ItemType Directory -Path $Dest | Out-Null
    Expand-Archive -Path $tmp -DestinationPath $Dest -Force
    Rename-Item (Join-Path $Dest 'electron.exe') 'TickCalc.exe'
    $def = Join-Path $Dest 'resources\default_app.asar'
    if (Test-Path $def) { Remove-Item $def -Force }
    Set-Content -Path $Marker -Value $ElectronVer -Encoding ASCII
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  } else {
    Write-Host '  1/3 엔진은 이미 있어요. 계산기 화면만 새로 넣을게요.'
    Write-Host '  2/3 건너뜀'
  }

  Write-Host '  3/3 계산기 넣고 바탕화면 아이콘 만드는 중...'
  $appDir = Join-Path $Dest 'resources\app'
  if (Test-Path $appDir) { Remove-Item $appDir -Recurse -Force }
  New-Item -ItemType Directory -Path $appDir | Out-Null
  Copy-Item (Join-Path $Here 'app\*') $appDir -Recurse -Force
  Get-ChildItem $appDir -Recurse | Unblock-File -ErrorAction SilentlyContinue

  $desk = [Environment]::GetFolderPath('Desktop')
  $ws = New-Object -ComObject WScript.Shell
  $lnk = $ws.CreateShortcut((Join-Path $desk '틱 손익 계산기.lnk'))
  $lnk.TargetPath = $Exe
  $lnk.WorkingDirectory = $Dest
  $lnk.IconLocation = "$Exe,0"
  $lnk.Description = '해외선물 틱 손익 계산기'
  $lnk.Save()

  Write-Host ''
  Write-Host '  설치 끝! 바탕화면의 "틱 손익 계산기" 아이콘으로 실행하세요.' -ForegroundColor Green
  Write-Host '  지금 바로 한 번 실행할게요.'
  Start-Process $Exe -WorkingDirectory $Dest
}
catch {
  Write-Host ''
  Write-Host ('  설치 중 문제가 생겼어요: ' + $_.Exception.Message) -ForegroundColor Red
  Write-Host '  인터넷 연결을 확인하고 설치.bat 을 다시 실행해 주세요.'
}
