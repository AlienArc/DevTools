# Overview

This PowerShell module wraps up functionality to pack a solution (all packable projects in solution) and copy it to a local folder for use by NuGet. It increments a build number to allow multiple local builds while avoiding caching issues.

# Installation

1) Open a PowerShell terminal with administrative privileges
2) Enable the RemoteSigned execution policy (this allows you to load unsigned modules from your local disk, but requires anything on a server or the internet to be signed):
    ```PowerShell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
    ```
3) Download this PowerShell Module and put it somewhere useful (like your PowerShell profile folder, typically: `$home\Documents\WindowsPowerShell`)
    ```PowerShell
    Invoke-WebRequest "https://raw.github.com/alienarc/DevTools/PowerShell/BuildLocalNuget.psm1" -OutFile "$home\Documents\WindowsPowerShell\BuildLocalNuget.psm1"
    ```
4) Add the module import and configuration options to your PowerShell profile: 
    1) Open/create `profile.ps1`
        ```PowerShell
        code $PROFILE.CurrentUserAllHosts
        ```
    2) Add the following at the end of your `Profile.ps1`:
        ```PowerShell
        Import-Module BuildLocalNuget.psm1 
        $env:LocalNugetPath = "c:\dev\localnuget"
        $env:LocalNugetVersion = "1.1.1"
        ```
    3) Save & Close `profile.ps1`
5) Add a new `NuGet.config` file to a common root of your cloned repos (i.e. `c:\dev\NuGet.config`) and setup a new `PackageSource` called `local`:
    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <configuration>
        <packageSources>
            <add key="local" value="C:\dev\localnuget" />
        </packageSources>
    </configuration>
    ```
5) make sure the local NuGet folder exists (see below for customizing it)
    ```PowerShell
    New-Item "C:\Dev\LocalNuGet" -ItemType Directory
    ```
    
## optional configuration:

* `LocalNugetPath` By default this script will publish the NuGet packages to `c:\dev\localnuget`, if you want to use a different folder either edit the script or set the `LocalNugetPath` environment variable to the desired path if your profile:
    ```PowerShell
    $env:LocalNugetPath = "<Path to localnuget folder>"
    ```
* by default this script will use "1.0.0" for the base version, you can either pass in a version from the command or you can set `LocalNugetVersion` environment variable to the desired version:
    * add the following to your $Profile script: `$env:LocalNugetVersion = "1.2.3"`

# Usage

From a PowerShell command prompt (requires VS dev tool environment to be setup, i.e. can run `msbuild`):

## Publish-LocalNuGet 
Creates versioned NuGet package and places it in the local NuGet directory

### Usage

```PowerShell
Publish-LocalNuget [-Path] <directory containing a sln file> [-Version "1.2.3"]
```

Typical:
```PowerShell
Publish-LocalNuget .
```

### Parameters

#### Path [required]
The path containing the `*.sln` file(s) to build

#### Version [optional]
The version string to prepend onto the generated version #, defaults to `1.0.0` or the value of the `LocalNugetVersion` environment variable, if set.

### Function
This command will:
* Increment the local build number
* Run `msbuild -t:clean,restore,pack` with version # the solution(s) located in the `Path` parameter directory
* Move all created `.nupkg` files to the local NuGet path

## Reset-LocalNuGetCounter
* Will reset the counter file to 0, making the next build start at 1

### Usage
```PowerShell
Reset-LocalNugetCounter [[-InitialValue] "0"]
```

# Notes

* This script will build all packages defined in a solution using the default configuration with a version of `<version>-local.<id>` where `<version>` is the environment variable `LocalNugetVersion` (or `1.0.0` if not defined) and `<id>` is the next number from the counter stored in the file `.nugetcounter` in `UserProfile` path.
 