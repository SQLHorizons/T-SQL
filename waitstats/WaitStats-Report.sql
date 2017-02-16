DECLARE @bTime			DATETIME
DECLARE @cTime			DATETIME
DECLARE @eTime			DATETIME
DECLARE @Rows			INT

--SELECT @bTime = DATEADD(mi,-60,GETDATE()), @cTime = '', @eTime = DATEADD(mi,-30,GETDATE());
--SELECT @bTime = '2015-04-24 08:30:00.000', @cTime = '', @eTime = '2015-04-24 11:30:00.000';
SELECT @bTime = DATEADD(mi,-60,GETDATE()), @cTime = '', @eTime = GETDATE(), @Rows = 20;

WITH
    Server_waits
    AS
    (
        SELECT [ServerName]
		  , RIGHT([ServerName], 4) AS [MachineID]
		  , [currentime]
		  , CONVERT(VARCHAR(10), [currentime], 120) AS [TheDate]
		  , CONVERT(VARCHAR(8), [currentime], 108) AS [TheTime]
		  , DENSE_RANK() OVER(ORDER BY [currentime]) AS [RANK]
		  , [wait_type]
		  , [waiting_tasks_count] AS [Requests]
		  , [wait_time_ms]
		  , [max_wait_time_ms]
		  , [signal_wait_time_ms]
        FROM [SQLOPs].[dbo].[tbl_wait_stats]
        WHERE [wait_type] NOT IN
            (
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
            AND [currentime] BETWEEN @bTime AND @eTime
    ),
    y
    As
    (
        SELECT sw2.[ServerName]
--		  ,sw2.[MachineID]
		  , sw2.[TheDate]
--		  ,DATEDIFF(second, sw1.[currentime], sw2.[currentime])
		  , sw2.[TheTime]
--		  ,sw2.[RANK] AS [Sample]
		  , ROW_NUMBER() OVER(PARTITION BY sw2.[RANK] ORDER BY sw2.[TheTime] DESC, sw2.[wait_time_ms] - sw1.[wait_time_ms] DESC) AS [ROW]
		  , sw2.[wait_type] AS [Wait Type]
		  , sw2.[Requests] AS [Total Requests since reboot]
		  , sw2.[Requests] - sw1.[Requests] AS [Requests]
		  , sw2.[wait_time_ms] - sw1.[wait_time_ms] AS [Wait Time (ms)]
		  , CONVERT(DECIMAL(10,3), (sw2.[wait_time_ms] - sw1.[wait_time_ms])/(DATEDIFF(second, sw1.[currentime], sw2.[currentime])*1000.0)) AS [Wait Time (ms)/sec]
--		  ,sw2.[max_wait_time_ms] - sw1.[max_wait_time_ms] AS [max_wait_time_ms]
		  , sw2.[signal_wait_time_ms] - sw1.[signal_wait_time_ms] AS [Signal Wait Time (ms)]
		  , CONVERT(DECIMAL(10,3), (sw2.[signal_wait_time_ms] - sw1.[signal_wait_time_ms])/(DATEDIFF(second, sw1.[currentime], sw2.[currentime])*1000.0)) AS [Signal Wait Time (ms)/sec]
        FROM [Server_waits] sw1 INNER JOIN [Server_waits] sw2
            ON sw1.[wait_type] = sw2.[wait_type]
                AND sw1.[RANK]  = sw2.[RANK] - 1
        WHERE sw2.[wait_time_ms] - sw1.[wait_time_ms] > 0
        --AND DATEDIFF(mi, sw2.[currentime], @eTime) <= 5 
    )
SELECT ServerName
		  , TheDate
		  , TheTime
		  , [Wait Type]
		  , [Total Requests since reboot]
		  , Requests
		  , [Wait Time (ms)]
		  , [Wait Time (ms)/sec]
		  , [Signal Wait Time (ms)]
		  , [Signal Wait Time (ms)/sec]
FROM y
WHERE ROW <= @Rows
--AND [Wait Time (ms)] > 500
ORDER BY [TheTime] DESC, [Wait Time (ms)] DESC
				     
