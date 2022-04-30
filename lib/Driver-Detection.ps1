# ========================================================================================================
# Driver Detection PowerShell Script
# Version 1.0
#
# Description: Check if driver is installed with PNPUTIL command using 
#              specified driver INF file name
# Parameters:
#   Inf -- Specifies INF file name of the driver
#   CheckVersion -- Specifies whether to check and verify driver version. Options: Yes, No
#   DriverVersion -- Version to check and verify
#
# Example: Driver-Detection.ps1 -Inf driver.inf -CheckVersion Yes -DriverVersion 12/14/2021 12.18.13.0
#
# Created and maintained by Niaz Ally (niazally@gmail.com)
# ========================================================================================================

# Define parameters.
param ($Inf = "{{--InfFileName--}}", $CheckVersion = "{{--CheckVersion--}}", $DriverVersion = "{{--DriverVersion--}}")

# Check for INF file name parameter. If not provided, prompt for INF file.
if ($null -eq $Inf -Or $Inf -eq "" -Or $Inf -eq "{{--inffilename--}}") {
    $Inf = Read-Host -Prompt "Enter Driver INF File Name"
}

# Validate INF file name. INF file must have .inf extension.
# If INF file is invalid, display error message and exit with status 1
if ($Inf -eq "" -Or $Inf.Length -lt 5 -Or $Inf.Substring($Inf.Length - 3) -ne "inf") {
    Write-Output "Error: Driver INF file is invalid`n"
    exit 1
}

# Paths to PNPUTIL command
$pnpUtilPath1 = "pnputil.exe" # Assumes the PATH environment variable is configured correctly
$pnpUtilPath2 = "C:\Windows\SysNative\pnputil.exe" # Alternative path if first path fails
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

# Begin driver detection check

# Run PNPUTIL and get list of installed drivers
# Store list into $driverList
$driverList = Invoke-Expression -Command "$pnpUtilPath /enum-drivers"

# Search $driverList for driver INF file name
$detectionResult = $driverList | Select-String -Pattern " $Inf" -Context 0,4

# Check if driver INF file name was found in $driverList
# If $detectionResult is null, then it means the driver INF file name was not found
# Therefore, driver is not installed. Display message and exit with status 1
if ($null -eq $detectionResult) {
    Write-Output "$Inf driver was not found.`n"
    exit 1
}
# If $detectionResult is not null, then driver INF File name was found in $driverList
# Therefore, driver is installed.
else {
    # Check if driver version needs to be verified
    if ($CheckVersion -eq "Yes") {
        # Check $detectionResult for driver version
        $versionResult = $detectionResult.toString() | Select-String -Pattern $DriverVersion

        # Check if $DriverVersion was found in $versionResult
        # If $versionResult is null, then it means the installed driver version is different.
        # Therefore, driver and version does not match. Display message and exit with status 1
        if ($null -eq $versionResult) {
            Write-Output "$Inf driver was found, but version is incorrect.`n"
            exit 1
        }
        # If $versionResult is not null, then the driver and version is correct.
        # Display message and exit with status 0
        else {
            Write-Output "$Inf was found, and version is correct.`n"
             exit 0
        }
    }
    # If driver version does not need to be verified, then display message and exit with status 0
    else {
        Write-Output "$Inf was found.`n"
        exit 0
    }
}