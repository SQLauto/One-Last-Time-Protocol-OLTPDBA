param
(
[parameter(mandatory=$true)]
[string[]]$computername
)

foreach($cname in $computername)
{
$namespace = gwmi -Namespace "root\microsoft\sqlserver" -Class "__Namespace" -Filter "name like 'ComputerManagement%'" -ComputerName $cname | sort desc | select -ExpandProperty name

 $ins= GWMI -computername $cname  -Namespace "root\microsoft\SqlServer\$namespace" -Class ServerNetworkProtocolProperty | select pscomputername,instancename,propertystrval,PropertyName,IPAddressName,ProtocolName  | where{$_.IPAddressName -eq 'IPAll' -and $_.propertystrval -ne ''}

 $SQLPort=@()

 foreach($iname in $ins)
{
if($iname.instancename -eq "MSSQLSERVER")
{
#$dfin = $iname.instancename
#$dfport = $iname.propertystrval
$dprop = New-Object System.Object
$dprop | Add-Member -type NoteProperty -name ServerName -Value $iname.PSComputerName
$dprop | Add-Member -type NoteProperty -name InstaneName -Value $iname.instancename
$dprop | Add-Member -type NoteProperty -name ConnString -Value "$($iname.pscomputername),$($iname.propertystrval)"
#write-output "$($iname.pscomputername),$dfport"
$SQLPort += $dprop
}

else
{
$namedins = $iname.InstanceName
$nport = $iname.propertystrval
$hostins = $iname.pscomputername
$fqnamed = ("$hostins\{0}" -f $namedins)
$NamedProp = New-Object System.Object
$NamedProp | Add-Member -type NoteProperty -name ServerName -Value $iname.PSComputerName
$NamedProp | Add-Member -type NoteProperty -name InstaneName -Value $namedins
$NamedProp | Add-Member -type NoteProperty -name ConnString -Value "$fqnamed,$nport"
#Write-Output "$fqnamed,$nport"
$SQLPort += $NamedProp
}

$SQLPort

 ##format output
 <#$SQLPort = New-Object System.Object
 $SQLPort = 
@([pscustomobject]@{ServerName="$($iname.pscomputername)";InstanceName=$dfin;ConnString="$($iname.pscomputername),$dfport"},
[pscustomobject]@{ServerName="$($iname.pscomputername)";InstanceName=$namedins;ConnString="$fqnamed,$nport"})
 $SQLPort
 ###>



}
}