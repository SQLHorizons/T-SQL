USE [msdb]
GO

/****** Object:  Job [SQLOPs - Record waitstats]    Script Date: 13/07/2017 10:21:55 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 13/07/2017 10:21:55 ******/

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SQLOPs - Record waitstats', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Collects waitstats to tempdb
Written by Paul Maxfield. Any Questions please ask', 
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect waitstats]    Script Date: 13/07/2017 10:21:55 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect waitstats', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [SQLOPs]
		  GO
		  IF OBJECT_ID (''dbo.tbltmp_wait_stats'', ''table'') IS NULL
			BEGIN
			  CREATE TABLE [dbo].[tbltmp_wait_stats](
				[ServerName]			NVARCHAR(128)	NOT NULL,
				[currentime]				DATETIME		NOT NULL,
				[wait_type]				NVARCHAR(60)	NOT NULL,
				[waiting_tasks_count]	BIGINT			NOT NULL,
				[wait_time_ms]			BIGINT			NOT NULL,
				[max_wait_time_ms]		BIGINT			NOT NULL,
				[signal_wait_time_ms]	BIGINT			NOT NULL,
				 CONSTRAINT [PK_tbltmp_wait_stats] PRIMARY KEY NONCLUSTERED 
				(
					[currentime]	ASC,		
					[wait_type]		ASC,
					[ServerName]	ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
			  ) ON [PRIMARY]
			END;
		  GO
		  INSERT INTO [SQLOPs].[dbo].[tbltmp_wait_stats]
			SELECT @@SERVERNAME AS ServerName, GETDATE()AS date, * FROM sys.dm_os_wait_stats
			  WHERE wait_time_ms > 0;
		  GO
		  DELETE FROM [SQLOPs].[dbo].[tbltmp_wait_stats]
			WHERE currentime < DATEADD(hh, -24, GETDATE());', 
		@database_name=N'SQLOPs', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 5 Minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140409, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
