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

#Initialization
$ComputerInfo = New-Object System.Object
$MonitorList = New-Object System.Collections.ArrayList
$Inventory = New-Object System.Collections.ArrayList

#List all the computers we want to scrape for info 
$ComputerNames = @("COMPUTER1,COMPUTER2,COMPUTER3")

#Initialize lists to track the progress through the list
$ListIndex = 1
$SizeOfList = $ComputerNames.Count;

#Gets all the devices in the AD. Not recommended as it picks up everything. (Preset is "FIRMAD0*")
#$Computers = Get-ADComputer -Filter 'Name -like "FIRMAD0*"' -Properties Name
#$ComputerNames = $Computers.Name
#Makes sure that the .csv layout is correct by using a computer that is known to be on and also has correct info
#$ComputerNames = ,"FIRMAD023" + $Computers.Name

##############################################
#Functions
#Detect more specific operating system version
switch -Wildcard ($ComputerOS){
    "6.1.7600" {$OS = "Windows 7"; break}
    "6.1.7601" {$OS = "Windows 7 SP1"; break}
    "6.2.9200" {$OS = "Windows 8"; break}
    "6.3.9600" {$OS = "Windows 8.1"; break}
    "10.0.*" {$OS = "Windows 10"; break}
    default {$OS = "Unknown Operating System"; break}
} 

#Detect monitors and their manufacturers
#List of Manufacture Codes that could be pulled from WMI and their respective full names. Used for translating later down.
function Get-Monitors { 
    $Computer1 = $Computer
    $ManufacturerHash = @{ 
    "AAC" =	"AcerView";
    "ACR" = "Acer";
    "AOC" = "AOC";
    "AIC" = "AG Neovo";
    "APP" = "Apple Computer";
    "AST" = "AST Research";
    "AUO" = "Asus";
    "BNQ" = "BenQ";
    "CMO" = "Acer";
    "CPL" = "Compal";
    "CPQ" = "Compaq";
    "CPT" = "Chunghwa Pciture Tubes, Ltd.";
    "CTX" = "CTX";
    "DEC" = "DEC";
    "DEL" = "Dell";
    "DPC" = "Delta";
    "DWE" = "Daewoo";
    "EIZ" = "EIZO";
    "ELS" = "ELSA";
    "ENC" = "EIZO";
    "EPI" = "Envision";
    "FCM" = "Funai";
    "FUJ" = "Fujitsu";
    "FUS" = "Fujitsu-Siemens";
    "GSM" = "LG Electronics";
    "GWY" = "Gateway 2000";
    "HEI" = "Hyundai";
    "HIT" = "Hyundai";
    "HSL" = "Hansol";
    "HTC" = "Hitachi/Nissei";
    "HWP" = "HP";
    "IBM" = "IBM";
    "ICL" = "Fujitsu ICL";
    "IVM" = "Iiyama";
    "KDS" = "Korea Data Systems";
    "LEN" = "Lenovo";
    "LGD" = "Asus";
    "LPL" = "Fujitsu";
    "MAX" = "Belinea"; 
    "MEI" = "Panasonic";
    "MEL" = "Mitsubishi Electronics";
    "MS_" = "Panasonic";
    "NAN" = "Nanao";
    "NEC" = "NEC";
    "NOK" = "Nokia Data";
    "NVD" = "Fujitsu";
    "OPT" = "Optoma";
    "PHL" = "Philips";
    "REL" = "Relisys";
    "SAN" = "Samsung";
    "SAM" = "Samsung";
    "SBI" = "Smarttech";
    "SGI" = "SGI";
    "SNY" = "Sony";
    "SRC" = "Shamrock";
    "SUN" = "Sun Microsystems";
    "SEC" = "Hewlett-Packard";
    "TAT" = "Tatung";
    "TOS" = "Toshiba";
    "TSB" = "Toshiba";
    "VSC" = "ViewSonic";
    "ZCM" = "Zenith";
    "UNK" = "Unknown";
    "_YV" = "Fujitsu";
    }

    #Grabs the Monitor objects from WMI
    $Monitors = Get-WmiObject -Namespace "root\WMI" -Class "WMIMonitorID" -ComputerName $Computer1 -ErrorAction SilentlyContinue
    #Creates an empty array to hold the data
    $Monitor_Array = @()
    
    
    #Takes each monitor object found and runs the following code:
    ForEach ($Monitor in $Monitors) {
      
        #Grabs respective data and converts it from ASCII encoding and removes any trailing ASCII null values
        If ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName) -ne $null) {
        $Mon_Model = ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)).Replace("$([char]0x0000)","")
        } else {
        $Mon_Model = $null
        }
        $Mon_Serial_Number = ([System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)).Replace("$([char]0x0000)","")
        $Mon_Attached_Computer = ($Monitor.PSComputerName).Replace("$([char]0x0000)","")
        $Mon_Manufacturer = ([System.Text.Encoding]::ASCII.GetString($Monitor.ManufacturerName)).Replace("$([char]0x0000)","")
      
        #Filters out "non monitors". Place any of your own filters here. These two are all-in-one computers with built in displays. I don't need the info from these.
        If ($Mon_Model -like "*800 AIO*" -or $Mon_Model -like "*8300 AiO*") {Break}
      
        #Sets a friendly name based on the hash table above. If no entry found sets it to the original 3 character code
        $Mon_Manufacturer_Friendly = $ManufacturerHash.$Mon_Manufacturer
        If ($Mon_Manufacturer_Friendly -eq $null) {
        $Mon_Manufacturer_Friendly = $Mon_Manufacturer
        }
      
        #Creates a custom monitor object and fills it with 4 NoteProperty members and the respective data
        $Monitor_Obj = [PSCustomObject]@{
        Manufacturer     = $Mon_Manufacturer_Friendly
        Model            = $Mon_Model
        SerialNumber     = $Mon_Serial_Number
        AttachedComputer = $Mon_Attached_Computer
        }
      
        #Appends the object to the array
        #$Monitor_Array += $Monitor_Obj

        #Write-Output $Monitor_Obj.Model
        $MonitorList.Add($Monitor_Obj.Model) | Out-Null
        #Write-Output $MonitorList
    }
}
#END OF FUNCTIONS
##############################################

#Start foreach loop
Foreach ($Computer in $ComputerNames) {

    #Reinitialize $ComputerInfo amd $MonitorList arrays in order to empty out the previous hardware
    $ComputerInfo = New-Object System.Object
    $MonitorList = New-Object System.Collections.ArrayList

    #Test if connection can be established
    $Connection = Test-Connection $Computer -Count 1 -Quiet
    
    #If connection can be established begin scraping
    if ($Connection -eq "True"){

        #Data gathering
        $ComputerOS = (Get-WmiObject Win32_OperatingSystem -ComputerName $Computer -EA SilentlyContinue).Version 
        $ComputerHW = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer | select Manufacturer,Model -EA SilentlyContinue
        $ComputerManufacturer = $ComputerHW.Manufacturer + " " + $ComputerHW.Model 
        $ComputerCPU = Get-WmiObject win32_processor -ComputerName $Computer | select Name -EA SilentlyContinue
        $ComputerCPU = $ComputerCPU.Name
        $ComputerRAM = Get-WmiObject Win32_PhysicalMemory -ComputerName $Computer | select Capacity -EA SilentlyContinue
        #Call monitor function
        Get-Monitors


        #Adding data to array
        $ComputerInfo | Add-Member -MemberType NoteProperty -Name "Name" -Value "$Computer" -Force
        $ComputerInfo | Add-Member -MemberType NoteProperty -Name "OperatingSystem" -Value "$OS"
        $ComputerInfo | Add-Member -MemberType NoteProperty -Name "Manufacturer" -Value "$ComputerManufacturer" -force
        $ComputerInfo | Add-Member -MemberType NoteProperty -Name "CPU" -Value "$ComputerCPU" -Force 

        #Add each RAM stick into a separate field
        foreach ($RAMStick in $ComputerRAM)
        {
            try {
            $IndexNum = "RAM " + $ComputerRAM.IndexOf($RAMStick)
            $RAMStick =   $RAMStick.Capacity
            $ComputerInfo | Add-Member -MemberType NoteProperty -Name $IndexNum -Value "$RAMStick" -force
            }
            catch {}
        }

        #Add each Monitor to a separate field
        for ($i = 0; $i -lt $MonitorList.Count; $i++)
        {
            $IndexNum = "Monitor " + $i
            $MonitorElement = $MonitorList[0]
            $ComputerInfo | Add-Member -MemberType NoteProperty -Name $IndexNum -Value "$MonitorElement" -force
        }
    
        #Add all of the gathered data in $ComputerInfo to $Inventory array for the final .csv export
        $Inventory.Add($ComputerInfo) | Out-Null
       
        #If the computer scraping was successful print out success
        $Computer = $Computer + "    OK" + "   ("+ $ListIndex + "/"+ $SizeOfList + ")"
        Write-Output $Computer

        #Increment the list index
        $ListIndex++
    }
    else
    {
        #If the computer scraping was unsuccessful print out failure
        $Computer = $Computer + "    FAIL" + " ("+ $ListIndex + "/"+ $SizeOfList + ")"
        Write-Output $Computer

        #Increment the list index
        $ListIndex++
    }


}

#Export output to .csv to root path
$Inventory | Export-Csv -Path .\Devicestest.Csv -Delimiter ';' -NoTypeInformation

#Show the contents of Devices.csv in console
#Get-Content -Path .\Devices.Csv