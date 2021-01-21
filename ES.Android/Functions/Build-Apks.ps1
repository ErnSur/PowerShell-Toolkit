function Build-APKS {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $AabPath,
        [Parameter(ParameterSetName = "Keystore", Mandatory)]
        [string] $KeystorePath,
        [Parameter(ParameterSetName = "Keystore", Mandatory)]
        [string] $KeystorePass,
        [Parameter(ParameterSetName = "Keystore", Mandatory)]
        [string] $KeystoreAlias,
        [Parameter(ParameterSetName = "Keystore")]
        [string] $KeyPass,
        [string] $BundletoolArgs,
        [switch] $Force
    )
    process {
        $apksPath = [io.path]::ChangeExtension($AabPath, ".apks")
        Write-Host "Extracting apks" -ForegroundColor Yellow
        if (!$Force -and (Test-Path $apksPath)) {
            Write-Error "$apksPath already exists."
            return $apksPath
        }
        $arg = @{
            'KeystorePath' = "--ks=""$KeystorePath"""
            'KeystorePass' = "--ks-pass=""pass:$KeystorePass"""
            'KeystoreAlias' = "--ks-key-alias=""$KeystoreAlias"""
            'KeyPass' = "--key-pass=""pass:$KeyPass"""
            'Force' = "--overwrite"
            'BundletoolArgs' = "$BundletoolArgs"
        }

        $command = "bundletool build-apks --bundle=""$AabPath"" --output=""$apksPath"" "
        $command += $arg.getenumerator() | Where-Object { $PSBoundParameters.ContainsKey($_.Key) } | Select-Object -ExpandProperty Value | Join-String -Separator " "
        & $command

        Write-Host "Build apks finished"
        return $apksPath
    }
}