--Author: Kannan G
--Usage: Moving a DB file to another folder? This script helps to generate the TSQL scripts for the same
--Example: --EXEC master..USP_DBMoveSGEN @DBname='dbmonitor',@files2move='both',@NewdataPath='E:\data\',@NewlogPath='E:\log\',@Setonline=1,@verbose=1

USE master
go
IF OBJECT_ID('dbo.USP_DBMoveSGEN', 'P') IS NULL
	BEGIN
	EXECUTE('CREATE PROCEDURE dbo.USP_DBMoveSGEN AS PRINT ''dbo.USP_SGEN_DBMOVE''');
	END
GO
--PROC Definition
ALTER PROC USP_DBMoveSGEN
@DBName NVARCHAR(100) = NULL,
@NewDataPath NVARCHAR(1000) = NULL,
@NewLogPath NVARCHAR(1000) = NULL,
@Files2Move NVARCHAR(100) = 'Both',
@Verbose int = 0,
@SetOnline int = 0
AS
BEGIN
/*17-JUN-2017- 
1. Added filter for specific files
2. Verbose parameter to print info messages
*/
IF (charindex('\',reverse(@NewDataPath)))<>1 
PRINT 'Please add character "\" to the end of @newdatapath parameter and rerun the SP'+Char(10);

ELSE IF  (charindex('\',reverse(@NewLogPath)))<>1
PRINT 'Please add character "\" to the end of @newlogpath parameter and rerun the SP'+Char(10);

ELSE
BEGIN
	--Step1- Take Offline
	DECLARE @@DBOFFLINE NVARCHAR(1000);
	SET @@DBOFFLINE= 'ALTER DATABASE ['+@DBNAME+'] SET OFFLINE WITH ROLLBACK IMMEDIATE;'
	IF @Verbose=1
	PRINT '--**Database offline'
	PRINT @@DBOFFLINE+CHAR(10)

--Filter 1: 
IF(@Files2Move ='Both' or @Files2Move='Data')
BEGIN
	--Step2 Modify file path logically
	DECLARE @@OldDataPath NVARCHAR(1000);
	DECLARE @@Datafilename NVARCHAR(1000);
	DECLARE @@NewDataPathCMD NVARCHAR(1000);
	DECLARE @@PhysicalDatafileCopy NVARCHAR(1000);
	--V2
	DECLARE @@NAME VARCHAR(50)
	DECLARE CSR_SMF CURSOR FOR
	SELECT name from sys.master_files where db_name(database_id)=@DBNAME and type_desc='ROWS'
	OPEN CSR_SMF
	FETCH NEXT FROM CSR_SMF INTO @@NAME
	WHILE @@FETCH_STATUS = 0   
	BEGIN 
		--Print old path
		SELECT @@OldDataPath = LEFT(physical_name,LEN(physical_name) - charindex('\',reverse(physical_name),1)		+ 1) ,@@Datafilename =RIGHT(physical_name, CHARINDEX('\', REVERSE(physical_name)) -1) from					sys.master_files
		Where db_name(database_id)=@dbName and name=@@name

	--Print New path modify command
		SELECT @@NewDataPathCMD= 'ALTER DATABASE ['+@DBName+'] MODIFY FILE(name='''+name							+''',FILENAME='''+@NewDataPath+@@Datafilename+''');'
		from sys.master_files
		Where db_name(database_id)=@dbName and name=@@name

		IF @Verbose=1
			BEGIN
			PRINT '--**Old data file path: ' + @@OldDataPath+CHAR(10)
			PRINT '--**Modify Data file path'
			END --Verbose Condition
		PRINT @@NewDataPathCMD+CHAR(10)
	
	FETCH NEXT FROM CSR_SMF INTO @@NAME   
	END   
	--Cursor Closure
	CLOSE CSR_SMF   
	DEALLOCATE CSR_SMF

--Move files at OS
	select @@PhysicalDatafileCopy= 'XCOPY '''+ physical_name +''' '''+@NewDataPath+''' /Y /I /F' from master.sys.master_files where		db_name(database_id) =@DBName and type_desc='ROWS'

	IF @Verbose=1 
		BEGIN -- Verbose
		PRINT '--**Phsically copy data file to new path'
		PRINT @@PhysicalDatafileCopy+CHAR(10)
		END -- Verbose End
END --Filter End

--Filter 1: 
IF(@Files2Move ='Both' or @Files2Move='Log')
BEGIN
	--Log file
	DECLARE @@OldlogPath NVARCHAR(1000);
	DECLARE @@logfilename NVARCHAR(1000);
	DECLARE @@NewlogPathCMD NVARCHAR(1000);
	DECLARE @@PhysicallogfileCopy NVARCHAR(1000);

	SELECT @@OldlogPath = LEFT(physical_name,LEN(physical_name) - charindex('\',reverse(physical_name),1) + 1) ,
	@@logfilename =RIGHT(physical_name, CHARINDEX('\', REVERSE(physical_name)) -1) from sys.master_files
	Where db_name(database_id)=@dbName and type_desc='LOG'

	SELECT @@NewlogPathCMD= 'ALTER DATABASE ['+@DBName+'] MODIFY FILE(name='''+name+''',FILENAME='''+@NewLogPath+@@logfilename		+''');'
	from sys.master_files
	Where db_name(database_id)=@dbName and type_desc='LOG'
		
		IF @Verbose=1
			BEGIN
				PRINT '--**Old log file path: ' + @@OldlogPath+CHAR(10)
				PRINT '--**Modify log file path'
			END --Filter end
	PRINT @@NewlogPathCMD+CHAR(10)

	select @@PhysicallogfileCopy= 'XCOPY '''+ physical_name +''' '''+@NewLogPath+''' /Y /I /F' from master.sys.master_files			where db_name(database_id) =@DBName and type_desc='LOG'

	IF @Verbose=1 
		BEGIN
		PRINT '--**Phsically copy log file to new path'
		PRINT @@PhysicallogfileCopy+CHAR(10)
		END --Verbose end

END --Filter End


	--Step 4 Turn ONLINE
	DECLARE @@DBOnline NVARCHAR(1000);
	SET @@DBOnline= 'ALTER DATABASE ['+@DBNAME+'] SET ONLINE;'
	IF @Verbose=1  PRINT '--**Database Online'
	IF @SetOnline=1 PRINT @@DBOnline+CHAR(10)		
	PRINT '-------------------------------------------------------------------------------'
	END
END
