SELECT session_id
	, start_time
	, status
	, command
	, SUBSTRING(text, (statement_start_offset/2) +1,
		((CASE statement_end_offset
		  WHEN -1
			THEN DATALENGTH(text)
		  ELSE statement_end_offset
		END - statement_start_offset)/2) + 1) AS query_text
	, query_plan
	, plan_handle
	, DB_NAME(database_id) AS dbname
	, blocking_session_id
	, wait_type
	, wait_time
	, last_wait_type 
	, wait_resource
	, cpu_time
	, total_elapsed_time AS [total_elapsed_time(ms)]
	, total_elapsed_time/60000.0 AS [total_elapsed_time(m)]
	, total_elapsed_time/3600000.0 AS [total_elapsed_time(h)]
	, scheduler_id
	, reads
	, writes
	, logical_reads
	, percent_complete
	, estimated_completion_time
	, row_count
	, text AS 'all query text' 
FROM sys.dm_exec_requests
  CROSS APPLY sys.dm_exec_sql_text(sql_handle)
  CROSS APPLY sys.dm_exec_query_plan(plan_handle)
  --WHERE session_id = 114
  WHERE session_id > 50 and session_id != (@@SPID)
