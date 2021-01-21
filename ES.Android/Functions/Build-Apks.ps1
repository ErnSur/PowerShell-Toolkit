function Build-APKS {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $AabPath,
        [string] $KeystorePath,
        [string] $KeystorePass,
        [string] $KeystoreAlias,
        [string] $KeyPass,
        [string] $BundletoolArgs,
        [switch] $Force
    )

    $apksPath = [io.path]::ChangeExtension($AabPath, ".apks")
    Write-Output "Extracting apks" -ForegroundColor Yellow
    if (!$Force -and (Test-Path $apksPath)) {
        Write-Output "$apksPath already exists."
        return $apksPath
    }

    $command = "bundletool build-apks --bundle=""$AabPath"" --output=""$apksPath"" "
    if ($PSBoundParameters.ContainsKey('KeystorePath')) {
        $command += "--ks=""$KeystorePath"" "
    }
    if ($PSBoundParameters.ContainsKey('KeystorePass')) {
        $command += "--ks-pass=""pass:$KeystorePass"" "
    }
    if ($PSBoundParameters.ContainsKey('KeystoreAlias')) {
        $command += "--ks-key-alias=""$KeystoreAlias"" "
    }
    if ($PSBoundParameters.ContainsKey('KeyPass')) {
        $command += "--key-pass=""pass:$KeyPass"" "
    }
    if ($PSBoundParameters.ContainsKey('Force')) {
        $command += "--overwrite "
    }
    if ($PSBoundParameters.ContainsKey('BundletoolArgs')) {
        $command += "$BundletoolArgs "
    }
    Invoke-Expression $command
    $aabFileName = Split-Path $AabPath -leaf

    Write-Output "Exported $aabFileName to $apksPath"
    return $apksPath
}