function ExportFunctionWithAlias
{
    Param(
        [Parameter(Mandatory=$True,Position=1)] [string] $name,
        [Parameter(Mandatory=$True,Position=2)] [string] $command
    )
    Export-ModuleMember -function $command
    Set-Alias -name $name -value $command -Scope "script"	
    Export-ModuleMember -Alias $name
}

function Set-VisualStudioEnvironment
{
    Param(
        [ValidateSet(2008,2010,2012,2013,2015,2017,2019)] 
        [int] $Version 
    )
    
    if ($Version -eq 0) { $Version = 2019 }

    if ($Version -eq 2008) { VS-SetEnv2008 }
    if ($Version -eq 2010) { VS-SetEnv2010 }
    if ($Version -eq 2012) { VS-SetEnv2012 }
    if ($Version -eq 2013) { VS-SetEnv2013 }
    if ($Version -eq 2015) { VS-SetEnv2015 }
    if ($Version -eq 2017) { VS-SetEnv2017 }
    if ($Version -eq 2019) { VS-SetEnv2019 }
}

function VS-SetEnv2008()
{
    $vcargs = if ({$Pscx:Is64BitProcess}) {'amd64'} else {'x86'}
    $VS90VCVarsBatchFile = "${env:VS90COMNTOOLS}..\..\VC\vcvarsall.bat"
    Invoke-BatchFile $VS90VCVarsBatchFile $vcargs
}

function VS-SetEnv2010()
{
    $vcargs = if ({$Pscx:Is64BitProcess}) {'amd64'} else {'x86'}
    $VS100VCVarsBatchFile = "${env:VS100COMNTOOLS}..\..\VC\vcvarsall.bat"
    Invoke-BatchFile $VS100VCVarsBatchFile $vcargs
}

function VS-SetEnv2012()
{
    $vcargs = if ({$Pscx:Is64BitProcess}) {'amd64'} else {'x86'}
    $VS100VCVarsBatchFile = "${env:VS110COMNTOOLS}..\..\VC\vcvarsall.bat"
    Invoke-BatchFile $VS100VCVarsBatchFile $vcargs
}

function VS-SetEnv2013()
{
    $vcargs = if ({$Pscx:Is64BitProcess}) {'amd64'} else {'x86'}
    $VS100VCVarsBatchFile = "${env:VS120COMNTOOLS}..\..\VC\vcvarsall.bat"
    Invoke-BatchFile $VS100VCVarsBatchFile $vcargs
}

function VS-SetEnv2015()
{
    $vcargs = if ({$Pscx:Is64BitProcess}) {'amd64'} else {'x86'}
    $VS100VCVarsBatchFile = "${env:VS140COMNTOOLS}..\..\VC\vcvarsall.bat"
    Invoke-BatchFile $VS100VCVarsBatchFile $vcargs
}

function VS-SetEnv2017()
{
    $VS150VCVarsBatchFile = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\Tools\VsDevCmd.bat"
    Invoke-BatchFile $VS150VCVarsBatchFile
}

function VS-SetEnv2019()
{
    $VS150VCVarsBatchFile = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\Tools\VsDevCmd.bat"
    Invoke-BatchFile $VS150VCVarsBatchFile
}

function Invoke-MsBuildTerse { msbuild /clp:"ErrorsOnly;WarningsOnly" $args }

#Export-ModuleMember -Function ('Set-VisualStudioEnvironment','Invoke-MsBuildTerse')
ExportFunctionWithAlias 'VS-BuildTerse' 'Invoke-MsBuildTerse'
ExportFunctionWithAlias 'VS-LoadEnvironment' 'Set-VisualStudioEnvironment'
