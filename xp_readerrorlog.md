
```sql
EXECUTE sp_cycle_errorlog
EXECUTE xp_readerrorlog 1,1,N'Login',N'failed'

EXECUTE xp_readerrorlog 1,1, "Login","failed" ,'20200217','20200217'

EXECUTE xp_readerrorlog 1, 1, N'Login', N'failed', '20200217', '20200217'

EXECUTE xp_readerrorlog 1,1, "Login","failed"

EXECUTE xp_readerrorlog 1,1, "Login","failed" ,'2020-02-17 10:18:29.100','2020-02-17 10:30:41.110'

EXECUTE xp_readerrorlog 1,1, N'Login', N'failed' ,'2020-02-17 10:18:29.100','2020-02-17 10:30:41.110'

EXECUTE xp_readerrorlog 1,1, N'Login', N'failed' ,'2020-02-17 10:18:29.100', NULL

EXECUTE xp_readerrorlog 1,1, N'Login', N'failed', '2020-02-17 10:18:29.100', '2020-02-17 10:30:41.110'
```

```powershell
Import-Module SQLServer

$logFile = 1
$type    = 1
$search  = "Login"
$filter  = "failed"
$start   = "2020-02-17 10:18:29.100"
$end     = "2020-02-17 10:30:41.110"
$order   = "desc"

$Query = "EXECUTE xp_readerrorlog {0},{1},N'{2}',N'{3}','{4}','{5}','{6}'"

$SQLServer = [Microsoft.SqlServer.Management.Smo.Server]::New("localhost")
Invoke-Sqlcmd -ServerInstance $SQLServer -Query $($Query -f $logFile, $type, $search, $filter, $start, $end, $order)
```
