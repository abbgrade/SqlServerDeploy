function New-SqlServer {

    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $DockerContainerName,

        [ValidateNotNullOrEmpty()]
        [string]
        $ServerAdminPassword,

        [ValidateNotNullOrEmpty()]
        [string]
        # $DockerImage = 'microsoft/mssql-server-linux:2017-latest'
        $DockerImage = 'microsoft/mssql-server-windows-developer:2017-latest'
    )

    $environment = @{
        'ACCEPT_EULA' = "Y"
    }

    if ( $DockerImage -match 'linux' ) {
        $environment['MSSQL_SA_PASSWORD'] = $ServerAdminPassword
    } elseif ( $DockerImage -match 'windows' ) {
        $environment['sa_password'] = $ServerAdminPassword
    } else {
        throw "not implemented"
    }

    Install-DockerImage -Image $DockerImage
    New-DockerContainer `
        -Image $DockerImage `
        -Name $DockerContainerName `
        -Environment $environment `
        -Ports @{
            1433 = 1433
        } -Detach

    'localhost'
}