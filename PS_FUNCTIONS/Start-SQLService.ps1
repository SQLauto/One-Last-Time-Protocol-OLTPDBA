<#
.Synopsis
Script to find SQL Services on local\remote host(s) and starts the services which are stopped state with confirmation. 
.DESCRIPTION
Script to find SQL Services on local\remote host(s) and starts the services which are stopped state with confirmation. 

1.Checks for SQL Services and its status in list of host(s) from input
2.Starts SQL Service if stopped based on user input
3.Output saved as StartSQLService_$printdate.csv
4.Errors saved as Errors_StartSQLServicee_$printdate.txt

Note: Update variable $wdir to the location where output to be saved. By default saves output & errors to user's home directory

#>


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



function Start-SQLService {
    ##Parameters for the function
    param
    (
        [cmdletbinding()]
        [parameter(mandatory = $true, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]$ComputerName
    )

    ##Directory for the ouptut/error
    #$wdir = pwd | select -ExpandProperty path #To use current working directory
    $wdir = $env:USERPROFILE #to use the homedirectory of current user
    $Printdate = date -Format("ddMMMyy_Hmm")

    Write-output "`n**Output\error will be saved to folder $wdir`n"

    foreach ($vser in $ComputerName) {
   
        try {   
            $sqlservices = gwmi win32_service -Filter "displayname like 'SQL%' and not StartMode='Disabled' and not name='SQLWriter' and not name like 'MSSQLFDLauncher%'" -ComputerName $vser -ErrorAction stop
            $sqlservices | select __server, displayname, state, startmode, processid |ft -auto | Format-Color @{'Running' = 'Green'; 'stopped' = 'RED'}
            $stoppedsrv = ($sqlservices | where {$_.state -eq 'stopped'})
     
            if ($($stoppedsrv.count) -eq 0 -and $($sqlservices.count) -ne 0) {
                Write-Output "All SQL & Related services are in Running state on host:$vser "
                $sqlservices | select __server, displayname, state, startmode, processid |Export-Csv "$wdir\GetSQLService_$printdate.csv"  -NoTypeInformation -force -append
            }
            elseif ($($sqlservices.count) -eq 0) {write-host "No SQL Services found on host $vser" -ForegroundColor Yellow}
            else {
                $action = Read-Host "In host: $vser, $($stoppedsrv.count) service(s)are in stopped state. Would you like to start them? Y\N"
                if ($action -eq 'y') {
                    $stoppedsrv.startservice() | Out-Null
                    Start-Sleep -Milliseconds 5000
                    $actiony = gwmi win32_service -Filter "displayname like 'SQL%' and not StartMode='Disabled'" -ComputerName $vser |  select __server, displayname, state, startmode, exitcode, processid
                    $actiony | ft -AutoSize | Format-Color @{'Running' = 'Green'; 'Stopped' = 'Red'; 'Start Pending' = 'yellow'}
                    $actiony | select __server, displayname, state, startmode, processid  | Export-Csv "$wdir\GetSQLService_$printdate.csv"  -NoTypeInformation -force -append
                }
                else {
                    $sqlservices | select __server, displayname, state, startmode, processid  |Export-Csv "$wdir\GetSQLService_$printdate.csv"  -NoTypeInformation -force -append
                }
            }
        }

        catch {
            "Error checking SQL services state in host $vser,reason below" | Out-File "$wdir\Errors_GetSQLService_$printdate.txt" -Append
            $errout = Test-Connection -ComputerName $vser -Count 1 -EA SilentlyContinue 
            if (!$errout)
            {"**Unable to ping the Server:  $vser" | Out-File "$wdir\Errors_GetSQLService_$printdate.txt" -Append}
            else
            {"**$env:USERNAME does not have access to $vser" | Out-File "$wdir\Errors_GetSQLService_$printdate.txt" -Append}

        }


    }
    $opendir = Read-Host "open Output\error directory $wdir ?, Y\N: "
    if ($opendir -eq 'y') {ii $wdir}
    else {break}

}