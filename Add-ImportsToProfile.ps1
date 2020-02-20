$scriptFolder = (Join-Path (Split-Path -parent $PSCommandPath) "PowerShell")

$allpsm1 = Get-ChildItem -Path $scriptFolder -File *.psm1

if (-not (Test-Path $profile)) {
    New-Item -Path $profile -Type File
}

foreach ($psm1 in $allpsm1) {
    if (-not (Select-String -Path $profile -SimpleMatch -Pattern ($psm1.FullName))) {
        Add-Content -Path $profile -Value ("`r`n`r`nImport-Module " + $psm1.FullName )
    }
}