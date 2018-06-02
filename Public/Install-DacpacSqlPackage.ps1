function Install-DacpacSqlPackage
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
        $SqlPackagePath = "sqlpackage.exe" # C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\
    )

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.Filename = $SqlPackagePath
    $process.StartInfo.Arguments = `
        "/Action:Publish",
        "/SourceFile:$DacpacPath",
        "/TargetUser:$( $Credential.GetNetworkCredential().username )",
        "/TargetPassword:$( $Credential.GetNetworkCredential().password )",
        "/TargetServerName:$ServerInstance",
        "/TargetDatabaseName:$DatabaseName"
    $process.StartInfo.RedirectStandardOutput = $True
    $process.StartInfo.RedirectStandardError = $True
    $process.StartInfo.UseShellExecute = $false
    $process.Start()
    $process.WaitForExit()
    [string] $output = $process.StandardOutput.ReadToEnd();
    [string] $error = $process.StandardError.ReadToEnd();

    Write-Debug $output
    Write-Error $error

    if ( $error ) {
        throw $error
    } else {
        Write-Debug "Dacpac $DackpackPath deloyed."
    }
}