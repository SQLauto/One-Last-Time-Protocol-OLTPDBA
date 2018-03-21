    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string] $SQLInstance 
    )

foreach ($instance in $SQLInstance)
{

$Wd = "C:\Users\" ##add \ to the end
$Filename= $Wd+$instance.ToUpper()+"_alldetails_"+ (Get-Date -Format "yyyyMMddTHHmmss")+".xlsx"
$Filename


Invoke-Sqlcmd2 -ServerInstance $instance -Query "select * from sys.databases" | Select-Object * -ExcludeProperty  "RowError","RowState","Table","ItemArray","HasErrors" | Export-Excel -Path $Filename -WorkSheetname DBStatus -AutoSize -AutoFilter
Invoke-Sqlcmd2 -ServerInstance $instance -Query "select * from sys.configurations" | Select-Object * -ExcludeProperty  "RowError","RowState","Table","ItemArray","HasErrors" |  Export-Excel -Path $Filename -WorkSheetname configurations -AutoSize -AutoFilter
Invoke-Sqlcmd2 -ServerInstance $instance -Query "select * from sys.master_files" |  Select-Object * -ExcludeProperty  "RowError","RowState","Table","ItemArray","HasErrors" |  Export-Excel -Path $Filename -WorkSheetname master_files -AutoSize -AutoFilter
}