# Intune Driver Installer using PowerShell
Install drivers through Microsoft Intune using PowerShell.

This PowerShell script compiles and creates .intunewin and detection script files that is used to create a Windows app (Win32) App in Intune.

The script will package the driver files along with supporting PowerShell scripts too install/uninstall a driver from Windows.

IntuneWin packaging is done by Microsoft Win32 Content Prep Tool (IntuneWinAppUtil.exe):
https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool

> Microsoft Win32 Content Prep Tool requires .NET Framework 4.7.2.
> Read license terms for the tool here: [Microsoft License Terms For Win32 Content Prep Tool](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool/blob/master/Microsoft%20License%20Terms%20For%20Win32%20Content%20Prep%20Tool.pdf)

Intune Driver Installer using PowerShell releases already include the IntuneWinAppUtil.exe; however, other versions can be used through the -IntuneWinFile parameter.

## Prerequisites
Before running Intune Driver Installer using PowerShell, ensure the following is done:
1. Download and extract Intune Driver Installer using PowerShell to a directory that is writable by the PowerShell script.
2. Prepare a folder with the Driver INF file and any other supporting files referenced by the INF.
> The folder must contain only the driver files. All files in the folder will be packaged into IntuneWin file.
3. If using a different IntuneWinAppUtil.exe, place it in a directory that is accessible by the PowerShell script.

## Components
Intune Driver Installer using PowerShell release contains the following components:
1. **Create-Driver-Installer.ps1** - This is the main script that will be used to compile, package, and export the .intunewin, detection script, and README files.
2. **lib folder** - The lib folder contains all the PowerShell scripts and other supporting file required to create the .intunewin, detection script, and README files.
> Do not rename or change any files in the lib folder.

## Usage
Create-Driver-Installer.ps1 is used to create the Intune Driver Installer.
> Ensure ExecutionPolicy is set to allow the PowerShell script to run; otherwise, Create-Driver-Installer.ps1 will fail to run.
> 
> Use `powershell.exe -ExecutionPolicy Bypass -File .\Create-Driver-Installer.ps1` to allow execution, if needed.

### Parameters

- -Inf -- Specifies the location of the driver INF file. All other supporting files for the driver must also be present at the INF location.
> Ensure only driver files are in the folder. All files in the folder will be packaged into the .intunewin file.
- -OutputPath -- Specifies output folder to export .intunewin, detection script and README files. Output folder must be writable by the PowerShell Script.
> Default path is .\output
- -IgnoreVersion -- Specifies whether driver version should be ignored in detection script. Valid optons are: Yes, No. 
If driver version is ignored (Yes), the driver installation will not occur if a matching driver is already installed, 
regardless of the installed version. To ensure the packaged driver gets installed, set IgnoreVersion to No.
> Default value is -IgnoreVersion No
- -IntuneWinFile -- Specifies the location of the IntuneWinAppUtil.exe application. This application is required to compile the .intunewin file. 
> Default IntuneWinFile location is lib\IntuneWinAppUtil.exe

### Examples
- `Create-Driver-Installer.ps1 -$Inf "[driver folder]\driver.inf"`
- `Create-Driver-Installer.ps1 -$Inf "[driver folder]\driver.inf" -OutputPath "output"`
- `Create-Driver-Installer.ps1 -$Inf "[driver folder]\driver.inf" -OutputPath "output" -IgnoreVersion Yes`

### Output
Create-Driver-Installer.ps1 will create the following files in the specified output folder:
- Driver-[Driver Name].intunewin -- IntuneWin file that contains the driver and installer scripts.
- Driver-Detection-[Driver Name].ps1 -- Detection script to use when creating the App in Intune.
- README.txt -- Instruction file that contains important information on how to create the App in Intune.
> Ensure to read the README file for all the parameters and configurations that needs to be used when creating the App in Intune.
