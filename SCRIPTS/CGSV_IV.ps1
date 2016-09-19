[CmdletBinding()]
param
(
[parameter(mandatory=$true)]
[string[]]$server
)

#Function from link: http://www.bgreco.net/powershell/format-color/
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

$wdir = pwd | select -ExpandProperty path
$Printdate = date -Format("ddMMMyyyy")

Foreach ($PCname in $server)
    {
$output = Get-service  -ComputerName $PCname -displayname "*SQL*" | where{$_.StartType -ne "disabled"  } | select MachineName,displayname,status,StartType 
$output | Format-Color @{'stopped' = 'red'} | ft -AutoSize
$output |Export-Csv "$wdir\SQLState_$printdate.csv"  -NoTypeInformation -force -append

}