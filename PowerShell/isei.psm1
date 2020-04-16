function Reset-IseiDatabase
{
	Param([Parameter(Mandatory=$True,Position=1)] [string]$ProjectPath)

    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Server=(localdb)\MSSQLLocalDB;Database=Master;Trusted_Connection=True;"
    $connection.Open()

    $singleUserModeCommand = New-Object System.Data.SqlClient.SqlCommand
    $singleUserModeCommand.CommandText = "alter database isei set single_user with rollback immediate"
    $singleUserModeCommand.Connection = $connection
    Write-Output "Setting database [isei] to single user mode..."
    $result = $singleUserModeCommand.ExecuteNonQuery()

    $dropCommand = New-Object System.Data.SqlClient.SqlCommand
    $dropCommand.CommandText = "drop database isei"
    $dropCommand.Connection = $connection
    Write-Output "Dropping database [isei]..."
    $result = $dropCommand.ExecuteNonQuery()

    $createCommand = New-Object System.Data.SqlClient.SqlCommand
    $createCommand.CommandText = "create database isei"
    $createCommand.Connection = $connection
    Write-Output "Creating database [isei]..."
    $result = $createCommand.ExecuteNonQuery()

    $connection.Close()

    Write-Output "Running EF database migrations..."
    dotnet ef database update --project $ProjectPath  #C:\dev\AlienArc\Clients\ISEI\src\IseiCore\
}

Export-ModuleMember -Function 'Reset-IseiDatabase'