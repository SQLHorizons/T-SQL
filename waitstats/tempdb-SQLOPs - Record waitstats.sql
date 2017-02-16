USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

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
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'dbAdmin', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect waitstats]    Script Date: 06/16/2017 14:53:18 ******/
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
		@command=N'USE [tempdb]
		  GO
		  IF OBJECT_ID (''dbo.tbl_wait_stats'', ''table'') IS NULL
			BEGIN
			  CREATE TABLE [tempdb].[dbo].[tbl_wait_stats](
				[ServerName]			NVARCHAR(128)	NOT NULL,
				[currentime]				DATETIME		NOT NULL,
				[wait_type]				NVARCHAR(60)	NOT NULL,
				[waiting_tasks_count]	BIGINT			NOT NULL,
				[wait_time_ms]			BIGINT			NOT NULL,
				[max_wait_time_ms]		BIGINT			NOT NULL,
				[signal_wait_time_ms]	BIGINT			NOT NULL,
				 CONSTRAINT [PK_tbl_wait_stats] PRIMARY KEY NONCLUSTERED 
				(
					[currentime]	ASC,		
					[wait_type]		ASC,
					[ServerName]	ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
			  ) ON [PRIMARY]
			END;
		  GO
		  INSERT INTO [tempdb].[dbo].[tbl_wait_stats]
			SELECT @@SERVERNAME AS ServerName, GETDATE()AS date, * FROM sys.dm_os_wait_stats
			  WHERE wait_time_ms > 0;
		  GO
		  DELETE FROM [tempdb].[dbo].[tbl_wait_stats]
			WHERE currentime < DATEADD(hh, -72, GETDATE());', 
		@database_name=N'tempdb', 
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
