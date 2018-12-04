#Example: Set-SQLServiceAccPass -ComputerName LOCALHOST -AccName .\TP1

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



function Set-SQLServiceAccPass {
    ##Parameters for the function
    param
    (
        [cmdletbinding()]
        [parameter(mandatory = $true, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]$ComputerName,
        [parameter(mandatory = $true)]
        [string]$AccName
    )

    ##Directory for the ouptut/error
    #$wdir = pwd | select -ExpandProperty path #To use current working directory
    $wdir = $env:USERPROFILE #to use the homedirectory of current user
    $Printdate = date -Format("ddMMMyy_Hmm")

    Write-output "`n**Output\error will be saved to folder $wdir`n"

    foreach ($vser in $ComputerName) {
   
        try {   
            $sqlservices = gwmi win32_service -Filter "displayname like 'SQL%' and not StartMode='Disabled' and not name='SQLWriter' and not name like 'MSSQLFDLauncher%'" -ComputerName $vser -ErrorAction stop  | where {$_.startname -eq "$AccName"}
            Write-Host "`nCurrent SQL Services state on host: $vser"
            $sqlservices | select __server, displayname, state, startmode, name, startname |ft -auto | Format-Color @{'Running' = 'Green'; 'stopped' = 'RED'}
 
            if ($($sqlservices.count) -ne 0) {
                $sqlservices | select __server, displayname, state, startmode, name, startname |Export-Csv "$wdir\SQLServiceAccPass_$printdate.csv"  -NoTypeInformation -force -append
                $Changepass = Read-Host "Would you like to change the password for above services running under $accname ? Y\N"
                if ($Changepass -eq 'Y') {
                    #Change
                    $newpass = Read-Host "`nEnter the new password for $accname`n"
                    foreach ($nsservice in $sqlservices) {
                        $cpassresult = $nsservice.change($null, $null, $null, $null, $null, $null, $accname, $newpass, $null, $null, $null) 
                        if ($cpassresult.ReturnValue -eq "0") {write-host "$($nsservice.Displayname) -> Sucessfully Changed password" -ForegroundColor Yellow} 
                    }
                    #Restart
                    $stoppedsrv = ($sqlservices | where {$_.state -eq 'Running'})
                    if ($($stoppedsrv.count) -ne 0) {   
                        $CNRestart = Read-Host "`nWould you like to restart the SQL services running under $accname ? Y\N"
                        if ($CNRestart -eq 'Y') {
                            $dependent = ($sqlservices | where {$_.displayname -like 'SQL Server Agent (*' -and $_.state -ne 'stopped'})
                            if ($($dependent.count) -ne 0) {foreach ($depser in $dependent) {$depser.stopservice() | Out-Null}}
                            $main = ($sqlservices | where {$_.displayname -notlike 'SQL Server Agent (*' -and $_.state -ne 'stopped'})
                            if ($($main.count) -ne 0) {
                                foreach ($mainser in $main) 
                                {$mainser.StopService() | Out-Null; $mainser.StartService() | Out-Null}
                            }
                            Start-Sleep -Seconds 10
                            if ($($dependent.count) -ne 0) {foreach ($depser in $dependent) {$depser.StartService() | Out-Null}}

                            Write-Host "`nSQL Services state after restart on host: $vser"
                            $postsqlservices = gwmi win32_service -Filter "displayname like 'SQL%' and not StartMode='Disabled' and not name='SQLWriter' and not name like 'MSSQLFDLauncher%'" -ComputerName $vser -ErrorAction stop  | where {$_.startname -eq "$AccName"}
                            $postsqlservices | select __server, displayname, state, startmode, name, startname |ft -auto | Format-Color @{'Running' = 'Green'; 'stopped' = 'RED'}
                        }#RestartIF
                    }#StopCountIF
                    Else {Write-Host "All SQL Services are already stopped in host: $vser" -ForegroundColor Yellow}
                }
            }
            elseif ($($sqlservices.count) -eq 0) {write-host "No SQL Services running under $accname found on host: $vser" -ForegroundColor Yellow }

        }

        catch {
            "Error checking for SQL Services in host $vser, reason below" | Out-File "$wdir\Errors_SQLServiceAccPass_$printdate.txt" -Append
            $errout = Test-Connection -ComputerName $vser -Count 1 -EA SilentlyContinue 
            if (!$errout)
            {"**Unable to ping the Server: $vser" | Out-File "$wdir\Errors_SQLServiceAccPass_$printdate.txt" -Append}
            else
            {"**$env:USERNAME does not have access to $vser" | Out-File "$wdir\Errors_SQLServiceAccPass_$printdate.txt" -Append}

        }#Catch


    }#ForeachComputer

    $opendir = Read-Host "open Output\error directory $wdir ?, Y\N: "
    if ($opendir -eq 'y') {ii $wdir}
    else {break}

}