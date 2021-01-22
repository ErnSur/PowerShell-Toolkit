function Get-UnityProjectVersion {
    param
    (
        [Parameter(Mandatory)]
        [string] $ProjectPath
    )

    $versionFilePath = Join-Path $ProjectPath ProjectSettings ProjectVersion.txt
    if(!(Test-Path $versionFilePath -PathType Leaf)) {
        Write-Error "Could not find project version at: $versionFilePath"
        return
    }

    $result = Select-String -Pattern "\d.*" -Path $versionFilePath | Select-Object -First 1 |
    ForEach-Object { $_.Matches[0].Value }

    if(!$result) {
        Write-Output "No Version found."
    }
    return $result
}