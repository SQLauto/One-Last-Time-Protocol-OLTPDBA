param(
[cmdletbinding()]
[parameter(mandatory=$true)]
[string[]]$computername
)

foreach($server in $computername)
{
$namespace = gwmi -Namespace "root\microsoft\sqlserver" -Class "__Namespace" -Filter "name like 'ComputerManagement%'" -ComputerName $server | sort desc | select -ExpandProperty name

 $raw_instance = GWMI -Namespace "root\microsoft\SqlServer\$namespace" -Class ServerSettings | select  -ExpandProperty instancename
  
  ForEach($iname in $raw_instance) 
  {
     if ($iname -eq "MSSQLSERVER") { $out_sqlins = "$server"; Write-Host "$out_sqlins" }
     else  { $out_sqlins = ("$server\{0}" -f $iname); Write-Host "$out_sqlins"  };

       }

}