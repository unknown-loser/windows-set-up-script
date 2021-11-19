function Quick-PrivilegesElevation() {
    # Used from https://stackoverflow.com/a/31602095 because it preserves the working directory!
    If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
}

function Check-GitUser() {
    [CmdletBinding()] #<<-- This turns a regular function into an advanced function
    param (
        [String]	$git_user_property, # Ex: Plínio Larrubia, email@email.com
        [String]	$git_property_name  # Ex: Name, Email
    )

    While ($git_user_property -eq "" -or $git_user_property -eq $null) {

        Write-Host "Could not found 'user.$git_user_property', is null or empty."
        $git_user_property = Read-Host "Please enter your $git_user_property (For git config --global)"

        If (!(($git_user_property -eq "") -or ($null -eq $git_user_property))) {

            Write-Host "Setting your git user.$git_property_name to $git_user_property..."
            git config --global user.$git_property_name "$git_user_property"
            Write-Host "Updated: $(git config --global user.$git_property_name)."

        }
    }

    Write-Host "Your git_user_property is: $git_user_property."
    return $git_user_property

}

function Setup-Git() {

    $Global:git_user_name = $null
    $Global:git_user_name = $(git config --global user.name)

    $Global:git_user_email = $null
    $Global:git_user_email = $(git config --global user.email)

    $Global:git_user_props = @("name", "email")

    $Global:git_user_name = $(Check-GitUser -git_user_property $git_user_name -git_property_name $git_user_props[0])
    $Global:git_user_email = $(Check-GitUser -git_user_property $git_user_email -git_property_name $git_user_props[1]).ToLower()

}

function Setup-SSH {

    $ssh_path = "~/.ssh"
    $ssh_enc_type = "ed25519"
    $ssh_file = "$($git_user_email)_id_$ssh_enc_type"
    $ssh_alt_file = "id_$ssh_enc_type" # Need to be checked

    If (!(Test-Path "$ssh_path")) {
        mkdir "$ssh_path" | Out-Null
    }
    Push-Location "$ssh_path"

    # Check if SSH Key already exists
    If (!((Test-Path "$ssh_path/$ssh_alt_file") -or (Test-Path "$ssh_path/$ssh_file"))) {

        Write-Host "$ssh_path/$ssh_alt_file NOT Exists AND"
        Write-Host "$ssh_path/$ssh_file NOT Exists..."
        Write-Host "Using your email from git to create a SSH Key: $git_user_email."
        Write-Warning "I recommend you save your passphrase somewhere, in case you don't remember."

        #           Encryption type    Command              Output file
        ssh-keygen -t "$ssh_enc_type" -C "$git_user_email" -f "$ssh_path/$($ssh_file)"

        Write-Host "Starting ssh-agent Service, this part is the reason to get admin permissions."
        Start-Service -Name ssh-agent
        Set-Service -Name ssh-agent -StartupType Automatic

        Write-Host "Checking if ssh-agent is running before adding the keys..."
        ssh-agent.exe

        Write-Host "Add your private key (One of these will pass)." # Remind: No QUOTES in variables
        ssh-add $ssh_file
        ssh-add $ssh_alt_file

    }
    Else {

        Write-Host "$ssh_path/$ssh_file Exists OR"
        Write-Host "$ssh_path/$ssh_alt_file Exists"

    }
}

function Setup-GPG {

    # https://www.gnupg.org/documentation/manuals/gnupg/OpenPGP-Key-Management.html
    $gnupg_gen_path = "~/AppData/Roaming/gnupg"
    $gnupg_path = "~/.gnupg"
    $gnupg_enc_size = "4096"
    $gnupg_enc_type = "rsa$gnupg_enc_size"
    $gnupg_usage = "cert"
    $gnupg_expires_in = 0
    $gnupg_file = "$($git_user_email)_$gnupg_enc_type"

    Pop-Location
    If (!(Test-Path "$gnupg_path")) {
        mkdir "$gnupg_path" | Out-Null
    }
    Push-Location "$gnupg_path"

    # GPG Key creation/import "check"
    If (!((Test-Path "$gnupg_path/*$gnupg_file*") -or (Test-Path "$gnupg_path/*.gpg"))) {

        Write-Host "$gnupg_path/*$gnupg_file* NOT Exists AND"
        Write-Host "$gnupg_path/*.gpg* NOT Exists..."

        Write-Host "Generating new GPG key in $gnupg_path/$gnupg_file..."

        Write-Host "Before exporting your public and private keys, add manually an email." -ForegroundColor Yellow
        Write-Host "Type: 1 (RSA and RSA) [ENTER]." -ForegroundColor Yellow
        Write-Host "Type: 4096 [ENTER]." -ForegroundColor Yellow
        Write-Host "Then: 0 (does not expire at all) [ENTER]." -ForegroundColor Yellow
        Write-Host "Then: y [ENTER]." -ForegroundColor Yellow
        Write-Host "Then: $git_user_name [ENTER]." -ForegroundColor Yellow
        Write-Host "Then: $git_user_email [ENTER]" -ForegroundColor Yellow
        Write-Host "Then: Anything you want (Ex: Git Keys) [ENTER]." -ForegroundColor Yellow
        Write-Host "Then: O (Ok) [ENTER]." -ForegroundColor Yellow
        Write-Host "Then: [your passphrase] [ENTER]." -ForegroundColor Yellow
        Write-Host "Then: [your passphrase again] [ENTER]." -ForegroundColor Yellow
        gpg --full-generate-key

        # If you want to delete unwanted keys, this is just for reference
        #gpg --delete-secret-keys $git_user_name
        #gpg --delete-keys $git_user_name

        Write-Host "Copying all files to $gnupg_path..."
        Copy-Item -Path "$gnupg_gen_path/*" -Destination "$gnupg_path/" -Recurse
        Remove-Item -Path "$gnupg_path/*" -Exclude "*.gpg", "*.key", "*.pub", "*.rev" -Recurse
        Remove-Item -Path "$gnupg_path/trustdb.gpg"

        Write-Host "Setting GnuPG program path to ${env:ProgramFiles(x86)}\GnuPG\bin\gpg.exe"
        git config --global gpg.program "${env:ProgramFiles(x86)}\GnuPG\bin\gpg.exe"

        # Export public and private key to a file: {email@email.com}_{encryption_type}_public.gpg
        gpg --output "$($gnupg_file)_public.gpg" --armor --export "$git_user_email"
        gpg --output "$($gnupg_file)_secret.gpg" --armor --export-secret-key "$git_user_email"

        # Import GPG keys
        gpg --import *$gnupg_file*
        gpg --import *.gpg*

        # Get the exact Key ID from the system
        $key_id = $((gpg --list-keys --keyid-format LONG).Split(" ")[5].Split("/")[1])

        If (!(($key_id -eq "") -or ($null -eq $key_id))) {

            Write-Host "key_id found: $key_id."
            Write-Host "Registering the Key ID found to git user..."
            git config --global user.signingkey "$key_id"
            Write-Host "Your git user.signingkey now is: $(git config --global user.signingkey)."

            Write-Host "Signed git commits enabled."
            git config --global commit.gpgsign true

            Write-Host "Copy and Paste the lines below on your"
            Write-Host "Github/Gitlab > Settings > SSH and GPG Keys > New GPG Key."
            Get-Content "$gnupg_path/$($gnupg_file)_public.gpg"

        }
        Else {

            Write-Host "Failed to retrieve your key_id: $key_id."

        }
    }
    Else {

        Write-Host "$gnupg_path/*$gnupg_file* Exists OR"
        Write-Host "$gnupg_path/*.gpg Exists..."

    }

    Pop-Location

}

function Main() {

    Quick-PrivilegesElevation

    Write-Host "Installing: Git and GnuPG..."
    winget install --silent Git.Git | Out-Host
    winget install --silent GnuPG.GnuPG | Out-Host
    Write-Host "Before everything, your data will only be keep locally, only in YOUR PC." -ForegroundColor Cyan
    Write-Host "I've made this to be more productive and will not lose time setting keys on Windows." -ForegroundColor Cyan
    Write-Warning "If you already have your keys located at ~/.ssh and ~/.gnupg, the signing setup will be skipped."
    Write-Warning "Make sure you got winget installed already."
    Read-Host "Press Enter to continue..."
    Setup-Git
    Setup-SSH
    Setup-GPG
}

Main