Get-ChildItem -Path "$PSScriptRoot/Functions" | ForEach-Object -Process {
    . $_.FullName
}