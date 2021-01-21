
$aaptPath = $IsWindows ? (Join-Path $PSScriptRoot Tools aapt2.exe) : (Join-Path $PSScriptRoot Tools aapt2);
$bundletoolPath = (Join-Path $PSScriptRoot Tools "bundletool-all-1.4.0.jar");
Set-Alias -Name aapt -Value $aaptPath
Set-Alias -Name log -Value Write-Host
function bundletool() {
    java -Xmx1g -jar $bundletoolPath $args
}

function Get-ApkPermissions($apkPath) {

    aapt dump permissions $apkPath
}

function Get-ApkManifest($apkPath) {
    & $aapt dump badging $apkPath
}

function Get-ApkPackageName($apkPath) {

}

#pnames
function Get-AndroidDevicePackages {
    adb shell pm list packages -f
}

function Restart-ADB {
    adb kill-server
    adb start-server
}

function Get-AdbDevices {
    function FirstCharToUpper($text) {
        return $text.substring(0, 1).ToUpper() + $text.substring(1)
    }

    $result = adb devices -l | Where-Object { $_.trim() -ne "" } | Select-Object -Skip 1 | ForEach-Object {
        $tsv = $_ -replace '\ \ +', ' Status:'
        $tsv = $tsv -replace '\ ', "`n"
        $tsv = "Id:" + $tsv
        $tsv = $tsv.Split() | ForEach-Object { FirstCharToUpper($_) } | Join-String -Separator "`n"
        $props = ConvertFrom-StringData -Delimiter ':' -StringData $tsv
        #$props.Keys | Write-Host
        return [PSCustomObject]$props
    }
    #return @($result | Format-Table -Property Id, Status, Model, Product)
    return @($result)
}

#region deploy
# For testing:
# Import-Module -Name ./PowerShell-Toolkit/ES.Android/ -Force

function Install-AndroidApp($filePath) {

    function Install($extension, $path, $deviceId) {
        Write-Host "Try Install to $deviceId" -ForegroundColor Yellow
        switch ($extension) {
            'apk' { adb -s $deviceId install -r "$path" }
            'apks' { bundletool install-apks --apks="$path" --device-id=$deviceId }
        }
        if ($?) {
            Write-Host "Success" -ForegroundColor Green
        }
        else {
            Write-Host "Failure" -ForegroundColor Red
        }
    }

    $extension = $filePath.Split(".")[-1]
    $deviceIds = Get-AdbDevices | ForEach-Object { $_.Id }
    switch ($extension) {
        'apk' {
            $deviceIds | ForEach-Object { Install $extension $filePath $_ };
            Break
        }
        'aab' {
            $filePath = Export-APKS $filePath
        }
        { 'apks' -or 'aab' } { 
            $deviceIds | ForEach-Object { Install 'apks' $filePath $_ }
        }
        Default {
            Write-Host "File format not recognizable."
        }
    }
}



function Export-APKS() {

    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $aabPath,
        [string] $keystorePath,
        [string] $keystorePass,
        [string] $keystoreAlias,
        [string] $keyPass
    )

    $apksPath = [io.path]::ChangeExtension($aabPath, ".apks")
    Write-Host "Extracting apks" -ForegroundColor Yellow
    if (Test-Path $apksPath) {
        Write-Host "$apksPath already exists."
        return $apksPath
    }

    $command = 'bundletool build-apks --bundle="$aabPath" --output="$apksPath" '
    if ($PSBoundParameters.ContainsKey('keystorePath')) {
        $command += '--ks="$keystorePath" '
    }
    if ($PSBoundParameters.ContainsKey('keystorePass')) {
        $command += '--ks-pass="pass:$keystorePass" '
    }
    if ($PSBoundParameters.ContainsKey('keystoreAlias')) {
        $command += '--ks-key-alias="$keystoreAlias" '
    }
    if ($PSBoundParameters.ContainsKey('keyPass')) {
        $command += '--key-pass="pass:$keyPass" '
    }
    Invoke-Command $command
    $aabFileName = Split-Path $aabPath -leaf

    Write-Host "Exported $aabFileName to $apksPath"
    return $apksPath
}

#endregion

