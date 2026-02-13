# scripts/windows-update.ps1
# Installs Windows Updates (with reboots) then shuts down for imaging.

$ErrorActionPreference = "Stop"
Write-Host "=== Windows Update script started: $(Get-Date -Format o) ==="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
  Write-Host "Installing PSWindowsUpdate module..."
  Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
  Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
  Install-Module -Name PSWindowsUpdate -Force
}

Import-Module PSWindowsUpdate

$maxPasses = 8
for ($i=1; $i -le $maxPasses; $i++) {
  Write-Host "=== Update pass $i/$maxPasses ==="

  Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot:$false -AutoReboot -Verbose | Out-String | Write-Host

  Start-Sleep -Seconds 30

  $pending = Get-WindowsUpdate -MicrosoftUpdate -IgnoreUserInput -ErrorAction SilentlyContinue
  if (-not $pending) {
    Write-Host "No more updates detected."
    break
  } else {
    Write-Host ("Remaining updates detected: {0}" -f $pending.Count)
  }
}

Write-Host "=== Windows Update complete. Shutting down for imaging... ==="
Stop-Computer -Force
