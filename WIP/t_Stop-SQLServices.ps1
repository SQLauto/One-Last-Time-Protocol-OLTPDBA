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


function Stop-SQLServices
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
    $sqlservices= gwmi win32_service -Filter "displayname like 'SQL%' and not StartMode='Disabled' and not name='SQLWriter'" -ComputerName $vser -ErrorAction stop
    $sqlservices | select __server,displayname,state,startmode,processid |ft -auto | Format-Color @{'Running'='Green';'stopped'='RED'} 
    $dependent= ($sqlservices | where{$_.displayname -like 'SQL Server Agent (*' -and $_.state -ne 'stopped'})
    $main= ($sqlservices | where{$_.displayname -notlike 'SQL Server Agent (*' -and $_.state -ne 'stopped'})

    $confirm = Read-Host "Would you like to stop the SQL services? Y\N"
        if($confirm -eq 'y')
        {
        $dependent.stopservice() | Out-Null
        Start-Sleep -Seconds 5
        $main.stopservice() | Out-Null
        Start-Sleep -Seconds 10
        }

    $sqlservices = gwmi win32_service -Filter "displayname like 'SQL%' and not StartMode='Disabled' and not name='SQLWriter'" -ComputerName $vser -ErrorAction stop
    $sqlservices | select __server,name,displayname,state,startmode,processid |ft -auto | Format-Color @{'Running'='Green';'stopped'='RED'}
    }
    catch
    {
    "Error checking for SQL Services in host $vser, reason below" | Out-File "$wdir\Errors_StopSQLService_$printdate.txt" -Append
    $errout = Test-Connection -ComputerName $vser -Count 1 -EA SilentlyContinue 
    if(!$errout)
    {"**Unable to ping the Server: $vser" | Out-File "$wdir\Errors_StopSQLService_$printdate.txt" -Append}
    else
    {"**$env:USERNAME does not have access to $vser" | Out-File "$wdir\Errors_StopSQLService_$printdate.txt" -Append}
    }
}

}