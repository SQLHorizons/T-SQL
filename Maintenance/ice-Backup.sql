DECLARE @DatabaseName VARCHAR(80)
DECLARE @BackupPath VARCHAR(256)
DECLARE @BackUpFileName VARCHAR(256)
DECLARE @Date VARCHAR(20)
 
/* Enable Trace Flag 3042 */
DBCC TRACEON (3042,-1); DBCC TRACESTATUS
 
SET @BackupPath = 'T:\Data_X\backup_01\SQL2014\MSSQL12.MSSQLSERVER\MSSQL\Backup\'
SELECT @Date = CONVERT(VARCHAR(20),GETDATE(),112) + REPLACE(CONVERT(VARCHAR(20),GETDATE(),108),':','')
PRINT @Date
 
DECLARE db_cursor CURSOR FOR
WITH curBackups AS
(
SELECT bus.database_name AS [Name]
, MAX(bus.backup_finish_date) AS [backup_finish_date]
, MAX(bus.backup_size) AS [Size]
FROM msdb.dbo.backupset bus
WHERE [type] = 'D'
GROUP BY bus.database_name
),
dbBackups AS
(
SELECT sdb.Name, cbu.backup_finish_date
, cbu.Size
FROM master.sys.databases sdb
LEFT OUTER JOIN curBackups cbu ON cbu.Name = sdb.name
WHERE sdb.Name NOT IN ('model','tempdb')
AND sdb.state = 0
)
 
SELECT Name FROM dbBackups
WHERE backup_finish_date < DATEADD(dd,-1,GETDATE()) OR backup_finish_date IS NULL
ORDER BY Size
 
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DatabaseName
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @BackUpFileName = @BackupPath + @DatabaseName + '_' + @Date + '.bak'
    BACKUP DATABASE @DatabaseName TO DISK = @BackUpFileName WITH STATS = 2    
    FETCH NEXT FROM db_cursor INTO @DatabaseName
END
CLOSE db_cursor
 
DEALLOCATE db_cursor
