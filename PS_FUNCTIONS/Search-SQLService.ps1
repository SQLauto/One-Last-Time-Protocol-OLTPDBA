<#
.Synopsis
Script to find SQL Services and its status on local\remote host(s). Also exports output to CSV in user's home directory.
.DESCRIPTION
Script to find SQL Services and its status on local\remote host(s).

1.Checks for SQL Services in list of host(s) from input
2.Output saved as SearchSQLService_$printdate.csv
3.Errors saved as Errors_SearchSQLService.txt

Note: Update variable $wdir to the location where output to be saved. By default saves output & errors to user's home directory

#>


function Format-Color([hashtable] $Colors = @{}, [switch] $SimpleMatch) {
	$lines = ($input | Out-String) -replace "`r", "" -split "`n"
	foreach($line in $lines) {
		$color = ''
		foreach($pattern in $Colors.Keys){
			if(!$SimpleMatch -and $line -match $pattern) { $color = $Colors[$pattern] }
			elseif ($SimpleMatch -and $line -like $pattern) { $color = $Colors[$pattern] }
		}
		if($color) {
			Write-Host -ForegroundColor $color $line
		} else {
			Write-Host $line
		}
	}
}



function Search-SQLService
{
##Parameters for the function
param
(
[cmdletbinding()]
[parameter(mandatory=$true,ValueFromPipelineByPropertyName,ValueFromPipeline)]
[string[]]$ComputerName
)

##Directory for the ouptut/error
#$wdir = pwd | select -ExpandProperty path #To use current working directory
$wdir = $env:USERPROFILE #to use the homedirectory of current user
$Printdate = date -Format("ddMMMyy_Hmm")

Write-output "`n**Output\error will be saved to folder $wdir`n"

foreach($vser in $ComputerName)
{
   
   try{   
   $sqlservices= gwmi win32_service -Filter "displayname like 'SQL%' and not StartMode='Disabled' and not name='SQLWriter' and not name like 'MSSQLFDLauncher%'" -ComputerName $vser -ErrorAction stop
   $sqlservices | select __server,displayname,state,startmode,processid |ft -auto | Format-Color @{'Running'='Green';'stopped'='RED'}
 
   if($($sqlservices.count) -ne 0)
   {
   $sqlservices | select __server,displayname,state,startmode,processid |Export-Csv "$wdir\SearchSQLService_$printdate.csv"  -NoTypeInformation -force -append
   }
   elseif($($sqlservices.count) -eq 0){write-host "No SQL Services found on host $vser" -ForegroundColor Yellow }

   }

   catch
   {
   "Error checking for SQL Services in host $vser, reason below" | Out-File "$wdir\Errors_SearchSQLService_$printdate.txt" -Append
   $errout = Test-Connection -ComputerName $vser -Count 1 -EA SilentlyContinue 
   if(!$errout)
    {"**Server $vser doesnt exist" | Out-File "$wdir\Errors_SearchSQLService_$printdate.txt" -Append}
   else
    {"**$env:USERNAME does not have access to $vser" | Out-File "$wdir\Errors_SearchSQLService_$printdate.txt" -Append}

   }


}

$opendir = Read-Host "open Output\error directory $wdir ?, Y\N: "
if($opendir -eq 'y') {ii $wdir}
else{break}

}