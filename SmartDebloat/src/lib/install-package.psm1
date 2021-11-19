function Install-Package() {
    # This function name may conflict with Chocolatey on PowerShell...

    [CmdletBinding()] #<<-- This turns a regular function into an advanced function
    param (
        [String]  $Name,
        [Array]   $PackageName,
        [String]  $InstallBlock = { winget install --silent --id $Package }
    )

    $DoneTitle = "Done"
    $DoneMessage = "$Name installed!"

    Write-Host "--> Installing: $($Name)." -ForegroundColor Cyan
    # Avoiding a softlock only on the script that occurs if the APP is already installed on Microsoft Store (Blame Spotify)
    If ((Get-AppxPackage).Name -ilike "*$($Name)*") {
        Write-Host "--> $PackageName already installed on MS Store! Skipping..." -ForegroundColor Cyan
    }
    Else {
        ForEach ($Package in $PackageName) {
            Invoke-Expression "$InstallBlock" | Out-Host
        }
    }

    Show-Message -Title "$DoneTitle" -Message "$DoneMessage"
}

<#
Example:
Install-Package -Name "Brave Browser" -PackageName "BraveSoftware.BraveBrowser"
Install-Package -Name "Multiple Packages" -PackageName @("Package1", "Package2", "Package3", ...) -InstallBlock { choco install -y $Package }
#>