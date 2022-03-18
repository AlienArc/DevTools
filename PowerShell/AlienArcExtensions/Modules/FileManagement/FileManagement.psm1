<#
.SYNOPSIS
Removes all directories under path that have no files.
.PARAMETER Path
Specifies a path. The default location is the current directory (.).
#>
Function Remove-EmptyChildDirectories
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [PSDefaultValue(Help='Current directory.')]
        [Alias("PSPath")]
        [string[]]$Path='.'
    )

    BEGIN {}
    PROCESS {

        $items = (Get-ChildItem -Recurse -Path $Path | Sort-Object @{expression = {$_.fullname.length}} -descending)

        foreach($item in $items)
        {
                if( $item.PSIsContainer )
                {
                    $subitems = Get-ChildItem -Recurse -Path "$($item.FullName)"
                    if($subitems -eq $null)
                    {
                            "Removing: " + $item.FullName
                            Remove-Item $item.FullName
                    }
                    $subitems = $null
                }
        }

    }
    END {}
}

<#
.SYNOPSIS
Resets directory permission inheritance for path and all items contained.
.PARAMETER Path
Specifies a path. The default location is the current directory (.).
#>
function Reset-DirectoryInheritance 
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [PSDefaultValue(Help='Current directory.')]
        [Alias("PSPath")]
        [string[]]$Path='.'
    )

    BEGIN {
    }
    PROCESS {
        foreach ($p in $Path)
        {
            $actualpath = (get-item $p -ErrorAction SilentlyContinue)            
            if ($null -eq $actualpath)  
            {
                Write-Error "Path '$p' does not exist"
                continue
            }
            Write-Output "Processing '$($actualpath.FullName)'"
	        icacls "$($actualpath.FullName)" /T /Q /C /RESET
        }
    }
    END {}
}

<#
.SYNOPSIS
Sets directory ownership to current user for path and all items contained.
.PARAMETER Path
Specifies a path. The default location is the current directory (.).
.PARAMETER Administrator
Instead of setting ownership to current user, ownership is set to local Administrator group
.PARAMETER Recurse
If path is a directory then set ownership recursively on children
#>
function Set-DirectoryOwnership
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [PSDefaultValue(Help='Current directory.')]
        [Alias("PSPath")]
        [string[]]$Path='.',
        [Parameter(Mandatory=$False)]
        [switch]
        [Alias("A")]
        $Administrator,
        [Parameter(Mandatory=$False)]
        [switch]
        [Alias("R")]
        $Recurse
    )

    BEGIN {
    }
    PROCESS {
        foreach ($p in $Path)
        {
            $actualpath = (get-item $p -ErrorAction SilentlyContinue)            
            if ($null -eq $actualpath)  
            {
                Write-Error "Path '$p' does not exist"
                continue
            }
            $recurseFlag = ""
            if ($actualpath -is [System.IO.DirectoryInfo] -and $Recurse)
            { 
                $recurseFlag = "/R"
            }
            Write-Output "Processing '$($actualpath.FullName)'"
            $AdminFlag = ""
            if ($Administrator) 
            {
                $AdminFlag = "/A"
            }
            takeown $AdminFlag $recurseFlag /F "$($actualpath.FullName)"
        }
    }
    END {}
}