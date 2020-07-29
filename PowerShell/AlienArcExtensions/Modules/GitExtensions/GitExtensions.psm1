function Update-AllGitRepos {

    Push-Location

    Get-ChildItem -Recurse -Depth 2 -Force | 
        Where-Object { $_.Mode -match "h" -and $_.FullName -like "*\.git" } |
            ForEach-Object {
                Set-Location "$($_.FullName)/.."
                $repo = (Get-Item .).Name
                $curBranch = git branch --show-current
                if ($curBranch -ne "develop")
                {
                    Write-Host "$repo - skipping, not on develop branch" -ForegroundColor "Yellow"
                    continue
                }
            
                Write-Host "Updating" $repo [$curBranch]

                #Write-Host "$repo - Updating remotes & pruning branches"
                git remote update --prune

                $localRev  = (git rev-parse HEAD)
                $remoteRev = (git rev-parse "@{u}")
                if ($localRev -eq $remoteRev)
                {
                    Write-Host "$repo - Allready up to date"
                }
                else
                {
                    git pull
                    Write-Host "$repo - Pulled latest"
                }
            }

            
    Pop-Location

}
Set-Alias Git-UpdateRepos Update-AllGitRepos
