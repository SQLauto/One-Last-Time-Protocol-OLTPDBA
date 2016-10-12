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

--Error log path
xp_readerrorlog 0, 1, N'Logging SQL Server messages in file'

--SQL Port in use
select  distinct(local_tcp_port) from sys.dm_exec_connections


--Current running queries sorted by CPU usage
SELECT 
	r.session_id
	,st.TEXT AS batch_text
	,SUBSTRING(st.TEXT, statement_start_offset / 2 + 1, (
			(
				CASE 
					WHEN r.statement_end_offset = - 1
						THEN (LEN(CONVERT(NVARCHAR(max), st.TEXT)) * 2)
					ELSE r.statement_end_offset
					END
				) - r.statement_start_offset
			) / 2 + 1) AS statement_text
	,qp.query_plan AS 'XML Plan'
	,r.*
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) AS qp
ORDER BY cpu_time DESC

--TOP CPU consumed query history
select top 50 
    sum(qs.total_worker_time) as total_cpu_time, 
    sum(qs.execution_count) as total_execution_count,
    count(*) as  number_of_statements, 
    qs.plan_handle,
	 est.text
from 
    sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text(qs.sql_handle) est
group by qs.plan_handle,est.text
order by sum(qs.total_worker_time) desc


--Whats in buffer
select type,name,sum(pages_kb/1024.0) as PagesMB
from sys.dm_os_memory_clerks
GROUP BY [type], [name]  
ORDER BY SUM(pages_kb/1024.0) DESC

--Memory state
SELECT total_physical_memory_kb, available_physical_memory_kb, 
       total_page_file_kb, available_page_file_kb, 
       system_memory_state_desc
FROM sys.dm_os_sys_memory;

-- SQL Server Process Address space info (SQL 2008 and 2008 R2)
--(shows whether locked pages is enabled, among other things)
SELECT physical_memory_in_use_kb,locked_page_allocations_kb, 
       page_fault_count, memory_utilization_percentage, 
       available_commit_limit_kb, process_physical_memory_low, 
       process_virtual_memory_low
FROM sys.dm_os_process_memory;

-- You want to see 0 for process_physical_memory_low
-- You want to see 0 for process_virtual_memory_low

-- Page Life Expectancy (PLE)
SELECT cntr_value AS [Page Life Expectancy],counter_name,object_name
FROM sys.dm_os_performance_counters
WHERE
 counter_name = N'Page life expectancy';

-- PLE is a good measurement of memory pressure.
-- Higher PLE is better. Below 300 is generally bad.
-- Watch the trend, not the absolute value.

