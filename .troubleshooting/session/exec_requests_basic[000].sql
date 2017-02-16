SELECT session_id
--	, request_id
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
--	, user_id
--	, connection_id
	, blocking_session_id
	, wait_type
	, wait_time
	, last_wait_type 
	, wait_resource
--	, open_transaction_count
--	, open_resultset_count
--	, transaction_id
--	, context_info
	, cpu_time
	, total_elapsed_time AS [total_elapsed_time(ms)]
	, total_elapsed_time/60000.0 AS [total_elapsed_time(m)]
	, total_elapsed_time/3600000.0 AS [total_elapsed_time(h)]
	, scheduler_id
--	, task_address
	, reads
	, writes
	, logical_reads
	, percent_complete
	, estimated_completion_time
--	, text_size
--	, language
--	, date_format
--	, date_first
--	, quoted_identifier
--	, arithabort
--	, ansi_null_dflt_on
--	, ansi_defaults
--	, ansi_warnings
--	, ansi_padding
--	, ansi_nulls
--	, concat_null_yields_null
--	, transaction_isolation_level
--	, lock_timeout
--	, deadlock_priority
	, row_count
--	, prev_error
--	, nest_level
--	, granted_query_memory
--	, executing_managed_code
	, text AS 'all query text' 
FROM sys.dm_exec_requests
  CROSS APPLY sys.dm_exec_sql_text(sql_handle)
  CROSS APPLY sys.dm_exec_query_plan(plan_handle)
  --WHERE session_id = 114
  WHERE session_id > 50 and session_id != (@@SPID)

--SELECT * FROM sys.dm_os_waiting_tasks WHERE session_id > 50 and session_id != (@@SPID)

--EXEC sp_lock


--SELECT SUBSTRING(text, (statement_start_offset/2) +1,
--  ((CASE statement_end_offset
--	WHEN -1
--	  THEN DATALENGTH(text)
--	ELSE statement_end_offset
--  END - statement_start_offset)/2) + 1) AS query_text, *
--FROM sys.dm_exec_requests
--  CROSS APPLY  sys.dm_exec_sql_text(sql_handle)
--WHERE session_id = 63



--select * from sys.dm_exec_sessions WHERE session_id > 50 and session_id != (@@SPID)

--SELECT * FROM sys.dm_tran_active_transactions
--SELECT *


--select * from sys.dm_exec_sessions where session_id = 81
--select * from sys.dm_exec_sessions where session_id = 91


--SELECT sql_handle
--	--, statement_start_offset
	
--	--, statement_end_offset
--	--, plan_generation_num
--	--, plan_handle
--	, SUBSTRING(text, (statement_start_offset/2) +1,
--		((CASE statement_end_offset
--		  WHEN -1
--			THEN DATALENGTH(text)
--		  ELSE statement_end_offset
--		END - statement_start_offset)/2) + 1) AS query_text
--	, query_plan
--	, creation_time
--	, last_execution_time
--	, execution_count
--	, total_worker_time
--	, last_worker_time
--	, min_worker_time
--	, max_worker_time
----	, total_physical_reads
----	, last_physical_reads
----	, min_physical_reads
----	, max_physical_reads
--	, total_logical_writes
--	, last_logical_writes
--	, min_logical_writes
--	, max_logical_writes
--	, total_logical_reads
--	, last_logical_reads
--	, min_logical_reads
--	, max_logical_reads
----	, total_clr_time
----	, last_clr_time
----	, min_clr_time
----	, max_clr_time
--	, total_elapsed_time
--	, last_elapsed_time
--	, min_elapsed_time
--	, max_elapsed_time
--from sys.dm_exec_query_stats
--  CROSS APPLY sys.dm_exec_sql_text(sql_handle)
--  CROSS APPLY sys.dm_exec_query_plan(plan_handle) 
--kill 84  

--execute master..sqbmemory

--select * from sys.dm_exec_sessions

--exec sp_who2 40

--select  distinct request_owner_guid from sys.dm_tran_locks where request_session_id = -2
--select  request_owner_guid from sys.dm_tran_locks where request_session_id = -2