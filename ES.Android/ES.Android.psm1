function Get-DefaultSDKPath {
    if($IsWindows){
        return Join-Path $env:LOCALAPPDATA Android sdk
    }
    elseif ($IsMacOS) {
        return Join-Path $HOME Library Android sdk
    }
    elseif ($IsLinux) {
        return Join-Path $HOME Android Sdk
    }
}

function Install-AndroidCmdTools {
    sdkmanager "cmdline-tools;latest"
}

function Get-ApkManifest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $ApkPath,
        [ValidateSet("Id","Permissions","VersionName","VersionCode","MinSdk","TargetSdk","Debuggable")]
        [string] $Value = "print"
    )
    $arg = @{
       'Id' = "application-id"
       'Permissions' = "permissions"
       'VersionName' = "version-name"
       'VersionCode' = "version-code"
       'MinSdk' = "min-sdk"
       'TargetSdk' = "target-sdk"
       "Debuggable" = "debuggable"
       "print" = "print"
    }
    apkanalyzer manifest $arg["$Value"] $ApkPath
}
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
        return [PSCustomObject]$props
    }
    
    @($result)
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
        [string] $Path,
        [Parameter(ParameterSetName = 'AllDevices')]
        [switch] $AllDevices,
        [Parameter(ParameterSetName = 'SingleDevice')]
        [string] $DeviceId = (Get-AdbDevices | Select-Object -First 1)
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
    $deviceIds = $AllDevices ? (Get-AdbDevices | ForEach-Object { $_.Id }) : $DeviceId
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

function Initialize-SDKPath {
    if($null -eq $env:AndroidSDK){
        $env:AndroidSDK = Get-DefaultSDKPath
    }
    Add-Path "$env:AndroidSDK/platform-tools"
    
    $cmdToolsPath = Join-Path $env:AndroidSDK cmdline-tools latest bin
    $toolsPath = Join-Path $env:AndroidSDK Tools bin
    Add-Path ((Test-Path "$cmdToolsPath") ? "$cmdToolsPath" : "$toolsPath")

    if(!(Test-Path $env:AndroidSDK)){
        Write-Host "There is no Android SDK at $env:AndroidSDK"
        Write-Host "Install Android SDK or set the env:AndroidSDK to correct location."
        return
    }
}
Initialize-SDKPath