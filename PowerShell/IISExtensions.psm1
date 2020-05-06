function Publish-ProjectToIIS {
    param (
        [Parameter(Mandatory=$False,Position=1)]
        [string]
        $ConfigFile,
        [Parameter(Mandatory=$False)]
        [switch]
        $List,
        [Parameter(Mandatory=$False)]
        [switch]
        $NoDelete,
        [Parameter(Mandatory=$False)]
        [switch]
        $NoPublish,
        [Parameter(Mandatory=$False)]
        [switch]
        $NoConfigs
    )
    DynamicParam
    {
        $ParamAttrib  = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttrib.ParameterSetName  = '__AllParameterSets'
        $AttribColl = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]
        $AttribColl.Add($ParamAttrib)
        $siteNamesList  = [SiteDetail[]](Get-Content (getDefaultConfigFile $ConfigFile) | Out-String | ConvertFrom-Json).Sites | Select-Object -ExpandProperty SiteName
        #$configurationFileNames = (Get-Content (getDefaultConfigFile $ConfigFile) | Out-String | ConvertFrom-Json).Sites | Select-Object -ExpandProperty Name
        $AttribColl.Add((New-Object  System.Management.Automation.ValidateSetAttribute($siteNamesList)))
        $RuntimeParam  = New-Object System.Management.Automation.RuntimeDefinedParameter('SiteName',  [string[]], $AttribColl)
        $RuntimeParamDic  = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $RuntimeParamDic.Add('SiteName',  $RuntimeParam)
        return  $RuntimeParamDic
    }

    begin {
    }
    
    process {
                
        $ConfigFile = getDefaultConfigFile $ConfigFile
        
        if ((Test-Path $ConfigFile -PathType Leaf -ErrorAction Ignore) -eq $false)
        {
            Write-Output "Config missing: '$ConfigFile'"
            return
        }
        
        $Config = [Config](Get-Content $ConfigFile | Out-String | ConvertFrom-Json)
        
        Set-Variable -Scope Script -Name PublishFolder -Value $Config.PublishPath
        Set-Variable -Scope Script -Name DevFolder -Value $Config.SourcePath
        
        $AllProjects = $Config.Sites
        
        if ($List -eq $true)
        {
            Write-Output "Available Projects"
            $AllProjects | Format-Table #-Property Name,ProfileName,PublishSubFolder,SolutionSubPath
            return
        }

        $SiteName = $PSBoundParameters.SiteName
        
        $Projects = $AllProjects | Where-Object {  $SiteName -eq $null -or $SiteName -ceq $_.SiteName }
        
        if ($Projects -eq $null -or ($Projects -is [system.array] -and $Projects.Count -le 0))
        {
            Write-Output "No Projects to Publish"
            break
        }
        
        Write-Output "Projects to Publish"
        $Projects | Format-Table #-Property Name,ProfileName,PublishSubFolder,SolutionSubPath
        
        net stop W3SVC
        
        foreach ($project in $Projects)
        {
            if ($project -eq $null) { break }
            
            $startMessage = "---- Starting Project $($project.SiteName) ----"
            $endMessage = "---- Completed Project $($project.SiteName) ----"
            Write-Output ""
            Write-Output $startMessage
            if(!$NoDelete){ DeletePublishFolder $project }
            if(!$NoPublish) { BuildAndPublish $project }
            if(!$NoConfigs) { CopyConfigs $project }
            Write-Output $endMessage
            Write-Output ""
        }
        
        net start W3SVC

    }
    
    end {        
    }
}

function DeletePublishFolder($Project)
{
    $folderName = $Project.PublishFolder
    if ($folderName -eq $null -or $folderName -eq "") 
    {
        Write-Output "Attempting to Delete with no folder specified"
        return 
    }

    Write-Output "Deleting $folderName folder"
    Remove-Item "$PublishFolder\$folderName" -Recurse -Force -ErrorAction Ignore
}

function BuildAndPublish($Project)
{
    $solutionPath = "$DevFolder\$($Project.SolutionPath)"
    $publishProfile = $Project.PublishProfile 
    
    Write-Output "Building $solutionPath"
    msbuild "$solutionPath" /t:"restore;clean;build" /p:DeployOnBuild=true /p:PublishProfile="$publishProfile" /clp:"ErrorsOnly"
}

function CopyConfigs($Project)
{
    $configSource = "$PublishFolder\_Configs\$($Project.PublishFolder)"
    $configDestination  = "$PublishFolder\$($Project.PublishFolder)"
    
    if ((Test-Path $configSource) -eq $true)
    {
        Write-Output "Publishing config files: $configSource"
        Get-ChildItem -Path "$configSource" | Copy-Item -Destination "$configDestination" -Recurse -Verbose -ErrorAction Ignore
    }
}

function getDefaultConfigFile($parameterValue)
{
    if ($parameterValue -eq $null -or $parameterValue -eq "")
    {
        $testPath = "projects.json" 
        if (test-path $testPath) { return $testPath }

        if ($env:IISExtensions_PublishConfig -ne $null) {
            $testPath = $env:IISExtensions_PublishConfig
            if (test-path $testPath) { return $testPath }
        }

        $testPath = Join-Path $PSScriptRoot "projects.json"
        if (test-path $testPath) { return $testPath }                
    } else {
        return $parameterValue        
    }
}

class Config
{
    [string]$PublishPath
    [string]$SourcePath
    [SiteDetail[]]$Sites
}

class SiteDetail
{
    [string]$SiteName
    [string]$PublishFolder
    [string]$SolutionPath
    [string]$PublishProfile
}


Export-ModuleMember -Function "Publish-ProjectToIIS"