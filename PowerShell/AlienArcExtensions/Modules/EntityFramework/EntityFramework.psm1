function OpenLocalDb()
{
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Server=(localdb)\MSSQLLocalDB;Database=Master;Trusted_Connection=True;"
    $connection.Open()
    return $connection
}

function DropDatabase ([System.Data.SqlClient.SqlConnection]$Connection, [string]$DatabaseName, [string]$ProjectPath)
{    
    $singleUserModeCommand = New-Object System.Data.SqlClient.SqlCommand
    $singleUserModeCommand.CommandText = "alter database [$DatabaseName] set single_user with rollback immediate"
    $singleUserModeCommand.Connection = $Connection
    Write-Output "Setting database [$DatabaseName] to single user mode..."
    $result = $singleUserModeCommand.ExecuteNonQuery()

    $dropCommand = New-Object System.Data.SqlClient.SqlCommand
    $dropCommand.CommandText = "drop database [$DatabaseName]"
    $dropCommand.Connection = $Connection
    Write-Output "Dropping database [$DatabaseName]..."
    $result = $dropCommand.ExecuteNonQuery()
}

function EnsureDatabase ([System.Data.SqlClient.SqlConnection]$Connection, [string]$DatabaseName,[string]$ProjectPath)
{    
    $createCommand = New-Object System.Data.SqlClient.SqlCommand
    $createCommand.CommandText = "IF NOT EXISTS(SELECT * FROM sys.sysdatabases where name='$DatabaseName') create database [$DatabaseName]"
    $createCommand.Connection = $Connection
    Write-Output "Ensuring database [$DatabaseName] exists..."
    $result = $createCommand.ExecuteNonQuery()
}

function RunMigrationUpdate ([string]$ProjectPath)
{
    Write-Output "Running EF database migrations..."
    dotnet ef database update --project $ProjectPath 
}

function Reset-EntityFrameworkDatabase
{
	Param(
        [Parameter(Mandatory=$True,Position=1)] [string]$DatabaseName,
        [Parameter(Mandatory=$True,Position=2)] [string]$ProjectPath
    )

    $connection = OpenLocalDb

    DropDatabase $connection $DatabaseName $ProjectPath
    EnsureDatabase $connection $DatabaseName $ProjectPath
    RunMigrationUpdate $ProjectPath

    $connection.Close()
    
}
Set-Alias EF-ResetDB Reset-EntityFrameworkDatabase

function Update-EntityFrameworkDatabase
{
	Param(
        [Parameter(Mandatory=$True,Position=1)] [string]$DatabaseName,
        [Parameter(Mandatory=$True,Position=2)] [string]$ProjectPath
    )

    $connection = OpenLocalDb

    EnsureDatabase $connection $DatabaseName $ProjectPath
    RunMigrationUpdate $ProjectPath

    $connection.Close()

}
Set-Alias EF-UpdateDB Update-EntityFrameworkDatabase
