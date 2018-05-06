function Install-Dacpac
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

        [ValidateScript({Test-Path $_ })]
        [string]
        $SqlPackagePath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\sqlpackage.exe"
    )

    & "$SqlPackagePath" `
        /Action:Publish `
        /SourceFile:$DacpacPath `
        /TargetUser:$( $Credential.GetNetworkCredential().username ) `
        /TargetPassword:$( $Credential.GetNetworkCredential().password ) `
        /TargetServerName:$ServerInstance `
        /TargetDatabaseName:$DatabaseName | Write-Debug

}