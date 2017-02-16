# [Missing Indexes](http://www.jasonstrate.com/2010/12/can-you-dig-it-missing-indexes/)

The following query will return a CREATE statment for anmissing indexes:

```sql
SELECT TOP 50 
    GETDATE() AS [RunTime],
    DB_NAME(mid.database_id) AS [DBNAME], 
    OBJECT_NAME(mid.[object_id]) AS [ObjectName], mid.[object_id] AS [ObjectID],
    CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS [Improvement_Measure],
    'CREATE INDEX missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + CONVERT (varchar, mid.index_handle) 
    + ' ON ' + mid.statement 
    + ' (' + ISNULL (mid.equality_columns,'') 
    + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END + ISNULL (mid.inequality_columns, '')
    + ')' 
    + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS [CREATE_INDEX_Statement],
    migs.user_seeks, migs.user_scans, migs.last_user_seek, migs.last_user_scan, migs.avg_total_user_cost, migs.avg_user_impact, migs.avg_system_impact,
    mig.index_group_handle, mid.index_handle
FROM sys.dm_db_missing_index_groups mig
    INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) > 10
    AND mid.database_id = DB_ID()
ORDER BY [Improvement_Measure] DESC
```


```sql
/*
based off of a combination of:
      Jason Strate's Excellent Missing Indexes queries to get the Execution Plans:
              http://www.jasonstrate.com/2010/12/can-you-dig-it-missing-indexes/
        And my own technique of grabbing the costs and multiplying them 
                      by the Execution Count to get Aggregate costs:
              http://sqlmag.com/blog/performance-tip-find-your-most-expensive-queries
      TODO: need to figure out a way to 

a) get a list of indexes by impact, then 
              b) cross-apply their plans and get costs
*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO
 
WITH XMLNAMESPACES(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
PlanMissingIndexes AS (
        SELECT 

query_plan, 
                usecounts 
        FROM 
                sys.dm_exec_cached_plans cp
                CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
        WHERE 
                qp.query_plan.exist('//MissingIndexes') = 1),
 
MissingIndexes AS (
        SELECT

stmt_xml.value('(QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]'
                        , 'sysname') AS DatabaseName,
                stmt_xml.value('(QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Schema)[1]'
                        , 'sysname') AS SchemaName,
                stmt_xml.value('(QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]'
                        , 'sysname') AS TableName,
                stmt_xml.value('(QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]'
                        , 'float') AS Impact,
                ISNULL(CAST(stmt_xml.value('(@StatementSubTreeCost)[1]'
                        , 'VARCHAR(128)') as float),0) AS Cost,
                pmi.usecounts UseCounts,
                STUFF((SELECT DISTINCT ', ' + c.value('(@Name)[1]', 'sysname')
        FROM 
                stmt_xml.nodes('//ColumnGroup') AS t(cg)
                CROSS APPLY cg.nodes('Column') AS r(c)
        WHERE 
                cg.value('(@Usage)[1]', 'sysname') = 'EQUALITY' 
                FOR  XML PATH('')), 1, 2, '') AS equality_columns
                        ,STUFF((SELECT DISTINCT ', ' + c.value('(@Name)[1]', 'sysname')
                FROM stmt_xml.nodes('//ColumnGroup') AS t(cg)
                CROSS APPLY cg.nodes('Column') AS r(c)
                WHERE cg.value('(@Usage)[1]', 'sysname') = 'INEQUALITY'
                FOR  XML PATH('')), 1, 2, '') AS inequality_columns
                        ,STUFF((SELECT DISTINCT ', ' + c.value('(@Name)[1]', 'sysname')
                FROM stmt_xml.nodes('//ColumnGroup') AS t(cg)
                CROSS APPLY cg.nodes('Column') AS r(c)
                WHERE cg.value('(@Usage)[1]', 'sysname') = 'INCLUDE'
                FOR  XML PATH('')), 1, 2, '') AS include_columns
                ,query_plan
                ,stmt_xml.value('(@StatementText)[1]', 'varchar(4000)') AS sql_text
                FROM PlanMissingIndexes pmi
                CROSS APPLY query_plan.nodes('//StmtSimple') AS stmt(stmt_xml)
                WHERE stmt_xml.exist('QueryPlan/MissingIndexes') = 1
)
 
SELECT TOP 200
        DatabaseName,
        SchemaName,
        TableName,
        equality_columns,
        inequality_columns,
        include_columns,
        usecounts,
        Cost,
        Cost * UseCounts [AggregateCost],
        Impact,
        query_plan
        FROM MissingIndexes
        WHERE DatabaseName NOT IN ('[master]', '[msdb]', '[distribution]')
        ORDER BY 
                Cost * usecounts DESC;
```
