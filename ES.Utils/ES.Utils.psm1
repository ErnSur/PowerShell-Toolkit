function Add-Path {
    <#
      .SYNOPSIS
        Adds a Directory to the Current Path
      .DESCRIPTION
        Add a directory to the current path.  This is useful for 
        temporary changes to the path or, when run from your 
        profile, for adjusting the path within your powershell 
        prompt.
      .EXAMPLE
        Add-Path -Directory "C:\Program Files\Notepad++"
      .PARAMETER Directory
        The name of the directory to add to the current path.
    #>
  
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = 'What directory would you like to add?')]
        [Alias('dir')]
        [string[]]$Directory
    )
  
    PROCESS {
        $envPathSeparator = $IsWindows ? ';' : ':';
        $Path = $env:PATH.Split($envPathSeparator)
        foreach ($dir in $Directory)
        {
            if ($Path -contains $dir)
            {
                Write-Verbose "$dir is already present in PATH"
            }
            else
            {
                if (-not (Test-Path $dir))
                {
                    Write-Verbose "$dir does not exist in the filesystem"
                }
                else
                {
                    $Path += $dir
                }
            }
        }
  
        $env:PATH = [String]::Join($envPathSeparator, $Path)
    }
}

# Remove empty directories locally
function Remove-EmptyFolder($path)
{
    # Go through each subfolder, 
    foreach ($subFolder in Get-ChildItem -Force -Literal $path -Directory) 
    {
        # Call the function recursively
        Remove-EmptyFolder $subFolder.FullName
    }

    # Get all child items
    $subItems = Get-ChildItem -Force:$getHiddelFiles -LiteralPath $path

    # If there are no items, then we can delete the folder
    # Exluce folder: If (($subItems -eq $null) -and (-Not($path.contains("DfsrPrivate")))) 
    If ($subItems -eq $null) 
    {
        Write-Host "Removing empty folder '${path}'"
        Remove-Item -Force -Recurse:$removeHiddenFiles -LiteralPath $Path -WhatIf:$whatIf
    }
}