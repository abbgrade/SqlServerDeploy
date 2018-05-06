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

    $ps = New-Object System.Diagnostics.Process
    $ps.StartInfo.Filename = $SqlPackagePath
    $ps.StartInfo.Arguments = `
        "/Action:Publish",
        "/SourceFile:$DacpacPath",
        "/TargetUser:$( $Credential.GetNetworkCredential().username )",
        "/TargetPassword:$( $Credential.GetNetworkCredential().password )",
        "/TargetServerName:$ServerInstance",
        "/TargetDatabaseName:$DatabaseName"
    $ps.StartInfo.RedirectStandardOutput = $True
    $ps.StartInfo.RedirectStandardError = $True
    $ps.StartInfo.UseShellExecute = $false
    $ps.Start()
    $ps.WaitForExit()
    [string] $output = $ps.StandardOutput.ReadToEnd();
    [string] $error = $ps.StandardError.ReadToEnd();

    Write-Debug $output

    if ( $error ) {
        throw $error
    } else {
        Write-Debug "Dacpac $DackpackPath deloyed."
    }
}