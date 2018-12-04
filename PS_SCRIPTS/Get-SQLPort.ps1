param
(
    [parameter(mandatory = $true)]
    [string[]]$computername
)

foreach ($cname in $computername) {
    $namespace = gwmi -Namespace "root\microsoft\sqlserver" -Class "__Namespace" -Filter "name like 'ComputerManagement%'" -ComputerName $cname | sort desc | select -ExpandProperty name -First 1

    $ins = GWMI -computername $cname  -Namespace "root\microsoft\SqlServer\$namespace" -Class ServerNetworkProtocolProperty -Filter "IPAddressName='IPAll' and not propertystrval=''" | select pscomputername, instancename, propertystrval, PropertyName, IPAddressName, ProtocolName

    $SQLPort = @()

    foreach ($iname in $ins) {
        if ($iname.instancename -eq "MSSQLSERVER") {
            #$dfin = $iname.instancename
            #$dfport = $iname.propertystrval
            $dportisdynamic = switch ($($iname.PropertyName)) {"TcpDynamicPorts" {"Dynamic"} "TcpPort" {"Fixed"}}
            $dprop = New-Object System.Object
            $dprop | Add-Member -type NoteProperty -name ServerName -Value $iname.PSComputerName
            $dprop | Add-Member -type NoteProperty -name InstaneName -Value $iname.instancename
            $dprop | Add-Member -type NoteProperty -name ConnString -Value "$($iname.pscomputername),$($iname.propertystrval)"
            $dprop | Add-Member -type NoteProperty -name PortType -Value $dportisdynamic
            #write-output "$($iname.pscomputername),$dfport"
            $SQLPort += $dprop
        }

        else {
            $namedins = $iname.InstanceName
            $nport = $iname.propertystrval
            $hostins = $iname.pscomputername
            $nportisdynamic = switch ($($iname.PropertyName)) {"TcpDynamicPorts" {"Dynamic"} "TcpPort" {"Fixed"}}
            $fqnamed = ("$hostins\{0}" -f $namedins)
            $NamedProp = New-Object System.Object
            $NamedProp | Add-Member -type NoteProperty -name ServerName -Value $iname.PSComputerName
            $NamedProp | Add-Member -type NoteProperty -name InstaneName -Value $iname.instancename
            $NamedProp | Add-Member -type NoteProperty -name ConnString -Value "$fqnamed,$nport"
            $NamedProp | Add-Member -type NoteProperty -name PortType -Value $nportisdynamic
            $SQLPort += $NamedProp
        }
    }

    $SQLPort
}