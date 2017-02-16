SET NOCOUNT ON
DECLARE @ExtentAllocationsByFileGroup TABLE(Fileid INT NOT NULL
, [FileGroup] INT NOT NULL
, TotalExtents BIGINT NOT NULL
, UsedExtents BIGINT
, [Name] VARCHAR(256)
, [FileName] VARCHAR(256));

INSERT INTO @ExtentAllocationsByFileGroup EXEC('DBCC SHOWFILESTATS WITH NO_INFOMSGS')
INSERT INTO @ExtentAllocationsByFileGroup (Fileid, [FileGroup], TotalExtents, UsedExtents)
SELECT 2, 0, 0, cntr_value/64 FROM sys.dm_os_performance_counters
WHERE counter_name = 'Log File(s) Used Size (KB)'
AND instance_name = DB_NAME()

SELECT t1.name, t2.UsedExtents/16 AS 'Used Space(MB)'
, t1.[size]/128 AS 'Size(MB)'
, t1.[max_size]/128 AS 'Max Size(MB)'
, t1.growth/128 AS 'Growth(MB)'
, CASE 
WHEN t1.[size] + t1.growth > t1.[max_size]
THEN CAST(((1 - t2.UsedExtents/(t1.[size]/8.0))*100) AS INT)
ELSE CAST(((1 - t2.UsedExtents/(t1.[max_size]/8.0))*100) AS INT)
END AS '% Free Space'
, t1.physical_name
FROM sys.master_files t1 INNER JOIN
@ExtentAllocationsByFileGroup t2
ON t1.[file_id] = t2.Fileid
WHERE t1.database_id = DB_ID()
ORDER BY database_id, t1.[type], t1.[name]
