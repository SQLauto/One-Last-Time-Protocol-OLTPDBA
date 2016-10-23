
 $ins= Get-WmiObject -Namespace "root\Microsoft\SqlServer\ComputerManagement12" -Class ServerNetworkProtocolProperty 

foreach($iname in $ins)
{
if($iname.instancename -eq "MSSQLSERVER")
{
write-output "$($iname.pscomputername)"
}

else
{
$namedins = $iname.InstanceName
$hostins = $iname.pscomputername
$fqnamed = ("$hostins\{0}" -f $namedins)
Write-Output "$fqnamed"
}

}
