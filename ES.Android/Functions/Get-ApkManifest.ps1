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