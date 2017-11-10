--SELECT count(*) FROM ::fn_dblog(NULL, NULL) WHERE Description='REPLICATE'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('dbo.sp_vlfpro'))
   exec('CREATE PROCEDURE [dbo].[sp_vlfpro] AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE sp_vlfpro
as
begin

CREATE TABLE ##VLFInfo (RecoveryUnitID int, FileID  int,
					   FileSize bigint, StartOffset bigint,
					   FSeqNo      bigint, [Status]    bigint,
					   Parity      bigint, CreateLSN   numeric(38));

CREATE TABLE ##VLFCountResults(DatabaseName sysname, VLFCount int); 

CREATE TABLE ##SQLPerf (
    [Database Name] varchar(100),
    [Log Size (MB)] decimal (10,2),
    [Log Space Used (%)] decimal (10,2),
    [Status] varchar(1)
    )

EXEC sp_MSforeachdb N'Use [?]; 

				INSERT INTO ##VLFInfo 
				EXEC sp_executesql N''DBCC LOGINFO([?])''; 
	 
				INSERT INTO ##VLFCountResults 
				SELECT DB_NAME(), COUNT(*) 
				FROM ##VLFInfo; 

				TRUNCATE TABLE ##VLFInfo;'

INSERT ##SQLPerf EXEC ('DBCC SQLPERF (LOGSPACE)');
	 
SELECT vlf.DatabaseName, VLFCount ,sp.[Log Size (MB)],sp.[Log Space Used (%)],sd.log_reuse_wait_desc ,'use '+sd.name+'; DBCC SHRINKFILE('''+smf.name+''' ,0,TRUNCATEONLY);' as ShrinkCMD,
'use '+sd.name+'; ALTER DATABASE ['+sd.name+'] MODIFY FILE ( NAME = N'''+smf.name+''', SIZE = '+ cast(cast(ROUND(sp.[Log Size (MB)]/100*75,0) as int) as varchar(8)) +'MB )' as ResizeCMD
FROM ##VLFCountResults vlf join ##SQLPerf sp
on vlf.DatabaseName=sp.[Database Name]
join sys.databases sd
 on sp.[Database Name]=sd.name join sys.master_files smf
 on sd.database_id=smf.database_id
 where smf.type_desc='LOG'
ORDER BY VLFCount DESC;
	 
DROP TABLE ##VLFInfo;
DROP TABLE ##VLFCountResults;
DROP TABLE ##SQLPerf;
end --proc end