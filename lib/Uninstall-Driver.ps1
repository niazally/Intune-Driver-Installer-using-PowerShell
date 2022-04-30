# ========================================================================================
# Microsoft Intune Driver Uninstaller PowerShell Script
# Version 1.0
#
# Description: Uninstaller script used to bootstrap the configuration and use
#              Driver-Installer.ps1 to uninstall the driver
# Parameters: None
#
# Example: Uninstall-Driver.ps1
#
# Created and maintained by Niaz Ally (niazally@gmail.com)
# ========================================================================================

# Specify Driver INF File. {{--InfFileName--}} is a placeholder used by other scripts.
$Inf = "{{--InfFileName--}}"

# Check if $Inf has been updated. Only continue if placeholder has been updated.
if ($Inf -ne "{{--InfFileName--}}") {
    # Begin driver uninstall

    # Call Driver-Installer.ps1 and pass configuration to uninstall driver
    Invoke-Expression ".\Driver-Installer.ps1 -Inf '$Inf' -Method Uninstall"
    
    # Exit using the exit code from Driver-Installer.ps1
    exit $LASTEXITCODE
}
# If $Inf is not updated, display error and exit with status 1
else {
    Write-Output "Error: Driver INF file not specified.`n"
    exit 1
}
