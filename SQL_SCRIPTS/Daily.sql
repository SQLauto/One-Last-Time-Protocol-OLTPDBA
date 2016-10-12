--File Property
SELECT DB_NAME() as DBName,name as logical_name,file_id,type_desc,size/128 AS SIZE_MB,size/128 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128 AS AvailableSpaceInMB,physical_name
FROM sys.database_files
order by AvailableSpaceInMB desc

--DB Wise buffer usage
SELECT DB_NAME(database_id) AS [Database Name], 
COUNT(*) * 8/1024.0 AS [Cached Size (MB)] 
FROM sys.dm_os_buffer_descriptors WITH (NOLOCK) 
WHERE database_id > 4 -- system databases 
AND database_id <> 32767 -- ResourceDB 
GROUP BY DB_NAME(database_id) 
ORDER BY [Cached Size (MB)] DESC OPTION (RECOMPILE);

--SQL Buffer Pool
SELECT
   (CASE WHEN ([is_modified] = 1) THEN N'Dirty' ELSE N'Clean' END) AS N'Page State',
   (CASE WHEN ([database_id] = 32767) THEN N'Resource Database' ELSE DB_NAME ([database_id]) END) AS N'Database Name',
   COUNT (*) AS PageCount
FROM sys.dm_os_buffer_descriptors
   GROUP BY [database_id], [is_modified]
   ORDER BY PageCount desc
GO

