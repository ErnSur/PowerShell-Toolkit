$aaptPath = (Join-Path $PSScriptRoot Tools aapt2) + ($IsWindows ? ".exe" : $null);
$bundletoolPath = (Join-Path $PSScriptRoot Tools "bundletool-all-1.4.0.jar");
Set-Alias aapt $aaptPath
function bundletool {
    java -Xmx1g -jar $bundletoolPath $args
}

function Get-ApkPermissions($ApkPath) {
    aapt dump permissions $ApkPath
}

function Get-ApkManifest($ApkPath) {
    aapt dump badging $ApkPath
}

function Get-ApkPackageName($ApkPath) {
    aapt dump packagename $ApkPath
}

#pnames
function Get-AndroidDevicePackages {
    adb shell pm list packages -f | ConvertFrom-StringData | Format-Table -AutoSize
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

function Uninstall-AndroidApp {
    Param(
        [Parameter(ParameterSetName = 'Name', ValueFromPipeline)]
        [string]$Name,
        [Parameter(ParameterSetName = 'Path')]
        [string]$Path
    )
    if ($PSBoundParameters.ContainsKey("Path")) {
        $Name = Get-ApkPackageName "$Path"
    }
    adb shell pm uninstall "$Name"
}

function Export-Apk($packageName) {
    $apkPath = (adb shell pm path $packageName | ConvertFrom-StringData -Delimiter ":").Values[0]
    adb pull $apkPath
}

function Install-AndroidApp {
    param (
        [Parameter(Mandatory, ValueFromPipeline,
            HelpMessage = "Path to apk, apks or aab file.")]
        [string] $Path
    )
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

    $extension = $Path.Split(".")[-1]
    $deviceIds = Get-AdbDevices | ForEach-Object { $_.Id }
    switch ($extension) {
        'apk' {
            $deviceIds | ForEach-Object { Install $extension $Path $_ };
            Break
        }
        'aab' {
            $Path = Build-APKS $Path
        }
        { 'apks' -or 'aab' } { 
            $deviceIds | ForEach-Object { Install 'apks' $Path $_ }
        }
        Default {
            Write-Host "File format not recognizable."
        }
    }
}

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
    Write-Host "Extracting apks" -ForegroundColor Yellow
    if (!$Force -and (Test-Path $apksPath)) {
        Write-Host "$apksPath already exists."
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

    Write-Host "Exported $aabFileName to $apksPath"
    return $apksPath
}

