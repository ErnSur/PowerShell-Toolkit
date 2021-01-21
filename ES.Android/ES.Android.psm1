
$aapt = $IsWindows ? (Join-Path $PSScriptRoot Tools aapt2.exe) : (Join-Path $PSScriptRoot Tools aapt2);
$bundletool = (Join-Path $PSScriptRoot Tools "bundletool-all-1.4.0.jar");

function Get-Info {
    $foo | Write-Host
}

function Get-ApkPermissions($apkPath) {
    & $aapt dump permissions $apkPath
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
function Get-AdbDeviceIds {
    $tsv = adb devices | Select-Object -Skip 1
    return ConvertFrom-Csv $tsv -Delimiter "`t" -Header "Id", "Name"
}

#region deploy
# For testing:
# Import-Module -Name /Users/mac/Repos/Plugins_and_libraries/PowerShell-Toolkit/ES.Android/ -Verbose

function Install-AndroidApp($filePath) {
    $extension = $line.Split(".")[-1]

    switch ($extension) {
        '.apk' {

          }
          'aab'{

          }
          'apks'{
              
          }
        Default {}
    }
    if($filePath -like "*.apk"){
        get_devices | xargs -I deviceId adb -s deviceId install -r "$1"
    }
    elseif (condition) {
        apksPath="$(extractAPKS "$1" | tee /dev/tty | tail -1)"
        installAPKSToAllDevices "$apksPath"
    }
elif has_extension "$1" "aab" ; then
elif has_extension "$1" "apks" ; then
    installAPKSToAllDevices "$1"
else
    echo "File format not recognizable."
fi
}

#endregion