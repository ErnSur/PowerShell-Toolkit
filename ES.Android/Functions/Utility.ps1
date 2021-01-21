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

function Restart-ADB {
    adb kill-server
    adb start-server
}

function Export-Apk($packageName) {
    $apkPath = (adb shell pm path $packageName | ConvertFrom-StringData -Delimiter ":").Values[0]
    adb pull $apkPath
}

function Get-AndroidDevicePackages {
    adb shell pm list packages -f | ConvertFrom-StringData | Format-Table -AutoSize
}
