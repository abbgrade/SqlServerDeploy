function New-SqlServer {

    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $ServerAdminPassword,

        [ValidateNotNullOrEmpty()]
        [string]
        # $DockerImage = 'microsoft/mssql-server-linux:latest'
        $DockerImage = 'microsoft/mssql-server-windows-developer:latest',

        [string]
        $DockerContainerName,

        [switch]
        $AcceptEula
    )

    # prepare parameter
    if ( -not $AcceptEula ) {
        throw "Accept the Microsoft EULA with -AcceptEula"
    }
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

    # check image
    Install-DockerImage -Image $DockerImage

    # create container
    $container = New-DockerContainer `
        -Image $DockerImage `
        -Name $DockerContainerName `
        -Environment $environment `
        -Ports @{
            1433 = 1433
        } -Detach
    $container | Add-Member -NotePropertyName 'Hostname' -NotePropertyValue 'localhost'

    # check service status
    Add-Type -AssemblyName 'System.ServiceProcess'
    $service = Get-DockerService -ContainerName $container.Name -Name 'MSSQLSERVER'
    Write-Debug "Service '$( $service.Name )' is $( $service.Status )"
    if ( $service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running ) {
        throw "Service '$( $service.Name )' is not 'Running'."
    }

    # return
    $container
}