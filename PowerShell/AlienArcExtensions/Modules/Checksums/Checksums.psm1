function Get-Checksum {    
    param (
        [Parameter(Position=1)]
        [ValidateSet("md5", "sha1", "sha256", "sha384", "sha512")] 
        $digest,

        [Parameter(Mandatory=$True,Position=2)] 
        [string]$path, 

        [Parameter(Mandatory=$False,Position=3)] 
        [string]$checksum
    )

    begin {
        
    }
    
    process {
        
        if ([System.String]::IsNullOrWhiteSpace($digest) -eq $true) { $digest = "md5" }

        $digest = $digest.ToLowerInvariant();

        "Doing $($digest.ToUpperInvariant()) checksum on '$path'"
        if ($Digest -eq "md5") { return Get-MD5Checksum $path $checksum }
        if ($Digest -eq "sha1") { return Get-SHAChecksum $path $checksum }
        if ($Digest -eq "sha256") { return Get-SHA256Checksum $path $checksum }
        if ($Digest -eq "sha384") { return Get-SHA384Checksum $path $checksum }
        if ($Digest -eq "sha512") { return Get-SHA512Checksum $path $checksum }

    }
}

function Get-MD5Checksum([Parameter(Mandatory=$True,Position=1)] [string]$path, [Parameter(Mandatory=$False,Position=2)] [string]$checksum)
{
	UsingID ($crypto = [System.Security.Cryptography.MD5]::Create()) { 
		return formatHash $crypto $path $checksum
	} 
}

function Get-SHAChecksum([Parameter(Mandatory=$True,Position=1)] [string]$path, [Parameter(Mandatory=$False,Position=2)] [string]$checksum)
{
	UsingID ($crypto = [System.Security.Cryptography.SHA1]::Create()) { 
		return formatHash $crypto $path $checksum
	} 
}

function Get-SHA256Checksum([Parameter(Mandatory=$True,Position=1)] [string]$path, [Parameter(Mandatory=$False,Position=2)] [string]$checksum)
{
	UsingID ($crypto = [System.Security.Cryptography.SHA256]::Create()) { 
		return formatHash $crypto $path $checksum
	} 
}

function Get-SHA384Checksum([Parameter(Mandatory=$True,Position=1)] [string]$path, [Parameter(Mandatory=$False,Position=2)] [string]$checksum)
{
	UsingID ($crypto = [System.Security.Cryptography.SHA384]::Create()) { 
		return formatHash $crypto $path $checksum
	} 
}

function Get-SHA512Checksum([Parameter(Mandatory=$True,Position=1)] [string]$path, [Parameter(Mandatory=$False,Position=2)] [string]$checksum)
{
	UsingID ($crypto = [System.Security.Cryptography.SHA512]::Create()) { 
		return formatHash $crypto $path $checksum
	} 
}

function formatHash
{
	Param(
		[Parameter(Mandatory=$True,Position=1)] $crypto,
		[Parameter(Mandatory=$True,Position=2)] $path, 
		[Parameter(Mandatory=$False,Position=3)] [string]$checksum
	)
	
    $esc = [char]0x1b

	UsingID ($fs = [System.IO.File]::OpenRead((resolve-path $path))) { 
		$hash = (($crypto.ComputeHash($fs) | foreach {$_.ToString("x2")}) -join '')
		if ([System.String]::IsNullOrWhiteSpace($checksum) -eq $False)
		{
			if ([System.String]::Compare($hash, $checksum, $True) -eq 0)
			{
				$hash += " ${esc}[32m(PASSED)${esc}[0m"
			}
			else
			{
				$hash += " ${esc}[31m(FAILED)${esc}[0m"
			}
		}
		#Write-Host $hash
		return $hash
	}
}

#From: http://weblogs.asp.net/adweigert/powershell-adding-the-using-statement
function UsingID {
    param (
        [System.IDisposable] $inputObject = $(throw "The parameter -inputObject is required."),
        [ScriptBlock] $scriptBlock = $(throw "The parameter -scriptBlock is required.")
    )
    
    Try {
        &$scriptBlock
    } finally {
        if ($inputObject -ne $null) {
            if ($inputObject.psbase -eq $null) {
                $inputObject.Dispose()
            } else {
                $inputObject.psbase.Dispose()
            }
        }
    }
}
