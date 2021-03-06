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

        $Jobs = (Get-ChildItem -Recurse -Depth 2 -Force | 
            Where-Object { $_.Mode -match "h" -and $_.FullName -like "*\.git" -and ($filter -eq $null -or ($filter -contains (Get-Item "$($_.FullName)/..").Name)) } |
                    Start-RSJob -Name {"$_"} -ScriptBlock {
                        Param ($gitPath) 
                        
                        Set-Location "$($gitPath.FullName)/.."
                        $repo = (Get-Item .).Name
                        $curBranch = git branch --show-current

                        $repoLine = "$repo [$curBranch] - "

                        if ($curBranch -ne "develop" -and $curBranch -ne "master")
                        {
                            Write-Output ($repoLine + "skipping, not on develop or master branch") # -ForegroundColor "Red" -BackgroundColor "Black"
                            return
                        }
                        
                        Write-Output ($repoLine + "Fetching") #-ForegroundColor "Yellow"
                    
                        #Write-Host "Updating" $repo [$curBranch]

                        #Write-Host "$repo - Updating remotes & pruning branches"
                        git remote update --prune

                        $localRev  = (git rev-parse HEAD)
                        $remoteRev = (git rev-parse "@{u}")
                        if ($localRev -eq $remoteRev)
                        {
                            Write-Output "Allready up to date" #-ForegroundColor "Green"
                        }
                        else
                        {
                            Write-Output "Pulling latest" #-ForegroundColor "Yellow"
                            git pull
                            #Write-Host "- Pulled latest" -ForegroundColor "Yellow"
                        }
                    })                    
                
                $CompletedJobs = @()

                while ($Jobs.State -contains "Running" -or $Jobs.State -contains "NotStarted"){ 
                            
                    $CompletedJobs = ($Jobs | Where-Object -Property State -eq "Completed")

                    if ($CompletedJobs.count -ne 0) {
                        Write-Host "." -ForegroundColor Yellow; 
                        $Jobs = $Jobs | Where-Object { $CompletedJobs -notcontains $_ }
                        $CompletedJobs | Receive-RsJob
                        $CompletedJobs | Remove-RsJob
                    }
                    Write-Host "." -NoNewline -ForegroundColor Yellow; 
                    Start-Sleep -Milliseconds 100 
                }

                if ($Jobs.count -ne 0) {
                    Write-Host "." -ForegroundColor Yellow; 
                }

                $Jobs | Wait-RSJob | Receive-RsJob
                $Jobs | Remove-RsJob

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

function Get-GitRepos 
{
    param (
        [Parameter(Mandatory=$False)]
        [string]
        $Path,
        [Parameter(Mandatory=$False)]
        [string[]]
        $IncludeBranch,
        [Parameter(Mandatory=$False)]
        [string[]]
        $ExcludeBranch
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
                        $gitPath = $_
                        
                        Set-Location "$($gitPath.FullName)/.."
                        $location = Get-Location

                        $repo = (Get-Item .).Name

                        Write-Progress -Activity "Getting Git Repo Details" -Status "$repo"

                        $curBranch = git branch --show-current

                        $process = $true;

                        if ($IncludeBranch.Count -gt 0 -and -not ($IncludeBranch -contains $curBranch))
                        {
                            $process = $false;
                        }

                        if ($ExcludeBranch.Count -gt 0 -and $ExcludeBranch -contains $curBranch)
                        {
                            $process = $false;
                        }

                        if ($process)
                        {
                            $gitRepo = New-Object PSObject
                            $gitRepo | Add-Member NoteProperty Name $repo
                            $gitRepo | Add-Member NoteProperty Branch $curBranch
                            $gitRepo | Add-Member NoteProperty Path $($location.Path)
                            $gitRepo
                        }
                    }

    }
    
    end {        
        Pop-Location
    }
}

Set-Alias Git-GetRepos Get-GitRepos

function Reset-GitLocalBranches()
{
    param (
        [Parameter(Mandatory=$False)]
        [string[]]
        $Branch,
        [Parameter(Mandatory=$False)]
        [string]
        $Path
    )

    begin {
        Push-Location
    }
    
    process {

        if ($Branch -eq $null -or $Branch -eq "")
        {
            $Branch = "develop"
        }

        $repos = Get-GitRepos | Where-Object {$_.Branch -ne $Branch} 
        $repos | ForEach-Object { Reset-GitLocalBranch -Path $_.Path -Branch $Branch }

    }
    
    end {        
        Pop-Location
    }

}

Set-Alias Git-ResetLocalBranches Reset-GitLocalBranches

function Reset-GitLocalBranch()
{
    param (
        [Parameter(Mandatory=$False)]
        [string[]]
        $Branch,
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

        if ($Branch -eq $null -or $Branch -eq "")
        {
            $Branch = "develop"
        }

        $repo = [System.IO.Path]::GetFileName($(Get-Location))

        $matchBranch = git branch --list $Branch

        git fetch

        if ($matchBranch -ne $null)
        {
            git checkout $Branch
            if ($LastExitCode -eq 0) 
            {
                git branch --list | Where-Object {$_ | Select-String -NotMatch " $Branch$" } | foreach-object { git branch -D $_.Trim() }
            }
            git pull
        }
        else {
            Write-Output "$repo does not have a local branch named $Branch."
        }

    }
    
    end {        
        Pop-Location
    }

}

Set-Alias Git-ResetLocalBranch Reset-GitLocalBranch
