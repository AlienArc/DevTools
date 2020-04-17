function addAliasForExport
{
	Param(
		[Parameter(Mandatory=$True,Position=1)] [string]$name,
		[Parameter(Mandatory=$True,Position=2)] [string]$command
	)
    Set-Alias -name $name -value $command -Scope "script"	
    Export-ModuleMember -Alias $name
}

function Reset-EntityFrameworkDatabase
{
	Param([Parameter(Mandatory=$True,Position=1)] [string]$DatabaseName)
	Param([Parameter(Mandatory=$True,Position=2)] [string]$ProjectPath)

    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Server=(localdb)\MSSQLLocalDB;Database=Master;Trusted_Connection=True;"
    $connection.Open()

    $singleUserModeCommand = New-Object System.Data.SqlClient.SqlCommand
    $singleUserModeCommand.CommandText = "alter database [$DatabaseName] set single_user with rollback immediate"
    $singleUserModeCommand.Connection = $connection
    Write-Output "Setting database [$DatabaseName] to single user mode..."
    $result = $singleUserModeCommand.ExecuteNonQuery()

    $dropCommand = New-Object System.Data.SqlClient.SqlCommand
    $dropCommand.CommandText = "drop database [$DatabaseName]"
    $dropCommand.Connection = $connection
    Write-Output "Dropping database [$DatabaseName]..."
    $result = $dropCommand.ExecuteNonQuery()

    $createCommand = New-Object System.Data.SqlClient.SqlCommand
    $createCommand.CommandText = "create database [$DatabaseName]"
    $createCommand.Connection = $connection
    Write-Output "Creating database [$DatabaseName]..."
    $result = $createCommand.ExecuteNonQuery()

    $connection.Close()

    Write-Output "Running EF database migrations..."
    dotnet ef database update --project $ProjectPath 
}

Export-ModuleMember -Function 'Reset-EntityFrameworkDatabase'
addAliasForExport 'EF-ResetDB' 'Reset-EntityFrameworkDatabase'