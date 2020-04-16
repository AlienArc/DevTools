function EnsureElevated {
    $isAdmin = [bool](([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))

    if (-not $isAdmin)
    {
        Write-Output "!! Run this script with administrator privileges !!"
        exit 1
    }
}

function EnsureProfileExists {
    Set-Variable -Scope script -name p -Value $PROFILE.CurrentUserAllHosts

    if (-not (Test-Path $p)) {
        Write-Output "No profile script detected, creating empty profile: $p"
        New-Item -Path $p -Type File > $null
    }
}

function AddModule ($module)
{
    if (-not (Select-String -Path $p -SimpleMatch -Pattern (" $module"))) {
        Add-Content -Path $p -Value ("`r`n`r`nImport-Module $module") -NoNewline
        Write-Output "Added: Import-Module $module"
    }
}

function InstallModule ($moduleName) 
{
    $module = (Get-Module -ListAvailable -Name $moduleName)
    if ($null -ne $module) { 
        Write-Output "$moduleName installed: $($module.Version)"
    } else { 
        Write-Output "Installing $moduleName" 
        Install-Module $moduleName -Scope CurrentUser -AllowClobber
    }    
    AddModule $moduleName
}

function InstallToolModules {
    $scriptFolder = (Join-Path (Split-Path -parent $PSCommandPath) "PowerShell")
    $allpsm1 = Get-ChildItem -Path $scriptFolder -File *.psm1

    foreach ($psm1 in $allpsm1) {
        AddModule $psm1.FullName
    }
}

EnsureElevated
EnsureProfileExists

InstallModule "PSCX"
InstallModule "posh-git"

InstallToolModules