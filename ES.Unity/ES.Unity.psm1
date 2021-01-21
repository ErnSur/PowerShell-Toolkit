function Get-UnityProjectVersion {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string] $projectPath
    )

    $versionFilePath = Join-Path $projectPath ProjectSettings ProjectVersion.txt
    $result = Select-String -Pattern "\d.*" -Path $versionFilePath | Select-Object -First 1 | %{ $_.Matches[0].Value }
    if(!$result) {
        Write-Output "No Version found."
    }
    return $result
}