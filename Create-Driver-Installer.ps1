# =====================================================================================================
# Intune Driver Installer Creator PowerShell Script
# Version 1.0
#
# Description: Compiles and creates .intunewin and detection script file for 
#              distribution with Microsoft Intune. README file with instructions is
#              also generated.
# 
# Parameters:
#   Inf -- Specifies the location of the driver INF file. All other supporting files
#          for the driver must also be present at the INF location.
# 
#   OutputPath -- Specifies output folder to export .intunewin, detection script
#                 and README files. Default path is [Current Directory]\output
# 
#   IgnoreVersion -- Specifies whether driver version should be ignored in detection
#                    script. Valid optons are: Yes, No (Default).
#                    If driver version is ignored (Yes), the driver installation will 
#                    not occur if a matching driver is already installed, regardless of 
#                    the installed version. To ensure the packaged driver gets installed,
#                    set IgnoreVersion to No.
# 
#   IntuneWinFile -- Specifies the location of the IntuneWinAppUtil.exe application.
#                    This application is required to compile the .intunewin file.
#                    Default location is [Current Directory]\lib\IntuneWinAppUtil.exe
#
# Example: Create-Driver-Installer.ps1 -$Inf "driver.inf"
# Example: Create-Driver-Installer.ps1 -$Inf "driver.inf" -OutputPath "output"
# Example: Create-Driver-Installer.ps1 -$Inf "driver.inf" -OutputPath "output" -IgnoreVersion Yes
#
# Created and maintained by Niaz Ally (niazally@gmail.com)
# =====================================================================================================

# Define parameters
param ($Inf, $OutputPath = "output", [ArgumentCompleter({"Yes", "No"})] $IgnoreVersion = "No", $IntuneWinFile = "lib\IntuneWinAppUtil.exe")

# Display Welcome Message
Write-Output "`nIntune Driver Installer using PowerShell"
Write-Output "=============================================`n"

# Check for INF file parameter. If not provided, prompt for INF file.
if ($null -eq $Inf) {
    $Inf = Read-Host -Prompt "Enter Driver INF File"
}

# Validate INF file name. INF file must have .inf extension.
# If INF file is invalid, display error message and exit with status 1
if ($Inf -eq "" -Or $Inf.Length -lt 5 -Or $Inf.Substring($Inf.Length - 3) -ne "inf") {
    Write-Output "Error: Driver INF file is invalid`n"
    exit 1
}

# Check if driver INF file exists. If it doesn't display error and exit with status 1
if (-Not (Test-Path -Path $Inf)) {
    Write-Output "Error: Driver INF file not found`n"
    exit 1
}

# Check if output path directory exists. If not create, directory using path.
if (-Not (Test-Path -PathType Container $OutputPath)) {
    if (-Not (New-Item -ItemType Directory -Force -Path $OutputPath)) {
        Write-Output "Error: Unable to create output directory`n"
        exit 1
    }
}
else {
    # If directory exists, check if directory is empty
    # If directory is not empty, prompt user for confirmation before continuing
    if((Test-Path -Path "$OutputPath\*")){
        Write-Output "Warning: Output directory is not empty. If you continue, existing files may be overwritten."
        # Prompt for confirmation
        $overwrite = Read-Host -Prompt "Do you want to continue (Y/N)? Default: N"
        
        # If user does not specify Y, display exit message and exit with status 1
        if ($overwrite -ne "y") {
            Write-Output "`nUser cancelled, exiting.`n"
            exit 1
        }

        # Check that output directory is writable
        # If not writable, display error and exit with status 1
        try {
            $null = New-Item -ItemType File -Force -ErrorAction Stop -Name "$OutputPath\README.txt"
        }
        catch {
            Write-Output "`nError: Output directory is not writable`n"
            exit 1
        }
    }
}

# Check if $IgnoreVersion is set correctly. If not, display error and exit with status 1
if ($IgnoreVersion -ne "yes" -And $IgnoreVersion -ne "no") {
    Write-Output "Error: Invalid option for -IgnoreVersion. Available options: Yes, No`n"
    exit 1
}

# Check if $IntuneWinFile exists. If not pronpt for correct file.
if (-Not (Test-Path -Path $IntuneWinFile)) {
    # Display error and prompt for correct file
    Write-Output "Default IntuneWin Utility not found"
    $IntuneWinFile = Read-Host -Prompt "Enter path to IntuneWin Utility"

    # Check if supplied file path is valid. If not, display error and exit with status 1
    if (-Not (Test-Path -Path $IntuneWinFile)) {
        Write-Output "`nError: Invalid IntuneWin Utility`n"
        exit 1
    }
}

# Start prepartion for .intunewin creation

# Supporting functions
function CleanUp {
    param($tempDir)
    try {
        $null = Remove-Item -Path $tempDir -Force -Recurse -ErrorAction Stop
    }
    catch {
        Write-Output "Warning: Unable to remove temporary directory."
        Write-Output "This can be removed manually.`n"
    }
}

Write-Output "`nStarting installation package preparation...`n"

# Create temporary directory for working files
# Set directory name with random number
$tempDir = "temp_$(Get-Random -Minimum 1000 -Maximum 9999)"


Write-Output "> Checking output directory"

# Try creating temporary directory
# If unsuccessful, display error and exit with status 1
try {
    $null = New-Item -ItemType Directory -Force -ErrorAction Stop -Name $tempDir
}
catch {
    Write-Output "`nError: Cannot create temporary directory`n"
    exit 1
}

# Setup variables to begin preparation for .intunewin creation
$infPath = Split-Path -Path $Inf # Directory containing the driver files
$infFile = Split-Path -Path $Inf -Leaf # Driver INF file name
$infFileBase = $infFile.Substring(0, $infFile.LastIndexOf(".")) # Driver INF file name without extension

$driverVersion = $null # Store driver from INF file

# Retrive Driver Version from INF File

Write-Output "> Getting driver version from INF file"

# Open INF file and retreive line containing DriverVer
$infVersion = (Get-Content -Path $Inf | Select-String -Pattern "DriverVer").Line

# Retrieve the value of DriverVer
$infVersion = $infVersion.Split("=")[-1].Split(" ")[-1].Split(";")

# Check if the driver version is at the end of the value
# If not then driver version should be the element before the last vaule
if ($infVersion[-1] -eq "") {
    $infVersion = $infVersion[-2]
}
else {
    $infVersion = $infVersion[-1]
}

# Remove comma and retrieve the driver date and versoin
$infVersion = $infVersion.Split(",")

# Check if date and version exist, if not display error and exit with status 1
if ($infVersion.Length -lt 2) {
    if ($IgnoreVersion -eq "no") {
        Write-Output "Error: Unable to retrieve driver version from INF file"
        Write-Output "To bypass this error, use -IgnoreVersion Yes`n"
        CleanUp($tempDir)
        exit 1
    }
    else {
        Write-Output "Warning: Unable to retrieve driver version from INF file`n"
    }
}
else {
    # Store driver version from INF file in $driverVersion
    $driverVersion = "$($infVersion[0]) $($infVersion[1])"
}

Write-Output "> Copying driver files"

# Copy driver files into temporary directory
# If unsuccessful, display error and exit with status 1
try {
    $null = Copy-Item -Path "$infPath\*" -Destination $tempDir -Recurse -ErrorAction Stop
}
catch {
    Write-Output "Error: Unable to copy driver files"
    CleanUp($tempDir)
    exit 1
}

Write-Output "> Adding Driver Installer module from library"

# Copy Driver-Installer.ps1 from library
# If unsuccessful, display error and exit with status 1
try {
    $null = Copy-Item -Path "lib\Driver-Installer.ps1" -Destination $tempDir -ErrorAction Stop
}
catch {
    Write-Output "Error: Unable to copy Driver-Installer.ps1"
    CleanUp($tempDir)
    exit 1
}

Write-Output "> Compiling and adding Driver Installer script"

# Compile and create Install-Driver.ps1 from library
# If unsuccessful, display error and exit with status 1
try {
    # Retrieve Install-Driver.ps1 from library
    $installDriverScript = Get-Content -Path "lib\Install-Driver.ps1" -Raw

    # Update relevant placeholders
    $installDriverScript = $installDriverScript.Replace("{{--InfFileName--}}", $infFile)

     # Export Install Driver script to temporary directory
    $installDriverScript | Set-Content -Path "$tempDir\Install-Driver.ps1" -Force
}
catch {
    Write-Output "Error: Unable to compile and create Install-Driver.ps1"
    CleanUp($tempDir)
    exit 1
}

Write-Output "> Compiling and adding Driver Uninstaller script"

# Compile and create Uninstall-Driver.ps1 from library
# If unsuccessful, display error and exit with status 1
try {
    # Retrieve Uninstall-Driver.ps1 from library
    $uninstallDriverScript = Get-Content -Path "lib\Uninstall-Driver.ps1" -Raw

    # Update relevant placeholders
    $uninstallDriverScript = $uninstallDriverScript.Replace("{{--InfFileName--}}", $infFile)

    # Export Uninstall Driver script to temporary directory
    $uninstallDriverScript | Set-Content -Path "$tempDir\Uninstall-Driver.ps1" -Force
}
catch {
    Write-Output "Error: Unable to compile and create Uninstall-Driver.ps1"
    CleanUp($tempDir)
    exit 1
}

Write-Output "`nPackage preparation complete.`n"

# Compile and export .intunewin file

Write-Output "Starting IntuneWin file creation...`n"
Write-Output "> Running IntuneWin Utility"

# Run IntuneWin Utility to package driver installer into .intunewin file
# If unsucessful, display error and exit with status 1
try {
    Start-Process -WindowStyle Hidden -FilePath "lib\IntuneWinAppUtil.exe" -Wait `
    -ArgumentList "-q -c \`"$(Resolve-Path $tempDir)\`" -s Install-Driver.ps1 -o \`"$(Resolve-Path $OutputPath)\`""
}
catch {
    Write-Output "Error: IntuneWin Utility did not execute correctly`n"
    CleanUp($tempDir)
    exit 1
}

Write-Output "> Verifying Driver Installer .intunewin file"

# Check that .intunewin file was created and rename to Driver-[Driver Name].intunewin
# Store IntuneWin Utility output file name
$intuneOutput = "$OutputPath\Install-Driver.intunewin"

# Check if IntuneWin Utility output file exists
# If exists, rename to Driver[Driver Name].intunewin
if (Test-Path -Path $intuneOutput) {
    try {
        # Store new IntuneWin Utiltiy output file name
        $intuneNewOutput = "Driver-$infFileBase.intunewin"

        # Check if new IntuneWin Utility output file exists
        # If exists, remove file
        if (Test-Path -Path "$OutputPath\$intuneNewOutput") {
            Remove-Item -Path "$OutputPath\$intuneNewOutput" -Force -ErrorAction Stop
        }

        # Rename IntuneWin Utility output file
        $null = Rename-Item -Path $intuneOutput -NewName $intuneNewOutput -Force -ErrorAction Stop

        # Update IntuneWin Utility output file name
        $intuneOutput = $intuneNewOutput
    }
    catch {}
}
# If output file does not exist, display warning.
else {
    Write-Output "Warning: Could not verify Driver Installer .intunewin file."
    Write-Output "Check output folder for Install-Driver.intunewin`n"
}

Write-Output "`nIntuneWin file creation completed.`n"

# Compile and export Driver Detection Script

Write-Output "> Compiling and exporting Driver Detection script`n"

$detectionScript = "Driver-Detection-$infFileBase.ps1" # Store file name of driver detection script

# Compile and create Driver-Detection.ps1 from library
# If unsuccessful, display error and exit with status 1
try {
    # Retrieve Driver-Detection.ps1 from library
    $detectDriverScript = Get-Content -Path "lib\Driver-Detection.ps1" -Raw

    # Update relevant placeholders
    $detectDriverScript = $detectDriverScript.Replace("{{--InfFileName--}}", $infFile)

    # If $IgnoreVersion is set to No, update relevant placeholders to check driver version
    if($IgnoreVersion -eq "No") {
        $detectDriverScript = $detectDriverScript.Replace("{{--CheckVersion--}}", "Yes")
        $detectDriverScript = $detectDriverScript.Replace("{{--DriverVersion--}}", $driverVersion)
    }

    # Export Detection Script to output folder
    $detectDriverScript | Set-Content -Path "$OutputPath\$detectionScript" -Force
}
catch {
    Write-Output "Error: Unable to compile and create Driver-Detection.ps1"
    CleanUp($tempDir)
    exit 1
}

Write-Output "> Generating README file with instructions`n"

# Compile and create README.txt from library
# If unsuccessful, display warning and continue
try {
    # Retrieve README.txt from library
    $readmeFile = Get-Content -Path "lib\README.txt" -Raw

    # Update relevant placeholders
    $readmeFile = $readmeFile.Replace("{{--IntuneWin--}}", $intuneOutput)
    $readmeFile = $readmeFile.Replace("{{--DetectionScript--}}", $detectionScript)
    $readmeFile = $readmeFile.Replace("{{--DriverName--}}", $infFileBase)
    $readmeFile = $readmeFile.Replace("{{--DriverVersion}}", $infVersion[1])

    # Export README to output folder
    $readmeFile | Set-Content -Path "$OutputPath\README.txt" -Force
}
catch {
    Write-Output "Warning: Unable to generate README file`n"
}

Write-Output "> Cleaning up...`n"

# Clean up temporary directory
CleanUp($tempDir)

# Display results
Write-Output "Driver Installer creation completed!!!`n"
Write-Output "README, .intunewin, and detection script files are located in"
Write-Output ((Resolve-Path $OutputPath).Path)
Write-Output "`nIntuneWin File: $intuneOutput"
Write-Output "Detection Script: $detectionScript"
Write-Output "`nCheck README for important instructions to create the App in Intune.`n"