
$aapt = $IsWindows ? (Join-Path $PSScriptRoot aapt2.exe) : "";

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