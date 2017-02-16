# [Discovering Unused Indexes](https://www.mssqltips.com/sqlservertutorial/256/discovering-unused-indexes/)
To ensure that data access can be as fast as possible, SQL Server like other relational database systems utilizes indexing to find data quickly.  SQL Server has different types of indexes that can be created such as clustered indexes, non-clustered indexes, XML indexes and Full Text indexes.
The benefit of having more indexes is that SQL Server can access the data quickly if an appropriate index exists.  The downside to having too many indexes is that SQL Server has to maintain all of these indexes which can slow things down and indexes also require additional storage.  So as you can see indexing can both help and hurt performance.

In this section we will focus on how to identify indexes that exist, but are not being used and therefore can be dropped to improve performance and decrease storage requirements.


```sql
SELECT OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
    I.[NAME] AS [INDEX NAME], 
    S.USER_SEEKS, 
    S.USER_SCANS, 
    S.USER_LOOKUPS, 
    S.USER_UPDATES,
    A.LEAF_INSERT_COUNT, 
    A.LEAF_UPDATE_COUNT, 
    A.LEAF_DELETE_COUNT  
FROM   SYS.DM_DB_INDEX_USAGE_STATS AS S
    INNER JOIN
    SYS.DM_DB_INDEX_OPERATIONAL_STATS (DB_ID(),NULL,NULL,NULL ) A
    ON
    S.[OBJECT_ID] = A.[OBJECT_ID]
    INNER JOIN 
    SYS.INDEXES AS I
    ON
    I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID  
WHERE  OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1
    AND S.database_id = DB_ID()
```

## d

```sql
WITH [UnusedIdx] AS
(
    SELECT OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
        I.[NAME] AS [INDEX NAME], 
        S.USER_SEEKS, 
        S.USER_SCANS, 
        S.USER_LOOKUPS,
        S.USER_SEEKS + S.USER_SCANS + S.USER_LOOKUPS AS [idxValue],                 
        S.USER_UPDATES,
        A.LEAF_INSERT_COUNT, 
        A.LEAF_UPDATE_COUNT, 
        A.LEAF_DELETE_COUNT  
    FROM   SYS.DM_DB_INDEX_USAGE_STATS AS S
        INNER JOIN
        SYS.DM_DB_INDEX_OPERATIONAL_STATS (DB_ID(),NULL,NULL,NULL ) A
        ON
        S.[OBJECT_ID] = A.[OBJECT_ID]
        INNER JOIN 
        SYS.INDEXES AS I
        ON
        I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID  
    WHERE  OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1
        AND I.[NAME] IS NOT NULL
        AND I.[index_id] > 1                         
        AND S.database_id = DB_ID()
)
 
SELECT DISTINCT 
    [OBJECT NAME], 
    [INDEX NAME],
    'DROP INDEX [' + [INDEX NAME] + '] ON [dbo].[' + [OBJECT NAME] + ']' AS [DROP IDX],
    [USER_SEEKS], 
    [USER_SCANS], 
    [USER_LOOKUPS],
    [USER_UPDATES]
FROM [UnusedIdx]
    WHERE [idxValue] < 1
    ORDER BY [OBJECT NAME], [INDEX NAME]
```
