function New-Dacpac {

    param (
        [ValidateScript({Test-Path $_ })]
        [string]
        $ProjectPath,

        [ValidateScript({Test-Path $_ })]
        [string]
        $MSBuild = "MSBuild.exe", # C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\

        [ValidateNotNullOrEmpty()]
        [string]
        $Target = "Build",

        [ValidateNotNullOrEmpty()]
        [string]
        $Configuration = "Debug"

    )

    $projectFile = Get-Item $projectPath
    $projectName = $projectFile.BaseName
    $projectFolderPath = $projectFile.Directory
    $dacpacPath = "$projectFolderPath\bin\$Configuration\$projectName.dacpac"

    if ( -not ( Test-Path $dacpacPath )) {
        Write-Debug "Build $ProjectPath"
        & $MSBuild $ProjectPath /t:$Target /p:Configuration=$Configuration
        Write-Debug "$dacpacPath created."
    }

    Test-Path $dacpacPath | Should -Be $true

    $dacpacPath
}