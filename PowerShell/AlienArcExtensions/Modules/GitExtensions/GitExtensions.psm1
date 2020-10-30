function Update-GitRepos {
    param (
        [Parameter(Mandatory=$False)]
        [string[]]
        $Filter,
        [Parameter(Mandatory=$False)]
        [string]
        $Path
    )

    begin {
        Push-Location
    }
    
    process {
        if ($Path -ne $null -and $Path -ne "")
        {
            set-location $Path
        }

        Get-ChildItem -Recurse -Depth 2 -Force | 
            Where-Object { $_.Mode -match "h" -and $_.FullName -like "*\.git" } |
                ForEach-Object {
                    
                    if ($filter -ne $null -and (($filter -contains (Get-Item "$($_.FullName)/..").Name) -eq $false)) 
                    {
                        return
                    }

                    Set-Location "$($_.FullName)/.."
                    $repo = (Get-Item .).Name
                    $curBranch = git branch --show-current

                    Write-Host "$repo [$curBranch] - " -NoNewline -ForegroundColor "White"

                    if ($curBranch -ne "develop" -and $curBranch -ne "master")
                    {
                        Write-Host "skipping, not on develop or master branch" -ForegroundColor "Red" -BackgroundColor "Black"
                        return
                    }
                
                    #Write-Host "Updating" $repo [$curBranch]

                    #Write-Host "$repo - Updating remotes & pruning branches"
                    git remote update --prune

                    $localRev  = (git rev-parse HEAD)
                    $remoteRev = (git rev-parse "@{u}")
                    if ($localRev -eq $remoteRev)
                    {
                        Write-Host "Allready up to date" -ForegroundColor "Green"
                    }
                    else
                    {
                        Write-Host "Pulling latest" -ForegroundColor "Yellow"
                        git pull
                        #Write-Host "- Pulled latest" -ForegroundColor "Yellow"
                    }
                }

    }
    
    end {        
        Pop-Location
    }

}

Set-Alias Git-UpdateRepos Update-GitRepos

function Set-GitCommitDate 
{
	Param(
		[Parameter(Mandatory=$True,Position=1)] $date
	)

	$formatedDate = [System.DateTimeOffset]::Parse($date).ToString("o")
	Write-Output "GIT Author/Comitter date environment variables set to '$formatedDate'."
	
	Set-Item ENV:GIT_AUTHOR_DATE "$formatedDate"
	Set-Item ENV:GIT_COMMITTER_DATE "$formatedDate"
}

Set-Alias Git-SetCommitDate Set-GitCommitDate

function Clear-GitCommitDate 
{
	Remove-Item ENV:GIT_AUTHOR_DATE
	Remove-Item ENV:GIT_COMMITTER_DATE
	Write-Output "GIT Author/Comitter date environment variables cleared."
}

Set-Alias Git-ClearCommitDate Clear-GitCommitDate
