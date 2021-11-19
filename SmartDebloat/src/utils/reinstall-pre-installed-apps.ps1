function Quick-PrivilegesElevation() {
    # Used from https://stackoverflow.com/a/31602095 because it preserves the working directory!
    If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
}

function Main() {

    Quick-PrivilegesElevation

    # The following code is from Microsoft (Adapted): https://go.microsoft.com/fwlink/?LinkId=619547
    # Get all the provisioned packages
    $Packages = (Get-Item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications') | Get-ChildItem

    # Filter the list if provided a filter
    $PackageFilter = $args[0]
    If ([string]::IsNullOrEmpty($PackageFilter)) {
        Write-Warning "No filter specified, attempting to re-register all provisioned apps."
    }
    Else {
        $Packages = $Packages | Where-Object { $_.Name -like $PackageFilter } 

        If ($null -eq $Packages) {
            Write-Warning "No provisioned apps match the specified filter."
            exit
        }
        Else {
            Write-Host "Registering the provisioned apps that match $PackageFilter..."
        }
    }

    ForEach ($Package in $Packages) {
        # Get package name & path
        $PackageName = $Package | Get-ItemProperty | Select-Object -ExpandProperty PSChildName
        $PackagePath = [System.Environment]::ExpandEnvironmentVariables(($Package | Get-ItemProperty | Select-Object -ExpandProperty Path))

        # Register the package
        Write-Host "Attempting to register package: $PackageName."

        Add-AppxPackage -register $PackagePath -DisableDevelopmentMode
    }
}

Main