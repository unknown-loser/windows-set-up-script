Import-Module -DisableNameChecking $PSScriptRoot\..\lib\"simple-message-box.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\"title-templates.psm1"

function Install-GamingPackages() {

    # You Choose
    $Ask = "Do you plan to play games on this PC?
  All Gaming Dependencies will be installed.
  + Microsoft DirectX
  + Microsoft .NET (Framework, Runtime & SDK)
  + Microsoft Visual C++ Packages (2005-2022)
  + Java Runtime Environment"

    switch (Show-Question -Title "Read carefully" -Message $Ask) {
        'Yes' {

            Write-Host "You choose Yes."
            $ChocoGamingPackages = @(
                "directx"               # DirectX End-User Runtime
            )

            Write-Title -Text "Installing Packages with Chocolatey"

            ForEach ($Package in $ChocoGamingPackages) {
                Title2Counter -Text "Installing: $Package" -MaxNum $ChocoGamingPackages.Length
                choco install -y $Package | Out-Host
            }

            $WingetGamingPackages = @(
                "Microsoft.dotNetFramework"         # Microsoft .NET Framework (v4.8+)
                "Microsoft.dotnet"                  # Microsoft .NET SDK (v5+)
                "Microsoft.VC++2005Redist-x86"      # Microsoft Visual C++ 2005 Redistributable
                "Microsoft.VC++2005Redist-x64"      # Microsoft Visual C++ 2005 Redistributable (x64)
                "Microsoft.VC++2008Redist-x86"      # Microsoft Visual C++ 2008 Redistributable - x86
                "Microsoft.VC++2008Redist-x64"      # Microsoft Visual C++ 2008 Redistributable - x64
                "Microsoft.VC++2010Redist-x86"      # Microsoft Visual C++ 2010 x86 Redistributable
                "Microsoft.VC++2010Redist-x64"      # Microsoft Visual C++ 2010 x64 Redistributable
                "Microsoft.VC++2012Redist-x86"      # Microsoft Visual C++ 2012 Redistributable (x86)
                "Microsoft.VC++2012Redist-x64"      # Microsoft Visual C++ 2012 Redistributable (x64)
                "Microsoft.VC++2013Redist-x86"      # Microsoft Visual C++ 2013 Redistributable (x86)
                "Microsoft.VC++2013Redist-x64"      # Microsoft Visual C++ 2013 Redistributable (x64)
                "Microsoft.VC++2015-2022Redist-x86" # Microsoft Visual C++ 2015-2022 Redistributable (x86)
                "Microsoft.VC++2015-2022Redist-x64" # Microsoft Visual C++ 2015-2022 Redistributable (x64)
                "Oracle.JavaRuntimeEnvironment"     # Java Runtime Environment
            )

            Write-Title -Text "Installing Packages with Winget"

            ForEach ($Package in $WingetGamingPackages) {
                Title2Counter -Text "Installing: $Package" -MaxNum $WingetGamingPackages.Length
                winget install --silent --id $Package | Out-Host
            }

        }
        'No' {
            Write-Host "You choose No. (No = Cancel)"
        }
        'Cancel' {
            # With Yes, No and Cancel, the user can press Esc to exit
            Write-Host "You choose Cancel. (Cancel = No)"
        }
    }
}

function Main() {

    Install-GamingPackages               # Install All Gaming Dependencies

}

Main