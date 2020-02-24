# Overview

This PowerShell module wraps up functionality to pack a solution (all packable projects in solution) and copy it to a local folder for use by nuget. It increments a build number to allow multiple local builds while avoiding caching issues.

# Installation

1) put this module somewhere useful (like your powershell profile folder, typically: $home\Documents\WindowsPowerShell)
2) enable unrestricted execution policy, or sign with your own code-signing cert (requires admin): Set-ExecutionPolicy Unrestricted
3) add the module to your powershell profile: <favorite Editor> $PROFILE
    a) Import-Module <Path-To-PSM1>\BuildLocalNuget.psm1 
4) setup a PackageSource in your Nuget.config (either profile, or root folder all your repos check out to)
    <?xml version="1.0" encoding="utf-8"?>
    <configuration>
    <packageSources>
        <add key="local" value="C:\dev\localnuget" />
    </packageSources>
    </configuration>
5) make sure the local nuget folder exists (see below for customizing it)

## optional configuration:

* by default this script will publish the nuget packages to c:\dev\localnuget, if you want to use a different foler either edit the script or set the LocalNugetPath environment variable to the desired path:
    * add the following to your $Profile script: $env:LocalNugetPath = "<Path to localnuget folder>"
* by default this script will use "1.0.0" for the base version, you can either pass in a version from the command or you can set LocalNugetVersion environment variable to the desired version:
    * add the following to your $Profile script: $env:LocalNugetVersion = "1.2.3"

# Notes

* This script will create a nupkg with a version of "1.0.0-local.<id>" where <id> is a counter stored in ".nugetcounter" in your home path.
 
# Usage

From a powershell command prompt (requires VS dev tool environment to be setup, i.e. can run msbuild):

## Publish-LocalNuget [-Path] <directory containing a sln file> [-Version "1.2.3"]
* Will increment the build number
* Will run a pack on the solution(s) located in the path parameter
* Will move all .nupkg files to local nuget path
* If Version is not specified than it defaults to "1.0.0" or LocalNugetVersion environment variable

## Reset-LocalNugetCounter
* Will reset the counter file to 0, making the next build start at 1
