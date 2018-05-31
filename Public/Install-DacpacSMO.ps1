foreach( $assemblyName in @(
    'Microsoft.SqlServer.Smo',
    'Microsoft.SqlServer.ConnectionInfo',
    'Microsoft.SqlServer.Dac' # https://www.microsoft.com/en-us/download/details.aspx?id=55114
)) {
    $assembly = [Reflection.Assembly]::LoadWithPartialName( $assemblyName )
    if ( -not $assembly ) {
        try {
            $assembly =  Add-Type -Path $ScriptRoot\..\bin\$assemblyName.dll
        } catch {
            $loaderException = $null
            if ( $_.Exception.LoaderExceptions ) {
                $loaderException = $_.Exception.LoaderExceptions[0]
            }
            Write-Warning "Failed to load assembly [$assemblyName] $loaderException"
        }
    }
}

function Install-DacpacSMO
{
    param (
        [ValidateScript({Test-Path $_ })]
        [string]
        $DacpacPath,

        [ValidateNotNullOrEmpty()]
        [string]
        $ServerInstance,

        [ValidateNotNullOrEmpty()]
        [string]
        $DatabaseName,

        [System.Management.Automation.PSCredential]
        $Credential,

        [switch]
        $DatabaseCredential
    )

    $connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection( $ServerInstance )

    if ( $DatabaseCredential ) {
        $connection.LoginSecure = $false
    }

    if ( $Credential ) {
        $connection.Login = $Credential.GetNetworkCredential().UserName
        $connection.Password = $Credential.GetNetworkCredential().Password
    }

    Write-Verbose "ConnectionString: $( $connection.ConnectionString )"
    $connection.Connect()

    # Connect to the local, default instance of SQL Server.
    $sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server( $connection )

    Write-Debug "Connected to SQL Server Version: '$( $sqlServer.Information.Version )'"

    # $databasePath = "SQLSERVER:\SQL\$ServerInstance\DEFAULT"
    # New-PsDrive -Name DefaultSql -PSProvider SqlServer -Root $databasePath -Credential $Credential
    # $sqlServer = Get-Item .

    # Open a Common.ServerConnection to the same instance.
    # $connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($sqlServer.ConnectionContext.SqlConnectionObject)
    # $connection.Connect()
    $dacStore = New-Object Microsoft.SqlServer.Management.Dac.DacStore($connection)

    # Load the DAC package file.
    $fileStream = [System.IO.File]::Open($DacpacPath, [System.IO.FileMode]::OpenOrCreate)
    $dacType = [Microsoft.SqlServer.Management.Dac.DacType]::Load($fileStream)

    # Subscribe to the DAC depl oyment events.
    $dacStore.add_DacActionStarted({ Write-Host Starting at $( Get-Date ) :: $_.Description })
    $dacStore.add_DacActionFinished({ Write-Host Completed at $( Get-Date ) :: $_.Description })

    # Deploy the DAC and create the database.
    $evaluateTSPolicy = $true
    $deployProperties = New-Object Microsoft.SqlServer.Management.Dac.DatabaseDeploymentProperties($connection,$DatabaseName)
    $dacStore.Install($dacType, $deployProperties, $evaluateTSPolicy)
    $fileStream.Close()
}