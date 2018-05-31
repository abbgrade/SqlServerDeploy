#Requires -Modules Pester, @{ ModuleName="PSDocker"; ModuleVersion="1.0.22" }

param (
    [string] $ServerAdminUsername = "sa",
    [string] $ServerAdminPassword = 'Passw0rd!',
    [string] $dockerContainerName = 'sqldeploytest'
)

$ErrorActionPreference = "Stop"
$DebugPreference = "Continue"
$VerbosePreference = "Continue"

if ( $PSScriptRoot ) { $ScriptRoot = $PSScriptRoot } else { $ScriptRoot = Get-Location }
$ModuleManifestPath = "$ScriptRoot\..\SqlServerDeploy.psm1"
Import-Module $ModuleManifestPath -Force

# New-Alias Install-Dacpac Install-DacpacSMO -Force
New-Alias Install-Dacpac Install-DacpacSqlPackage -Force

#region Helper Functions

. $ScriptRoot\Helper\New-Dacpac.ps1
. $ScriptRoot\Helper\New-SqlServer.ps1
. $ScriptRoot\Helper\Remove-SqlServer.ps1

#endregion

Describe 'Install-Dacpac Tests' {

    BeforeAll {
        try {
            # $dacpacPath = New-Dacpac -ProjectPath "$ScriptRoot\sql-server-samples\samples\databases\wide-world-importers\wwi-ssdt\wwi-ssdt\WideWorldImporters.sqlproj"
            $dacpacPath = New-Dacpac -ProjectPath "$ScriptRoot\HelloWorldDB\HelloWorldDB.sqlproj"
            $saCredential = New-Object System.Management.Automation.PSCredential( $ServerAdminUsername, ( ConvertTo-SecureString $ServerAdminPassword -AsPlainText -Force ))
            $dockerContainer = New-SqlServer -DockerContainerName $dockerContainerName -ServerAdminPassword $ServerAdminPassword -AcceptEula
            $serverInstance = $dockerContainer.Hostname
        } catch {
            Remove-SqlServer -DockerContainerName $dockerContainerName
            throw
        }
    }
    It 'Checks the SQL Server' {
        # Test-SqlConnection -ServerInstance $serverInstance -Credential $saCredential
    }
    It 'Installs a Dacpac' {
        $databaseName = ( Get-Item $dacpacPath ).BaseName
        Install-Dacpac -DacpacPath $dacpacPath `
            -ServerInstance $serverInstance `
            -DatabaseName $databaseName `
            -Credential $saCredential -DatabaseCredential
    }
    AfterAll {
        Remove-SqlServer -DockerContainerName $dockerContainerName
    }
}