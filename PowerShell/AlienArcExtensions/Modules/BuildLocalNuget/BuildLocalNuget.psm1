function Get-ScriptDirectory {
    Split-Path -parent $PSCommandPath
}

function Get-CounterFile {
    Join-Path $env:userprofile ".nugetcounter"
}

function Get-NextBuild {
    $counterFile = Get-CounterFile
    if (-Not (Test-Path $counterFile)) {
        (Set-LastBuild 0) > $null
    }
    [int](Get-Content -Path $counterFile) + 1
}

function Set-LastBuild ($counter) {
    $counterFile = Get-CounterFile
    if (-Not (Test-Path $counterFile)) {
        New-Item -Path $counterFile -Type File
    }
    Set-Content -Path $counterFile -Value $counter 
}

function Publish-LocalNuGet {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            return $true 
        })]
        [string] $Path,
        [string] $Version = $null,
        [string] $UseNugetConfig = ""
    )

    if ($env:LocalNugetPath -ne $null) {
        $localNuget = (Get-Item $env:LocalNugetPath)
    } else {
        $localNuget = (Get-Item "C:\dev\localnuget\")        
    }

    if ($Version -eq "") {
        if ($env:LocalNugetVersion -ne $null) {
            $Version = $env:LocalNugetVersion
        } else {
            $Version = "1.0.0" 
        }
    }

    $build = Get-NextBuild

    $fullPath = (Get-Item $Path)
    $sln = Get-ChildItem -Path $fullPath -File *.sln

    $extraArgs = ""
    if ($UseNugetConfig -ne $null -and $UseNugetConfig -ne "")
    {
        $extraArgs = "/p:RestoreConfigFile=""$UseNugetConfig"""
    }

    msbuild $sln.FullName -t:restore,clean,pack -p:Version="$Version-local.$build" -p:AssemblyVersion="$Version.0" -p:FileVersion="$Version.0" -p:IncludeSymbols=true $extraArgs

    Get-ChildItem -Path $fullPath -File *.nupkg -Recurse | Move-Item -Destination $localNuget -Verbose

    Set-LastBuild $build
}
Set-Alias LN-Publish Publish-LocalNuGet

function Reset-LocalNuGetCounter {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $InitialValue = "0"
    )

    Set-LastBuild $InitialValue
}
Set-Alias LN-Reset Reset-LocalNuGetCounter

function Clear-LocalNuGet {

    if ($env:LocalNugetPath -ne $null) {
        $localNuget = (Get-Item $env:LocalNugetPath)
    } else {
        $localNuget = (Get-Item "C:\dev\localnuget\")        
    }

    Get-ChildItem -Path $localNuget | Remove-Item
}
Set-Alias LN-Clear Clear-LocalNuGet
