========= Intune Driver Installer using PowerShell =========

Description
==============
Install drivers on Windows through Intune using PowerShell.
This README contains instructions to create and configure the App in Intune.

Required Files
===================
IntuneWin: {{--IntuneWin--}}
Detection Script: {{--DetectionScript--}}

Required Commands
=====================
Install Command: powershell.exe -ExecutionPolicy Bypass -File .\Install-Driver.ps1
Uninstall Command: powershell.exe -ExecutionPolicy Bypass -File .\Uninstall-Driver.ps1

Return Codes
===============
0 - Success
1 - Failed

Driver Details
==================
Driver Name: {{--DriverName--}}
Driver Version: {{--DriverVersion}}

===============
Instructions
===============
1. Log into Microsoft Endpoint (https://endpoint.microsoft.com).

2. Navigate to Home > Apps > Windows | Windows Apps.

3. Create a new App with App Type: Windows app (Win32).

4. Upload IntuneWin file specified in this README.

5. Update Name, Description, Publisher appropriately. Recommended to fill in App Version using Driver Verison specified in this README.

6. In Program, update Install command using Install Command specified in this README.

7. Update Uninstall command using Uninstall Command specified in this README.

8. Ensure Install behavior is set to System.

9. Remove all Return Codes and add Return Codes specified in this README.

10. Select appropriate Operating system architecture and Minimum operating system.

11. In Detection rules, choose "Use a custom detection script" as Rules format.

12. Upload Detection Script specified in this README.

13. Configure all other options as necessary, then choose Create.

14. Setup complete. Intune will schedule driver install.