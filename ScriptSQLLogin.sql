SELECT 'CREATE LOGIN ' + QUOTENAME(u.name) + ' WITH PASSWORD=' + CONVERT(NVARCHAR(MAX),l.password_hash,1)+ ' HASHED, DEFAULT_DATABASE='
+QUOTENAME(l.default_database_name) +', DEFAULT_LANGUAGE='
+QUOTENAME(l.default_language_name)+', CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF, sid = ' + CONVERT(NVARCHAR(MAX),u.sid,1) FROM sys.database_principals u
INNER JOIN sys.sql_logins l
ON u.sid = l.sid
WHERE u.type = 'S'
AND u.principal_id > 4
