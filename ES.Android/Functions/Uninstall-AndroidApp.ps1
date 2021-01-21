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