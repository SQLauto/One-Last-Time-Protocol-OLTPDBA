<#
.Synopsis
 PS Script to check access to servers(from input) and find SQL Services status. Additionally you can save output to file.
.DESCRIPTION
PS Script to check access to servers(from input) and find SQL Services status.

1.Checks the access to list of computers from input
2.Updates the files No_Access & Servers2Check
3.Checks for SQL services and displays the output

Note: Update variable $wdir to the location where output to be saved. 

Access help through "help .\Find-SQLServices_File_Input.ps1"

.EXAMPLE
PS S:\> S:\Find-SQLServices_IV.ps1
cmdlet Find-SQLServices_IV.ps1 at command pipeline position 1
Supply values for the following parameters:
server[0]: SERVER1
server[1]: SERVER2
server[2]: SERVER4
server[3]: SERVER5
server[4]: 

 ** Scanning servers from input for SQL Services**
 

__SERVER name                                     State   StartMode displayname                                       
-------- ----                                     -----   --------- -----------                                       
SERVER1  MsDtsServer120                           Stopped Manual    SQL Server Integration Services 12.0              
SERVER1  MSOLAP$SQL1                              Stopped Manual    SQL Server Analysis Services (SQL1)                 
SERVER1  MSSQL$SQL1                               Stopped Manual    SQL Server (SQL1)                                   
SERVER1  MSSQLFDLauncher                          Stopped Manual    SQL Full-text Filter Daemon Launcher (MSSQLSERVER)
SERVER1  MSSQLFDLauncher$SQL1                     Stopped Manual    SQL Full-text Filter Daemon Launcher (SQL1)         
SERVER1  MSSQLSERVER                              Stopped Manual    SQL Server (MSSQLSERVER)                          
SERVER1  ReportServer$SQL1                        Stopped Manual    SQL Server Reporting Services (SQL1)                
SERVER1  SQL Server Distributed Replay Client     Stopped Manual    SQL Server Distributed Replay Client              
SERVER1  SQL Server Distributed Replay Controller Stopped Manual    SQL Server Distributed Replay Controller          
SERVER1  SQLAgent$SQL1                            Stopped Manual    SQL Server Agent (SQL1)                             
SERVER1  SQLBrowser                               Stopped Manual    SQL Server Browser                                
SERVER1  SQLSERVERAGENT                           Stopped Manual    SQL Server Agent (MSSQLSERVER)                    
SERVER1  SQLWriter                                Running Auto      SQL Server VSS Writer                             


Save output to CSV? (Y/N) : y

** Output saved as .\Find_SQLService_output18Sep2016.csv
#>
[CmdletBinding()]
param(
[parameter(mandatory=$true)]
[string[]]$server
)

$wdir = pwd | select -ExpandProperty path
Write-Host "`n ** Scanning servers from input for SQL Services**`n"
if(!(Test-Path  -Path "$wdir\servers2check.txt")){New-Item -ItemType File -Path "$wdir\servers2check.txt" | Out-Null} 
clc "$wdir\servers2check.txt"

Foreach ($PCname in $server)
    {
    $AccessPath = "\\" + $PCName + '\c$\'
    $Result = Test-Path $AccessPath -ErrorAction SilentlyContinue
    if ($Result -eq "True") {$pcname >>"$wdir\servers2check.txt"}
    else {$pcname >> $wdir\No_Access.txt}
    }

#Scanning Servers for SQL on which we have access
$fservers= gc "$wdir\servers2check.txt"
$Printdate = date -Format("ddMMMyyyy")
Write-Host "`n**SQL Scan result on $Printdate**`n "
gwmi win32_service -ComputerName $fservers -filter ("displayname like 'SQL%'")  | select __server,name,State,StartMode,displayname  | ft -AutoSize

#Save output to file
$confirm = Read-Host "Save output to CSV? (Y/N) "
if($confirm -in ('y','yes'))
{gwmi win32_service -ComputerName $fservers -filter ("displayname like 'SQL%'")  | select __server,name,State,StartMode,displayname  | Export-Csv "$wdir\Find_SQLService_output_$printdate.csv"  -NoTypeInformation -force
Write-Host "`n** Output saved as $wdir\Find_SQLService_output$printdate.csv"
} 