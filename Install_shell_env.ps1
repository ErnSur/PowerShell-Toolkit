function Install-PackageManager {
    if ($IsMacOS) {
        Install-Brew
    }
    elseif ($IsWindows) {
        Install-Choco
    }
}

function Install-Brew {
    & '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
}

function Install-Choco {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

function Install-PSToolkit {
    #$installDir = $IsWindows ? 
}