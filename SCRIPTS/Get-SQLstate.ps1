

#Function courtesy Brad Greco: http://www.bgreco.net/powershell/format-color/
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

function get-sqlstate
{
[CmdletBinding()]
param
(
[parameter(mandatory=$true)]
[string[]]$server
)
$wdir = pwd | select -ExpandProperty path #By default saves to current diretly, change if required.
$Printdate = date -Format("ddMMMyy_Hmm")
clc "$wdir\noaccess.txt" -ErrorAction SilentlyContinue
Foreach ($PCname in $server)
    {

    try
    {
#$output = Get-service  -ComputerName $PCname -displayname "*SQL*" | where{$_.StartType -ne "disabled"  } | select MachineName,displayname,status,StartType
$output = Get-service  -ComputerName $PCname  -displayname "*SQL*" -ErrorVariable e1 | where{$_.StartType -ne "disabled" -and $_.Name -notin('SQLWriter','SQL Server Distributed Replay Client','SQL Server Distributed Replay Controller') -and $_.Name -notlike 'MSSQLFDLauncher*' } | select MachineName,displayname,status,StartType  
$output | Format-Color @{'stopped' = 'red'} | ft -AutoSize
$output |Export-Csv "$wdir\SQLState_$printdate.csv"  -NoTypeInformation -force -append
}
catch
{
$PCname | Out-File "$wdir\noaccess.txt" -Append
ping $PCname | Out-File "$wdir\noaccess.txt" -Append
$e1 | Out-File "$wdir\noaccess.txt" -Append
}


}

}
