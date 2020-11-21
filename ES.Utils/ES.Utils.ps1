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