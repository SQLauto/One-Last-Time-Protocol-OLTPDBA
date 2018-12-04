function Format-Color([hashtable] $Colors = @{}, [switch] $SimpleMatch) {
    $lines = ($input | Out-String) -replace "`r", "" -split "`n"
    foreach ($line in $lines) {
        $color = ''
        foreach ($pattern in $Colors.Keys) {
            if (!$SimpleMatch -and $line -match $pattern) { $color = $Colors[$pattern] }
            elseif ($SimpleMatch -and $line -like $pattern) { $color = $Colors[$pattern] }
        }
        if ($color) {
            Write-Host -ForegroundColor $color $line
        }
        else {
            Write-Host $line
        }
    }
}

function Set-SQLServicesManual {

    param(
        [cmdletbinding()]
        [parameter(mandatory = $true)]
        [string[]]$computername
    )

    ##Directory for the ouptut/error
    #$wdir = pwd | select -ExpandProperty path #To use current working directory
    $wdir = $env:USERPROFILE #to use the homedirectory of current user
    $Printdate = date -Format("ddMMMyy_Hmm")

    Write-output "`n**Output\error will be saved to folder $wdir`n"

    foreach ($cname in $computername) {
        try { 
            $sqlservices = gwmi win32_service -Filter "displayname like 'SQL%' and not StartMode='Disabled' and not name='SQLWriter'" -ComputerName $cname -ErrorAction stop
            Write-Output "Before Startup change"
            $sqlservices | select __server, name, displayname, state, startmode, startname |ft -auto | Format-Color @{'Running' = 'Green'; 'stopped' = 'RED'}
    
            ##Changing start type
            foreach ($eachsqlser in $sqlservices) {
                if ($eachsqlser.startmode -eq 'Auto') {
                    $servicename = $eachsqlser.name
                    Set-Service -ComputerName $cname -Name $servicename -StartupType Manual
                    Write-Verbose "Changed StartMode to Manual for service: $servicename"
                }
            }

            Write-Output "`nAfter Startup change"
            $sqlservices = gwmi win32_service -Filter "displayname like 'SQL%' and not StartMode='Disabled' and not name='SQLWriter'" -ComputerName $cname -ErrorAction stop
            $sqlservices | select __server, name, displayname, state, startmode, startname|  Export-Csv "$wdir\SQLStartupManual_$printdate.csv"  -NoTypeInformation -force -append
            $sqlservices | select __server, name, displayname, state, startmode, startname |ft -auto | Format-Color @{'Running' = 'Green'; 'stopped' = 'RED'}
        }
        catch {
            "Error checking for SQL Services in host $cname, reason below" | Out-File "$wdir\Errors_SQLStartupManual_$printdate.txt" -Append
            $errout = Test-Connection -ComputerName $cname -Count 1 -EA SilentlyContinue 
            if (!$errout)
            {"**Unable to ping the Server: $cname" | Out-File "$wdir\Errors_SQLStartupManual_$printdate.txt" -Append}
            else
            {"**$env:USERNAME does not have access to $cname" | Out-File "$wdir\Errors_SQLStartupManual_$printdate.txt" -Append}
        }

    }

    #open output directory
    $opendir = Read-Host "open Output\error directory $wdir ?, Y\N: "
    if ($opendir -eq 'y') {ii $wdir}
    else {break}
}