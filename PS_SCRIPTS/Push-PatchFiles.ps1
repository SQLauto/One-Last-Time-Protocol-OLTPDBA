function Push-PatchFiles
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$Servername,
        [alias('EO')]
        [SWITCH] $Exportoutput = $false
    )

$OutputDir = "$env:USERPROFILE"
$FolderComment = 'SQLPatch'
$SP  = 'K:\Test'
#$GDR = ''

$PushOutcome=@()

foreach ($ser in $Servername)
{

$BiggestDrive = gwmi win32_volume -ComputerName $ser -filter("drivetype = 3 and not label = 'System Reserved' and NOT Caption like '%\\VOLUME%'") | Sort-Object freespace -Descending | select -First 1 -ExpandProperty Caption
 
Write-Verbose "Largest drive in $ser is $BiggestDrive"
$DestinationPath = '\\'+"$ser"+'\'+"$($BiggestDrive.replace(':','$'))"+$FolderComment+'\'
Write-Verbose  "using folder $DestinationPath to copy the files"

$DestProp = New-Object System.Object
$DestProp | Add-Member -type NoteProperty -name ServerName -Value $ser
$DestProp | Add-Member -type NoteProperty -name PatchFiles_Path -Value $DestinationPath

$PushOutcome += $DestProp

cpi $sp  -Destination $DestinationPath -Recurse -Force
#-Filter *.ZIP
}

$PushOutcome | ft -AutoSize
if ($Exportoutput) {$PushOutcome | Export-Csv $("$OutputDir\PatchPath_"+(Get-Date -Format "yyyyMMddTHHmmss").tostring()+'.csv')  -NoTypeInformation -force -append}

}#Function Closure