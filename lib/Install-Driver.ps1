# ========================================================================================
# Intune Driver Installer PowerShell Script
# Version 1.0
#
# Description: Installer script used to bootstrap the configuration and use
#              Driver-Installer.ps1 to install the driver
# Parameters: None
#
# Example: Install-Driver.ps1
#
# Created and maintained by Niaz Ally (niazally@gmail.com)
# ========================================================================================

# Specify Driver INF File. {{--InfFileName--}} is a placeholder used by other scripts.
$Inf = "{{--InfFileName--}}"

# Check if $Inf has been updated. Only continue if placeholder has been updated.
if ($Inf -ne "{{--inffilename--}}") {
    # Begin driver installation

    # Call Driver-Installer.ps1 and pass configuration to install driver
    Invoke-Expression ".\Driver-Installer.ps1 -Inf '$Inf' -Method Install"
    
    # Exit using the exit code from Driver-Installer.ps1
    exit $LASTEXITCODE
}
# If $Inf is not updated, display error and exit with status 1
else {
    Write-Output "Error: Driver INF file not specified.`n"
    exit 1
}
