# ========================================================================================
# Driver Installer PowerShell Script
# Version 1.0
#
# Description: Installs or uninstalls driver using PNPUTIL
# Parameters:
#   Inf -- Specifies the location of the driver INF file. All other supporting files
#          for the driver must also be present at the INF location.

#   Method -- Indicates the operation to perform. 
#             There are two valid options are: install, uninstall
#
# Example: Driver-Installer.ps1 -Inf driver.inf -Method Install
#
# Created and maintained by Niaz Ally (niazally@gmail.com)
# ========================================================================================

# Define parameters
param ($Inf, [ArgumentCompleter({"Install", "Uninstall"})] $Method)

# Check for INF file parameter. If not provided, prompt for INF file.
if ($null -eq $Inf) {
    $Inf = Read-Host -Prompt "Enter Driver INF File"
}
# Check for Method parameter. If not provided, prompt for Method.
if ($null -eq $Method) {
    $Method = Read-Host -Prompt "Enter installation method (install/uninstall)"
}

# Validate INF file name. INF file must have .inf extension.
# If INF file is invalid, display error message and exit with status 1
if ($Inf -eq "" -Or $Inf.Length -lt 5 -Or $Inf.Substring($Inf.Length - 3) -ne "inf") {
    Write-Output "Error: Driver INF file is invalid`n"
    exit 1
}

# Validate Method. Method must either be install or uninstall.
if ($Method -ne "install" -And $Method -ne "uninstall") {
    Write-Output "Error: Invalid method`n"
    exit 1
}

# Check if Driver INF file exists.
# If file doesn't exist, display error and exit.
if(Test-Path -Path $Inf) {

    # Paths to PNPUTIL command
    $pnpUtilPath1 = "C:\Windows\SysNative\pnputil.exe" # Path when deploying with Intune
    $pnpUtilPath2 = "pnputil.exe" # Assumes the PATH environment variable is configured correctly
    $pnpUtilPath = $null # Path to use for PNPUTIL

    # Check if PNPUTIL command exists on first path. If exist, set $pnpUtilPath.
    if($null -ne (Get-Command $pnpUtilPath1 -ErrorAction SilentlyContinue)) {
        $pnpUtilPath = $pnpUtilPath1
    }
    # Check if PNPUTIL command exists on second path. If exist, set $pnpUtilPath.
    elseif ($null -ne (Get-Command $pnpUtilPath2 -ErrorAction SilentlyContinue)) {
        $pnpUtilPath = $pnpUtilPath2
    }

    # Check if $pnpUtilPath is set. If not set, it means a valid path to the PNPUTIL command was not found
    # Display error and exit with status 1 if not valid path is found
    if ($null -eq $pnpUtilPath) {
        Write-Output "Error: PNPUTIL command could not be found.`nUnable to continue.`n"
        exit 1
    }

    # Check if install method was called
    if ($Method -eq "install") {
        # Install Method

        # Display message to indicate start of driver installation
        Write-Output "Driver installation started`nInstalling driver using $Inf...`n"
        
        # Run PNPUTIL command to install driver and store output to $installCommand for analysis
        $installCommand = Invoke-Expression -Command "$pnpUtilPath /add-driver '$Inf' /install"

        # Search output of PNPUTIL to check for indication of successful driver install
        # Store the indication into $installResult
        $installResult = $installCommand | Select-String -Pattern "Added driver packages:  1"

        # Check if $installResult shows a succesful driver installation
        # If $installResult is null, indicator for successful installation was not found
        # Display error message and exit with status 1
        if ($null -eq $installResult) {
            Write-Output "Error: Driver installation failed.`n"
            exit 1
        }
        # If $installResult is not null, it means the indicator for successful installation was found
        # Display success message and exit with status 0
        else {
            Write-Output "Driver installation completed.`n"
            exit 0
        }
    }
    # Check if uninstall method was called
    elseif ($Method -eq "uninstall") {
        # Uninstall method

        # Display message to indicate start of driver uninstall
        Write-Output "Driver uninstall started`nUninstalling driver using $Inf...`n"

        # Run PNPUTIL command to uninstall driver and store output to $uninstallCommand for analysis
        $uninstallCommand = Invoke-Expression -Command "$pnpUtilPath /delete-driver '$Inf' /uninstall"

        # Search output of PNPUTIL to check for indication of unsuccessful driver uninstall
        # Store the indication into $uninstallResult
        $uninstallResult = $uninstallCommand | Select-String -Pattern "Failed to delete driver package"

        # Check if $uninstallResult shows an unsuccesful driver uninstall
        # If $uninstallResult is null, indicator for unsuccessful uninstall was not found
        # This means that the driver uninstall was successful
        # Display success message and exit with status 0
        if ($null -eq $uninstallResult) {
            Write-Output "Driver uninstall completed.`n"
            exit 0
        }
        # If $unistallResult is not null, check if PNPUTIL could not find the driver.
        # If the driver could not be found, then the driver is already uninstalled.
        # Display messsage and exit with status 0
        elseif ($null -ne ($uninstallCommand | Select-String -Pattern "Failed to delete driver package: Element not found")) {
            Write-Output "Driver is not installed.`n"
            exit 0
        }
        # If $uninstallResult is not null and driver is installed, 
        # it means the indicator for unsuccessful uninstall was found
        # Display error message and exit with status 1
        else {
            Write-Output "Error: Driver uninstall failed.`n"
            exit 1
        }
    }
}
# If INF file does not exist, display error message and exit with status 1
else {
    Write-Output "Error: Driver INF file not found!`nUnable to continue.`n"
    exit 1
}
