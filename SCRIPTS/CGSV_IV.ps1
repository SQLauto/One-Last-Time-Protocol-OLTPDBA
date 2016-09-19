<#
.Synopsis
Gets computername as input and displays SQL Services. Also highlights stopped services in RED and running in GREEN
#>
[CmdletBinding()]
param
(
[parameter(mandatory=$true)]
[string]$server
)


Get-service  -ComputerName $server -displayname "*SQL*" | where{$_.StartType -ne "disabled"  } | select MachineName,status,name,displayname,StartType | foreach{
if ($_.Status -eq 'Stopped')
{[console]::ForegroundColor='red';$_;}
else
{[console]::ForegroundColor='Green';$_;}
}

[console]::ForegroundColor='White'