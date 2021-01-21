function Get-AdbDevices {
    function FirstCharToUpper($text) {
        return $text.substring(0, 1).ToUpper() + $text.substring(1)
    }

    function New-AdbDevice($properties) {
        $device = [PSCustomObject]$properties
        $device.PSTypeNames.Insert(0,'ADB.Device')
        return $device
    }

    $result = adb devices -l | Where-Object { $_.trim() -ne "" } | Select-Object -Skip 1 | ForEach-Object {
        $tsv = $_ -replace '\ \ +', ' Status:'
        $tsv = $tsv -replace '\ ', "`n"
        $tsv = "Id:" + $tsv
        $tsv = $tsv.Split() | ForEach-Object { FirstCharToUpper($_) } | Join-String -Separator "`n"
        $props = ConvertFrom-StringData -Delimiter ':' -StringData $tsv
        return New-AdbDevice $props
    }

    return @($result)
}

Update-TypeData -TypeName "ADB.Device" -DefaultDisplayPropertySet 'Id', 'Status', 'Model', 'Product' -Force
