USE [SQLOps]
GO

/****** Object:  StoredProcedure [dbo].[usp_collect_WaitStats]    Script Date: 18/03/2019 09:55:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_collect_WaitStats]
AS
BEGIN


	SET NOCOUNT ON;

	IF OBJECT_ID ('dbo.tbltmp_wait_stats', 'table') IS NULL
	BEGIN
        CREATE TABLE [dbo].[tbltmp_wait_stats] (
            [ServerName] NVARCHAR(128) NOT NULL,
            [currentime] DATETIME NOT NULL,
            [wait_type] NVARCHAR(60) NOT NULL,
            [waiting_tasks_count] BIGINT NOT NULL,
            [wait_time_ms] BIGINT NOT NULL,
            [max_wait_time_ms] BIGINT NOT NULL,
            [signal_wait_time_ms] BIGINT NOT NULL,
            CONSTRAINT [PK_tbltmp_wait_stats] PRIMARY KEY NONCLUSTERED (
                [currentime]	ASC,		
                [wait_type]		ASC,
                [ServerName]	ASC
            ) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
        ) ON [PRIMARY]
    END;

	INSERT INTO [SQLOPs].[dbo].[tbltmp_wait_stats]
	SELECT @@SERVERNAME AS ServerName, GETDATE()AS date, *
		FROM sys.dm_os_wait_stats
		WHERE wait_time_ms > 0;

	DELETE FROM [SQLOPs].[dbo].[tbltmp_wait_stats]
		WHERE currentime < DATEADD(hh, -24, GETDATE());

END
