#Requires -Modules Pester

param (
    [string] $saUsername = "sa",
    [string] $saPassword = 'Passw0rd!',
    [string] $dockerContainerName = 'sqldeploytest'
)

$ErrorActionPreference = "Stop"
$DebugPreference = "Continue"

if ( $PSScriptRoot ) { $ScriptRoot = $PSScriptRoot } else { $ScriptRoot = Get-Location }
$ModuleManifestPath = "$ScriptRoot\..\SqlServerDeploy.psm1"
Import-Module $ModuleManifestPath -Force

#region Helper Functions
function New-Dacpac {

    param (
        [ValidateScript({Test-Path $_ })]
        [string]
        $ProjectPath,

        [ValidateScript({Test-Path $_ })]
        [string]
        $MSBuild = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"
    )

    $projectFile = Get-Item $projectPath

    $dacpacPath = "$( $projectFile.Directory )\bin\Debug\WideWorldImporters.dacpac"
    if ( -not ( Test-Path $dacpacPath )) {
        Write-Debug "Build $ProjectPath"
        & $MSBuild $ProjectPath
        Write-Debug "$dacpacPath created."
    }

    Test-Path $dacpacPath | Should Be $true

    $dacpacPath
}

function New-SqlServer {

    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $DockerContainerName,

        [ValidateNotNullOrEmpty()]
        [string]
        $SAPassword,

        [ValidateNotNullOrEmpty()]
        [string]
        # $DockerImage = 'microsoft/mssql-server-linux:2017-latest'
        $DockerImage = 'microsoft/mssql-server-windows-developer:2017-latest'
    )

    [string] $saParameter = $null
    if ( $DockerImage -match 'linux' ) {
        $saParameter = 'MSSQL_SA_PASSWORD'
    } elseif ( $DockerImage -match 'windows' ) {
        $saParameter = 'sa_password'
    } else {
        throw "not implemented"
    }

    docker pull $DockerImage | Write-Debug
    Write-Debug "Docker image $DockerImage pulled."

    docker run -e "ACCEPT_EULA=Y" `
        -e "$saParameter=$SAPassword" `
        -p 1433:1433 `
        --name $DockerContainerName `
        -d $DockerImage | Write-Debug
    Write-Debug "Docker container $DockerContainerName created."

    'localhost'
}

function Remove-SqlServer {

    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $DockerContainerName
    )

    if ( docker ps -f name=$DockerContainerName -q ) {
        docker stop $DockerContainerName | Write-Debug
        docker rm $DockerContainerName | Write-Debug
    }
}

#endregion

Describe 'Install-Dacpac Tests' {

    [string] $dacpacPath
    [string] $serverInstance
    [System.Management.Automation.PSCredential] $saCredential

    BeforeAll {
        $serverInstance = New-SqlServer -DockerContainerName $dockerContainerName -SAPassword $saPassword
        $saCredential = New-Object System.Management.Automation.PSCredential ($saUsername, ( ConvertTo-SecureString $saPassword -AsPlainText -Force ))
        $dacpacPath = New-Dacpac -ProjectPath "$ScriptRoot\sql-server-samples\samples\databases\wide-world-importers\wwi-ssdt\wwi-ssdt\WideWorldImporters.sqlproj"
    }
    # It 'Checks the SQL Server' {
    #     Get-SqlInstance -MachineName $serverInstance -Credential $saCredential
    # }
    It 'Installs a Dacpac' {
        $databaseName = ( Get-Item $dacpacPath ).BaseName
        Install-Dacpac -DacpacPath $dacpacPath -ServerInstance $serverInstance -DatabaseName $databaseName -Credential $saCredential
    }
    AfterAll {
        Remove-SqlServer -DockerContainerName $dockerContainerName
    }
}

