SELECT session_id
--	, request_id
	, start_time
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
	, status
	, command
	, plan_handle
	, DB_NAME(database_id) AS dbname
--	, user_id
--	, connection_id
	, blocking_session_id
	, wait_type
	, wait_time
	, last_wait_type 
	, wait_resource
	, row_count
--	, prev_error
--	, nest_level
--	, granted_query_memory
--	, executing_managed_code
FROM sys.dm_exec_requests
WHERE session_id > 50

--SELECT * FROM sys.dm_os_waiting_tasks WHERE session_id > 50 and session_id != (@@SPID)