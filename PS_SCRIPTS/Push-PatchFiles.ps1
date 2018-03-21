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
        [string[]]$Servername
    )

$FolderComment = 'SQLPatch'
$SP  = 'K:\Test'
$GDR = ''

foreach ($ser in $Servername)
{

$BiggestDrive = gwmi win32_volume -ComputerName $ser -filter("drivetype = 3 and not label = 'System Reserved' and NOT Caption like '%\\VOLUME%'") | Sort-Object freespace -Descending | select -First 1 -ExpandProperty Caption

Write-Host "Largest drive in $ser is $BiggestDrive" -ForegroundColor Yellow
$DestinationPath = '\\'+"$ser"+'\'+"$($BiggestDrive.replace(':','$'))"+$FolderComment+'\'
Write-Host  $DestinationPath

cpi $sp  -Destination $DestinationPath -Recurse -Force
#-Filter *.ZIP
}

}#Function Closure