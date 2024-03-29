#$stopWatch = new-object System.Diagnostics.StopWatch

#Loop through and load all submodules
$allModuleDirectories = Get-ChildItem $PSScriptRoot\Modules -Name

foreach ($currentModule in $allModuleDirectories)
{
    $subModuleBasePath = "$PSScriptRoot\Modules\{0}\{0}" -f $currentModule

    # Check for PSD1 first
    $path = "$subModuleBasePath.psd1"
    if (!(Test-Path -PathType Leaf $path)) 
    {
        # Assume PSM1 only
        $path = "$subModuleBasePath.psm1"
        if (!(Test-Path -PathType Leaf $path))
        {
            # Missing/invalid module
            Write-Warning "Module $path is missing."
            continue
        }
    }

    try {
        #$stopWatch.Reset()
        #$stopWatch.Start()

        Import-Module $path -DisableNameChecking 

        #$stopWatch.Stop()
        #$loadMessage = "-- $path Loaded in {0} ms" -f $stopWatch.ElapsedMilliseconds
        #Write-Host $loadMessage
    }
    catch {
        Write-Output "Module $currentModule load error: $_"
    }
}

