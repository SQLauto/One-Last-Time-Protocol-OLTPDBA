--Author: Kannan G
--Use case: Need to restore all log backups for a DB since last Full backup? this script helps to generate script for the same
--Change data/Log file name same as destination DB
--Example: USP_RestoreSGEN @DBName= 'TestDB',@DestinationDB='TestDB_restore'
USE master 
go
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'USP_RestoreSGEN') 
EXEC ('CREATE PROC dbo.USP_RestoreSGEN AS SELECT ''stub version, to be replaced''') 
GO 
         
ALTER PROC USP_RestoreSGEN
@DBName nvarchar(25),
@LastFull int=1,
@DestinationDB nvarchar(25)=@DBName,
--@AlternateBackupPath varchar(1000)=NULL,
@MoveTO varchar(1000) = NULL
AS 
BEGIN
SET NOCOUNT ON;
DECLARE @@FLIMIT INT
DECLARE @@LBKP DATETIME
DECLARE @@NBKP DATETIME
DECLARE @@ORGINALFULLPATH VARCHAR(1000)
DECLARE @@PRINTMOVECMDS VARCHAR(1000)
DECLARE @@PRINTLOGRESTORECMDS VARCHAR(1000)
DECLARE @@BKPDETCOUNT INT

		--Step 1 --GET backup details
		CREATE TABLE #BKPDET
		(
		BKP_FINISH_DATE DATETIME,
		Original_full_path varchar(1000),
		file_name varchar(1000),
		RNO INT IDENTITY(1,1)
		)
		insert into #BKPDET
		SELECT top 30 BS.backup_finish_date,physical_device_name, RIGHT(physical_device_name, CHARINDEX('\', REVERSE(physical_device_name)) -1)  [file_name]
		FROM msdb..backupset BS
		JOIN MSDB..backupmediafamily BMF ON BS.media_set_id=BMF.media_set_id
		WHERE type='D'
		AND database_name=@DBName
		ORDER BY backup_finish_date DESC
		SELECT @@LBKP=BKP_FINISH_DATE,@@ORGINALFULLPATH=Original_full_path FROM #BKPDET WHERE RNO=@LastFull
		SELECT @@BKPDETCOUNT=COUNT(*) FROM #BKPDET
		
		--DIAG
		--PRINT @@LBKP
		--PRINT @@ORGINALFULLPATH
		--SELECT * FROM #BKPDET
IF @@LBKP IS NULL
PRINT @DBName+' has only '+CAST(@@BKPDETCOUNT AS VARCHAR(10))+' FULL backup(s) available. Could not use the value: '+CAST(@LastFull AS VARCHAR(10))
ELSE
BEGIN
		--Step 2 filter results
		IF @LastFull=1 
		BEGIN
			SET @@FLIMIT=NULL
			SELECT @@NBKP= CONVERT(datetime, GETDATE(), 112) 
		END
		ELSE
		BEGIN
			SET @@FLIMIT= @LastFull-1;
			SELECT @@NBKP=BKP_FINISH_DATE FROM #BKPDET WHERE RNO=@@FLIMIT
		END
		--Step 3 CONDITION for MOVETO Param
		IF @MoveTO IS NULL
		BEGIN
			--FULL BACKUP restore script
			PRINT '--Script to restore full backup taken at : '+CAST(@@LBKP AS VARCHAR(25))+CHAR(10)
			PRINT 'RESTORE DATABASE ['+@DestinationDB+'] FROM DISK=''' +@@ORGINALFULLPATH+''' WITH NORECOVERY,STATS=5'+CHAR(10) 

			--Log BACKUP restore script
			PRINT '--Logs restore since Full backup at: '+CAST(@@LBKP AS VARCHAR(25))+CHAR(10);
			--Cursor Declare
			DECLARE LOGRESTORECMDS CURSOR FOR
			SELECT 'RESTORE LOG ['+@DestinationDB+'] FROM DISK='''+physical_device_name+''' WITH NORECOVERY,STATS=5'+' --'+CAST(backup_finish_date AS VARCHAR(60))
			FROM msdb..backupset BS
			JOIN MSDB..backupmediafamily BMF
			ON BS.media_set_id=BMF.media_set_id
			WHERE type='L'
			AND database_name=@DBName
			AND (backup_finish_date BETWEEN @@LBKP AND @@NBKP)
			---------------------------------------------------------
			OPEN LOGRESTORECMDS
			FETCH NEXT FROM LOGRESTORECMDS INTO @@PRINTLOGRESTORECMDS
			WHILE @@FETCH_STATUS = 0   
			BEGIN   
			PRINT @@PRINTLOGRESTORECMDS
			FETCH NEXT FROM LOGRESTORECMDS INTO @@PRINTLOGRESTORECMDS   
			END   
			--Cursor Closure
			CLOSE LOGRESTORECMDS   
			DEALLOCATE LOGRESTORECMDS

			PRINT CHAR(10)+'--RESTORE DATABASE '+@DestinationDB+' WITH RECOVERY'
			
		END

		ELSE--FOR @MOVETO PARAM
		BEGIN--FOR VALIDATING @MOVETO PARAM
		IF CHARINDEX('\',REVERSE(@MoveTO),1)<>1
		PRINT 'Add Symbol "\" to the end of @MOVETO parameter value and rerun the SP'
		ELSE
		BEGIN
			--FULL BACKUP restore script
			PRINT '--Script to restore database with move option for full backup taken at : '+CAST(@@LBKP AS VARCHAR(25))+CHAR(10)
			PRINT 'RESTORE DATABASE ['+@DestinationDB+'] FROM DISK=''' +@@ORGINALFULLPATH+''' WITH'
			--Cursor Declare
			DECLARE movetocommands CURSOR FOR  
			SELECT 'MOVE '''+name+''' TO '''+@MoveTO+RIGHT(physical_name, CHARINDEX('\', REVERSE(physical_name)) -1) +''',' as MOVECMDS
			FROM SYS.master_files 
			where db_name(database_id)=@DBName
			--Open Cursor
			OPEN movetocommands
			FETCH NEXT FROM movetocommands INTO @@PRINTMOVECMDS
			WHILE @@FETCH_STATUS = 0   
			BEGIN   
			PRINT @@PRINTMOVECMDS
			FETCH NEXT FROM movetocommands INTO @@PRINTMOVECMDS   
			END   
			--Cursor Closure
			CLOSE movetocommands   
			DEALLOCATE movetocommands
			PRINT 'NORECOVERY,STATS=5'
			--Log BACKUP restore script
			PRINT CHAR(10)+'--Logs restore since Full backup at: '+CAST(@@LBKP AS VARCHAR(25))+CHAR(10);
			--Cursor Declare
			DECLARE LOGRESTORECMDS CURSOR FOR
			SELECT 'RESTORE LOG ['+@DestinationDB+'] FROM DISK='''+physical_device_name+''' WITH NORECOVERY,STATS=5'+' --'+CAST(backup_finish_date AS VARCHAR(60))
			FROM msdb..backupset BS
			JOIN MSDB..backupmediafamily BMF
			ON BS.media_set_id=BMF.media_set_id
			WHERE type='L'
			AND database_name=@DBName
			AND (backup_finish_date BETWEEN @@LBKP AND @@NBKP)
			---------------------------------------------------------
			OPEN LOGRESTORECMDS
			FETCH NEXT FROM LOGRESTORECMDS INTO @@PRINTLOGRESTORECMDS
			WHILE @@FETCH_STATUS = 0   
			BEGIN   
			PRINT @@PRINTLOGRESTORECMDS
			FETCH NEXT FROM LOGRESTORECMDS INTO @@PRINTLOGRESTORECMDS   
			END   
			--Cursor Closure
			CLOSE LOGRESTORECMDS   
			DEALLOCATE LOGRESTORECMDS

			PRINT CHAR(10)+'--RESTORE DATABASE '+@DestinationDB+' WITH RECOVERY'
			END
		END

		DROP TABLE #BKPDET
		SET NOCOUNT OFF;
END --ENDIF @@LBKP IS NULL
---FINAL END
END
GO