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
        $NoConfigs,
        [switch]
        $DetailedOutput,
        [string] 
        $UseNugetConfig = ""
    )
    DynamicParam
    {
        $ParamAttrib  = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttrib.ParameterSetName  = '__AllParameterSets'
        $AttribColl = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]
        $AttribColl.Add($ParamAttrib)
        $siteNamesList  = GetProjectListFromConfig
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
        
        if($ConfigFile -eq $null -or $ConfigFile -eq "")
        {
            Write-Output "Config missing: '$ConfigFile'"
            return
        }
        
        $Config = [Config](Get-Content $ConfigFile | Out-String | ConvertFrom-Json)
        
        Set-Variable -Scope Script -Name PublishFolder -Value $Config.PublishPath
        Set-Variable -Scope Script -Name DevFolder -Value $Config.SourcePath
        Set-Variable -Scope Script -Name ProfilesFolder -Value $Config.PublishProfilesPath
        
        $AllProjects = $Config.Sites
        
        if ($List -eq $true)
        {
            Write-Output "Available Projects"
            $AllProjects | Format-Table 
            return
        }

        $SiteName = $PSBoundParameters.SiteName
        
        $Projects = $AllProjects | Where-Object {  $SiteName -eq $null -or $SiteName -ceq $_.Name }
        
        if ($Projects -eq $null -or ($Projects -is [system.array] -and $Projects.Count -le 0))
        {
            Write-Output "No Projects to Publish"
            break
        }
        
        Write-Output "Projects to Publish"
        $Projects | Format-Table -Property Name, PublishProfile
              
        foreach ($project in $Projects)
        {
            if ($project -eq $null) { break }
            
            $startMessage = "---- Starting Project $($project.Name) ----"
            $endMessage = "---- Completed Project $($project.Name) ----"
            Write-Output ""
            Write-Output $startMessage
            if ((Get-Website $project.Name) -eq $null)
            {
                Write-Host "Website not found. The name in the config may not match your site."
                continue
            }
            Write-Output "Stopping website..."
            Stop-Website $project.Name
            if(!$NoDelete){ DeletePublishFolder $project }
            if(!$NoPublish) { BuildAndPublish $project $UseNugetConfig $DetailedOutput }
            if(!$NoConfigs) { CopyConfigs $project }
            Write-Output "Restarting website..."
            Start-Website $project.Name
            Write-Output $endMessage
            Write-Output ""
        }
    }
    
    end {        
    }
}

function GetProjectListFromConfig()
{
    $configPath = getDefaultConfigFile $ConfigFile

    if($configPath -eq $null -or $configPath -eq "")
    {
        return @("No config file found");
    }
    
    return [SiteDetail[]](Get-Content ($configPath) | Out-String | ConvertFrom-Json).Sites | Select-Object -ExpandProperty Name
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

function BuildAndPublish($Project, $UseNugetConfig, $DetailedOutput)
{
    $solutionPath = "$DevFolder\$($Project.SolutionPath)"
    $publishProfile = $($Project.PublishProfile)
    $profileBuildDestination = "$($Project.PublishProfileTargetPath)\$publishProfile.pubxml"
 
    Write-Output "Building $solutionPath"
    Copy-Item "$ProfilesFolder\$publishProfile.pubxml" $profileBuildDestination -Verbose

    $args = @()
    $args += $solutionPath
    $args += "/t:""restore;clean;build"""
    $args += "/p:DeployOnBuild=true"
    $args += "/p:PublishProfile=""$publishProfile"""
    
    if ($DetailedOutput -ne $true)
    {
        $args += "/clp:""ErrorsOnly"""
    }

    if ($UseNugetConfig -ne $null -and $UseNugetConfig -ne "")
    {
        $args += "/p:RestoreConfigFile=""$UseNugetConfig"""
    }
        
    msbuild $args
    
    Remove-Item $profileBuildDestination -Verbose
}

function CopyConfigs($Project)
{
    $configSource = "$PublishFolder\_Configs\$($Project.PublishFolder)"
    $configDestination  = "$PublishFolder\$($Project.PublishFolder)"
    
    if ((Test-Path $configSource) -eq $true)
    {
        Write-Output "Publishing config files: $configSource"
        Get-ChildItem -Path "$configSource" | Copy-Item -Destination "$configDestination" -Recurse -Verbose -ErrorAction Ignore
        
        # $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
        # $xslt.Load("MyTransform.xsl")
        # $xslt.Transform("MyXMLFile.xml","MyOutput.WhatEver")

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

        $Script:IsConfigError = $true;
    } else {
        $Script:IsConfigError = $true;
        return $parameterValue        
    }
}

class Config
{
    [string]$PublishPath
    [string]$SourcePath
    [string]$PublishProfilesPath
    [SiteDetail[]]$Sites
}

class SiteDetail
{
    [string]$Name
    [string]$PublishFolder
    [string]$SolutionPath
    [string]$PublishProfile
    [string]$PublishProfileTargetPath
}

Set-Alias IIS-PublishProject Publish-ProjectToIIS

function Register-IISWebsites {
    param (
        [Parameter(
            Mandatory=$true,
            Position = 0,
            HelpMessage = "Path to publish settings.")]
        [Alias("ConfigPath")]
        [string]
        $publishConfig,

        [Parameter(
            Position = 1,
            HelpMessage = "Path to publish folder.")]
        [Alias("PublishPath")]
        [string]
        $publishFolder = "C:\publish",
    
        [Parameter(
            Position = 2)]
        [string]
        $certName = "IIS Express Development Certificate"
    )

    begin {
        $certStoreMy = "cert:\LocalMachine\My"
        $certStoreRoot = "cert:\LocalMachine\Root"
        Import-Module WebAdministration                
    }
    
    process {
        
        $MyCert = (Get-ChildItem $certStoreMy | 
            Where-Object { $_.FriendlyName -like "*$certName*" } |
            Select-Object -First 1)

        if ($MyCert -eq $null) {
            Write-Output "Cert $certName not found!"
            exit 1
        }

        $cert = $MyCert.Thumbprint

        if ((Test-Path "$certStoreRoot\$cert") -eq $false) {
            $rootStore = Get-Item -Path $certStoreRoot
            $rootStore.open("ReadWrite")
            $rootStore.add($MyCert)
            $rootStore.close()
        }

        $WebSites = [WebSiteDetail[]](Get-Content $publishConfig | Out-String | ConvertFrom-Json)

        foreach ($website in $websites) {
            remove-WebSite -Name $website.Name -ErrorAction SilentlyContinue
            remove-WebAppPool -name $website.Name -ErrorAction SilentlyContinue
        }

        foreach ($website in $websites) {
            $siteName = $website.Name 
            $sitePort = $website.Port 
            $protocol = $website.Protocol 
            $netTcpBinding = $website.NetTcpBinding
            $sitePath = "$publishFolder\$siteName"

            "*** Processing $siteName ***"

            New-Item -ItemType directory "$sitePath" -Force -ErrorAction SilentlyContinue

            New-WebAppPool -name $siteName

            $newSiteParameters = @{
                'Name'            = $siteName;
                'PhysicalPath'    = "$sitePath";
                'ApplicationPool' = $siteName;
                'Port'            = $sitePort;
            }

            if ($protocol -eq "https") {
                $newSiteParameters['ssl'] = $true
                $newSiteParameters['SslFlags'] = 0
            }

            New-WebSite @newSiteParameters

            if ($protocol -eq "https") {
                $binding = Get-WebBinding -Name $siteName -Protocol $protocol
                $binding.AddSslCertificate($cert, "my")
            }

            if ($netTcpBinding -ne $null -and $netTcpBinding -ne "") {
                Set-ItemProperty "IIS:\Sites\$siteName" -name EnabledProtocols -Value "http,net.tcp"
                New-ItemProperty -path "IIS:\Sites\$siteName" -name bindings -value @{protocol = "net.tcp"; bindingInformation = "$netTcpBinding" }
            }
        }
    }
    
    end {
        
    }
}

class WebSiteDetail {
    [string]$Name
    [int]$Port
    [string]$NetTcpBinding
    [string]$Protocol = "https"
}

Set-Alias IIS-RegisterWebsites Register-IISWebsites
