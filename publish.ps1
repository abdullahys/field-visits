# Publish changes to GitHub (GitHub Pages redeploys the site from main automatically).
# Usage: .\publish.ps1 "وصف التعديل"
param([string]$Message = "تحديث النظام")
$ErrorActionPreference = "Stop"
$env:Path = "C:\Program Files\Git\cmd;" + $env:Path
Set-Location $PSScriptRoot

git add -A
if (-not (git status --porcelain)) { Write-Host "لا توجد تعديلات جديدة."; exit 0 }
git commit -q -m $Message
git push -q origin main
Write-Host "تم الرفع: $(git log -1 --format='%h %s')"

# wait until the live site serves the new version
$sha = (git rev-parse HEAD)
for ($i = 0; $i -lt 30; $i++) {
  Start-Sleep 10
  try {
    $b = & "C:\Program Files\GitHub CLI\gh.exe" api repos/abdullahys/field-visits/pages/builds/latest | ConvertFrom-Json
    if ($b.commit -eq $sha -and $b.status -eq "built") { Write-Host "الموقع محدّث: https://abdullahys.github.io/field-visits/"; exit 0 }
  } catch {}
}
Write-Host "انرفع التعديل، والموقع ما زال يتحدّث. تحقق بعد دقيقة."
