--Finding backup duration of each Db's
DECLARE @dbname sysname
SET @dbname = NULL --set this to be whatever dbname you want
SELECT bup.user_name AS [User],
 bup.database_name AS [Database],
 bup.server_name AS [Server],
 bup.backup_start_date AS [Backup Started],
 bup.backup_finish_date AS [Backup Finished]
 ,CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))/3600 AS varchar) + ' hours, ' 
 + CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))/60 AS varchar)+ ' minutes, '
 + CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))%60 AS varchar)+ ' seconds'
 AS [Total Time]
FROM msdb.dbo.backupset bup
WHERE bup.backup_set_id IN
  (SELECT MAX(backup_set_id) FROM msdb.dbo.backupset
  WHERE database_name = ISNULL(@dbname, database_name) --if no dbname, then return all
  AND type = 'D' --only interested in the time of last full backup
  GROUP BY database_name) 
/* COMMENT THE NEXT LINE IF YOU WANT ALL BACKUP HISTORY */
AND bup.database_name IN (SELECT name FROM master.dbo.sysdatabases)
ORDER BY bup.database_name


--Missing Backups
SELECT SD.name,MAX(backup_finish_date) AS LATEST_BKP,MB.type
FROM SYS.databases SD
LEFT OUTER JOIN MSDB..backupset MB
ON SD.name=MB.database_name
WHERE
sd.name<>'tempdb' and
--MB.type='D' OR MB.type IS NULL
--MB.TYPE= 'L' OR MB.type IS NULL
backup_finish_date IS NULL
GROUP BY SD.name,MB.type


--Backup HISTORY
select top 100  physical_device_name,database_name,backup_finish_date,user_name,is_snapshot
from msdb..backupset bs
join msdb..backupmediafamily bmf on bs.media_set_id=bmf.media_set_id
where --database_name= 'bcp' and 
bs.type ='D'
order by backup_finish_date desc

--Backup directory with network accessibility
select  top 1 a.server_name, a.database_name, backup_finish_date, a.backup_size,
CASE a.[type] -- Let's decode the three main types of backup here
 WHEN 'D' THEN 'Full'
 WHEN 'I' THEN 'Differential'
 WHEN 'L' THEN 'Transaction Log'
 ELSE a.[type]
END as BackupType
-- Browse to the file
,'\\' + 
-- lets extract the server name out of the recorded server and instance name
CASE
 WHEN patindex('%\%',a.server_name) = 0  THEN a.server_name
 ELSE substring(a.server_name,1,patindex('%\%',a.server_name)-1)
END 
-- then get the drive information
+ '\' + left(replace(b.physical_device_name,':','$'),2) AS '\\Server\Drive'
from msdb.dbo.backupset a join msdb.dbo.backupmediafamily b
  on a.media_set_id = b.media_set_id
where a.database_name Like 'master%'
order by a.backup_finish_date desc

--Backup duration and size
SELECT TOP 100
s.database_name,
m.physical_device_name,
CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize,
CAST(DATEDIFF(second, s.backup_start_date,
s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken,
s.backup_start_date,
CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn,
CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn,
CASE s.[type] WHEN 'D' THEN 'Full'
WHEN 'I' THEN 'Differential'
WHEN 'L' THEN 'Transaction Log'
END AS BackupType,
s.server_name,
s.recovery_model
FROM msdb.dbo.backupset s
INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
--WHERE s.database_name = DB_NAME() -- Remove this line for all the database
ORDER BY backup_start_date DESC, backup_finish_date
GO
