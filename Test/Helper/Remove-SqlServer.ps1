function Remove-SqlServer {

    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $DockerContainerName
    )

    if ( Get-DockerContainer | Where-Object names -eq $DockerContainerName ) {
        Stop-DockerContainer -Name $DockerContainerName
        Remove-DockerContainer -Name $DockerContainerName
    }
}