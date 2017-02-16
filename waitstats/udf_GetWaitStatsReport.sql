USE [SQLOps]
GO
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[udf_GetWaitStatsReport] (	@Window SMALLINT = 60, @Rows   SMALLINT = 10 )
RETURNS TABLE 
AS
	RETURN (
		WITH Server_waits
			AS (
				SELECT
					[ServerName]
				  , [currentime]
				  , [TheDate]   = CONVERT(VARCHAR(10), [currentime], 120)
				  , [TheTime]   = CONVERT(VARCHAR(8), [currentime], 108)
				  , [RANK]      = DENSE_RANK() OVER(ORDER BY [currentime])
				  , [wait_type]
				  , [Requests]  = [waiting_tasks_count]
				  , [wait_time_ms]
				  , [max_wait_time_ms]
				  , [signal_wait_time_ms]
				FROM [SQLOPs].[dbo].[tbl_wait_stats]
				WHERE [wait_type] NOT IN
					(
						N'TRACEWRITE',
						N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
						N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
						N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
						N'CHKPT', N'CLR_AUTO_EVENT',
						N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
						N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
						N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
						N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
						N'EXECSYNC', N'FSAGENT',
						N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
						N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
						N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
						N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
						N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
						N'LOGMGR_QUEUE', N'ONDEMAND_TASK_QUEUE',
						N'PWAIT_ALL_COMPONENTS_INITIALIZED',
						N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
						N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
						N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
						N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
						N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
						N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
						N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
						N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
						N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
						N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
						N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
						N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
						N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
						N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
						N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
						N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT'
					)
					AND [currentime] BETWEEN (DATEADD(mi,-@Window,GETDATE())) AND GETDATE()
			),
			data AS (
				SELECT sw2.[ServerName]
				  , sw2.[TheDate]
				  , sw2.[TheTime]
				  , [ROW]                                = ROW_NUMBER() OVER(PARTITION BY sw2.[RANK] ORDER BY sw2.[TheTime] DESC, sw2.[wait_time_ms] - sw1.[wait_time_ms] DESC)
				  , [Wait Type]                          = sw2.[wait_type]
				  , [Total Requests since reboot]        = sw2.[Requests]
				  , [Requests]                           = sw2.[Requests] - sw1.[Requests] 
				  , [Wait Time (ms)]                     = sw2.[wait_time_ms] - sw1.[wait_time_ms]
--				  , [Avg Wait Time/Request (μs)]         = CONVERT(DECIMAL(10,0), (sw2.[wait_time_ms] - sw1.[wait_time_ms])/(0.001*(sw2.[Requests] - sw1.[Requests])))
				  , [Wait Time (ms)/sec]                 = CONVERT(DECIMAL(10,3), (sw2.[wait_time_ms] - sw1.[wait_time_ms])/(DATEDIFF(SECOND, sw1.[currentime], sw2.[currentime])*1000.0))
				  , [Signal Wait Time (ms)]              = sw2.[signal_wait_time_ms] - sw1.[signal_wait_time_ms]
--				  , [Avg Signal Wait Time/Request (μs)]  = CONVERT(DECIMAL(10,0), (sw2.[signal_wait_time_ms] - sw1.[signal_wait_time_ms])/(0.001*(sw2.[Requests] - sw1.[Requests])))
				  , [Signal Wait Time (ms)/sec]          = CONVERT(DECIMAL(10,3), (sw2.[signal_wait_time_ms] - sw1.[signal_wait_time_ms])/(DATEDIFF(second, sw1.[currentime], sw2.[currentime])*1000.0))
				FROM [Server_waits] sw1 INNER JOIN [Server_waits] sw2
					ON  sw1.[wait_type] = sw2.[wait_type]
					AND sw1.[RANK]      = sw2.[RANK] - 1
				WHERE sw2.[wait_time_ms] - sw1.[wait_time_ms] > 0
			)
		SELECT TOP(100)PERCENT 
					ServerName
				  , TheDate
				  , TheTime
				  , [Wait Type]
				  , [Total Requests since reboot]
				  , [Requests Over Sample] = Requests
				  , [Wait Time (ms)]
--				  , [Avg Wait Time/Request (μs)]
				  , [Wait Time (ms)/sec]
				  , [Signal Wait Time (ms)]
--				  , [Avg Signal Wait Time/Request (μs)]
				  , [Signal Wait Time (ms)/sec]
		FROM data
		WHERE ROW <= @Rows
		ORDER BY [TheTime] DESC, [Wait Time (ms)] DESC

	)
GO

SELECT * FROM [SQLOps].[dbo].[udf_GetWaitStatsReport] ( DEFAULT, DEFAULT )
