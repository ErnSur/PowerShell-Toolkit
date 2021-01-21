function Initialize-SDKPath {
    if($null -eq $env:AndroidSDK){
        $env:AndroidSDK = Get-DefaultSDKPath
    }
    Add-Path "$env:AndroidSDK/platform-tools"

    $cmdToolsPath = Join-Path $env:AndroidSDK cmdline-tools latest bin
    $toolsPath = Join-Path $env:AndroidSDK Tools bin
    Add-Path ((Test-Path "$cmdToolsPath") ? "$cmdToolsPath" : "$toolsPath")

    if(!(Test-Path $env:AndroidSDK)){
        Write-Output "There is no Android SDK at $env:AndroidSDK"
        Write-Output "Install Android SDK or set the env:AndroidSDK to correct location."
        return
    }
}



Initialize-SDKPath