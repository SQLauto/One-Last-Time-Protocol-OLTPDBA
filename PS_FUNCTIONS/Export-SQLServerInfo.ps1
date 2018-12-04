[CmdletBinding()]
[Alias()]
[OutputType([int])]
Param
(
    # Param1 help description
    [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
        Position = 0)]
    [string[]] $SQLInstance 
)

$AllDBSize = 'with fs
as
(
    select database_id, type, size * 8.0 / 1024 size
    from sys.master_files
)
select 
    name,
    (select sum(size) from fs where type = 0 and fs.database_id = db.database_id) DataFileSizeMB,
    (select sum(size) from fs where type = 1 and fs.database_id = db.database_id) LogFileSizeMB
from sys.databases db
order by datafilesizemb desc'

$LinkedServer = 'SELECT * FROM sys.Servers a LEFT OUTER JOIN sys.linked_logins b ON b.server_id = a.server_id LEFT OUTER JOIN sys.server_principals c ON c.principal_id = b.local_principal_id'

$LastFullbackup = "SELECT sd.name,MAX(backup_finish_date) AS LAST_BKP,MB.type,DATEDIFF(DAY,MAX(backup_finish_date),GETDATE()) AS DAYS_SINCE_LAST,DATEDIFF(hh,MAX(backup_finish_date),GETDATE()) AS HOURS_SINCE_LAST FROM sys.databases sd LEFT OUTER JOIN msdb..backupset MB ON sd.name=MB.database_name WHERE (sd.name<>'tempdb' and sd.state=0) and (MB.type='D' OR MB.type IS NULL) GROUP BY sd.name,MB.type ORDER BY DAYS_SINCE_LAST DESC"

$basicinfo = " declare @elpath varchar(200); set @elpath= CAST(SERVERPROPERTY('ErrorLogFileName')  as varchar(200));SELECT @@SERVERNAME Instance_Name,SERVERPROPERTY('EDITION') Edition,SERVERPROPERTY('PRODUCTVERSION') VersionNumber,SERVERPROPERTY('PRODUCTLEVEL') SP_Level,SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS [CurrentNodeName], SERVERPROPERTY('IsClustered') as IsCluster,LEFT(@elpath,(charindex('ERRORLOG',@elpath)-1)) ErrorLogPath,getdate() as DateChecked"

foreach ($instance in $SQLInstance) {

    $Wd = "$env:HOMEPATH\" ##add \ to the end
    $Instance_file = $instance.Replace("\", "_")
    $Filename = $Wd + $Instance_file.ToUpper() + "_SQLinfo_" + (Get-Date -Format "ddMMMyy_Hmm") + ".xlsx"
    $Filename

    Invoke-Sqlcmd2 -ServerInstance $instance -Query $basicinfo.ToString() | Select-Object * -ExcludeProperty  "RowError", "RowState", "Table", "ItemArray", "HasErrors" | Export-Excel -Path $Filename -WorkSheetname basicinfo -AutoSize -AutoFilter
    Invoke-Sqlcmd2 -ServerInstance $instance -Query "select * from sys.databases" |  Select-Object * -ExcludeProperty  "RowError", "RowState", "Table", "ItemArray", "HasErrors" | Export-Excel -Path $Filename -WorkSheetname DBStatus -AutoSize -AutoFilter
    Invoke-Sqlcmd2 -ServerInstance $instance -Query "select * from sys.configurations" |  Select-Object * -ExcludeProperty  "RowError", "RowState", "Table", "ItemArray", "HasErrors" | Export-Excel -Path $Filename -WorkSheetname configurations -AutoSize -AutoFilter
    Invoke-Sqlcmd2 -ServerInstance $instance -Query "select db_name(database_id) DBName,* from sys.master_files" |  Select-Object * -ExcludeProperty  "RowError", "RowState", "Table", "ItemArray", "HasErrors" |Export-Excel -Path $Filename -WorkSheetname master_files -AutoSize -AutoFilter
    Invoke-Sqlcmd2 -ServerInstance $instance -Query $LastFullbackup.ToString() |  Select-Object * -ExcludeProperty  "RowError", "RowState", "Table", "ItemArray", "HasErrors" | Export-Excel -Path $Filename -WorkSheetname DB_Backup -AutoSize -AutoFilter
    Invoke-Sqlcmd2 -ServerInstance $instance -Query $AllDBSize.ToString() | Select-Object * -ExcludeProperty  "RowError", "RowState", "Table", "ItemArray", "HasErrors" | Export-Excel -Path $Filename -WorkSheetname AllDBSize -AutoSize -AutoFilter
    Invoke-Sqlcmd2 -ServerInstance $instance -Query $LinkedServer.ToString() | Select-Object * -ExcludeProperty  "RowError", "RowState", "Table", "ItemArray", "HasErrors" | Export-Excel -Path $Filename -WorkSheetname LinkedServers -AutoSize -AutoFilter
}