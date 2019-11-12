# GetComputerInfo.ps1
Powershell script for getting data out of domain joined computers
```powershell
<#
.SYNOPSIS
  Name: GetComputerInfo.ps1
  The purpose of this script is to retrieve basic information from a group of PCs.
  
.DESCRIPTION
  This is a script to retrieve basic information computers in a domain.
  It will gather hardware specifications, Operating System, RAM size and monitors and export them to a .csv file.

.NOTES
  Created: 23-04-2019
  Author: alexfour

  Monitor function from https://community.spiceworks.com/how_to/148349-get-desktop-monitor-information-powershell-script
  Author: lahimakonem

.EXAMPLE
  Insert all the domain computer names into the $ComputerNames array.
  Run the GetComputerInfo script to retrieve the information and to export a .csv.
#>
```
