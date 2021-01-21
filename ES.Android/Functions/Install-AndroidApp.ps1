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
    begin {
        function Install($extension, $path, $deviceId) {
            Write-Output "Try Install to $deviceId" -ForegroundColor Yellow
            switch ($extension) {
                'apk' { adb -s $deviceId install -r "$path" }
                'apks' { bundletool install-apks --apks="$path" --device-id=$deviceId }
            }
            if ($?) {
                Write-Output "Success" -ForegroundColor Green
            }
            else {
                Write-Output "Failure" -ForegroundColor Red
            }
        }
    }
    process {
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
                Write-Output "File format not recognizable."
            }
        }

    }
}