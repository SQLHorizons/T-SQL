SELECT
s.name AS SchemaName,
o.name AS ObjectName,
dp.name AS PrincipalName,
dperm.type AS PermissionType,
dperm.permission_name AS PermissionName,
dperm.state AS PermissionState,
dperm.state_desc AS PermissionStateDescription
FROM sys.objects o
INNER JOIN sys.schemas s on o.schema_id = s.schema_id
INNER JOIN sys.database_permissions dperm ON o.object_id = dperm.major_id
INNER JOIN sys.database_principals dp 
ON dperm.grantee_principal_id = dp.principal_id
WHERE
dperm.class = 1 --object or column
AND
dperm.type = 'EX'
AND 
dp.name = 'Specific_username'
AND
o.name = 'specific_object_name'

