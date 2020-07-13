function Update-AllGitRepos {
    Get-ChildItem -Recurse -Depth 2 -Force | 
        Where-Object { $_.Mode -match "h" -and $_.FullName -like "*\.git" } |
            ForEach-Object {
                Set-Location $_.FullName
                Set-Location ../
                Write-Host "Updating" (Get-Location).Path [(git rev-parse --abbrev-ref HEAD)]
                git pull
                Set-Location ../
            }
}

Export-ModuleMember -Alias "Git-UpdateAllRepos" -Function "Update-AllGitRepos"