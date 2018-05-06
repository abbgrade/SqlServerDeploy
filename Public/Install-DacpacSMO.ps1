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
        $Credential
    )

    $databasePath = "SQLSERVER:\SQL\$ServerInstance\DEFAULT"
    New-PsDrive -Name DefaultSql -PSProvider SqlServer -Root $databasePath -Credential $Credential

    $sqlServer = Get-Item .

    ## Open a Common.ServerConnection to the same instance.
    $connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($sqlServer.ConnectionContext.SqlConnectionObject)
    $connection.Connect()
    $dacStore = New-Object Microsoft.SqlServer.Management.Dac.DacStore($connection)

    ## Load the DAC package file.
    $fileStream = [System.IO.File]::Open($DacpacPath, [System.IO.FileMode]::OpenOrCreate)
    $dacType = [Microsoft.SqlServer.Management.Dac.DacType]::Load($fileStream)

    ## Subscribe to the DAC deployment events.
    $dacStore.add_DacActionStarted({ Write-Host Starting at $( Get-Date ) :: $_.Description })
    $dacStore.add_DacActionFinished({ Write-Host Completed at $( Get-Date ) :: $_.Description })

    ## Deploy the DAC and create the database.
    $evaluateTSPolicy = $true
    $deployProperties = New-Object Microsoft.SqlServer.Management.Dac.DatabaseDeploymentProperties($connection,$DatabaseName)
    $dacStore.Install($dacType, $deployProperties, $evaluateTSPolicy)
    $fileStream.Close()
}