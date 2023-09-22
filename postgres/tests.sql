
\t
select '-------------------'
union all
SELECT 'GENERAL INFORMATION'
union all
select '-------------------';

select 'Instance: <Your instance name>';
select 'Script run: ' || current_timestamp::text;
select 'Version: ' || version();
\t
select datname as databases from pg_database order by datname;
\t
select 'Extensions:';
\t
select * from pg_extension order by extname;

\t
select '-----------------'
union all
select 'SECURITY AUDITING'
union all
select '-----------------';
\t

SELECT name, setting , case when setting = 'on' then 'PASS' else 'FAIL' end as verify
FROM pg_settings
where name = 'log_connections'
union all
SELECT name, setting , case when setting = 'ddl' then 'PASS' else 'FAIL' end as verify
FROM pg_settings
where name = 'log_statement'
union all
select 'pgaudit installed',(select 'version ' || extversion::text from pg_extension where extname = 'pgaudit'), case when exists (select 1 from pg_extension where extname = 'pgaudit') then 'PASS' else 'FAIL' end;

\t
select '---------------'
union all
select 'PASSWORD EXPIRY'
union all
select '---------------';
\t

select usename, valuntil, 
       case 
	       when valuntil between now() and now() + interval '90 days' then 'PASS'
	       when valuntil < now() then 'EXPIRED' 
	       when valuntil is null or valuntil = 'infinity' then 'FAILED IF A PERSON' else 'PASS' 
	   end
from pg_user
where usename not in ('rdsadmin','appd_mon', 'system_userx', 'etc.') -- Exclude system users
order by valuntil;

\t
select '---------------------'
union all
select 'USERS WHO CAN CONNECT'
union all
select '---------------------';
\t

SELECT pgu.usename as user_name,
       (SELECT string_agg(pgd.datname, ',' ORDER BY pgd.datname) 
        FROM pg_database pgd 
        WHERE has_database_privilege(pgu.usename, pgd.datname, 'CONNECT')) AS database_name
FROM pg_user pgu
ORDER BY pgu.usename;

\t
select '------'
union all
select 'GROUPS'
union all
select '------';
\t

select groname 
from pg_group 
where groname not like 'pg%'
  and groname not in ('rds_ad','rds_iam', 'rds_password', 'rds_replication')
order by groname;

\t
select '---------------'
union all
select 'USERS IN GROUPS'
union all
select '---------------';
\t

select t2.rolname group_name , t3.rolname member_name, t4.rolname as grantor, admin_option
from pg_auth_members t1
join pg_roles t2 on t1.roleid = t2.oid
join pg_roles t3 on t1.member = t3.oid and t3.rolcanlogin
join pg_roles t4 on t1.grantor = t4.oid
order by t2.rolname,t3.rolname;

\t
select '----------------------------'
union all
select 'PERMISSIONS BY OWNERSHIP'
union all
select '----------------------------';
\t

select schemaname, tableowner, count(*)
from pg_tables
group by 1,2

\t
select '----------------------------'
union all
select 'DIRECTLY GRANTED PERMISSIONS'
union all
select '----------------------------';
\t

SELECT grantee, privilege_type, is_grantable, count(distinct table_schema||table_name) table_count       		
FROM information_schema.role_table_grants t1
join pg_tables t2 on t1.table_schema = t2.schemaname and t1.table_name = t2.tablename
join pg_roles on grantee = rolname and rolcanlogin
where grantee <> tableowner
group by grantee, privilege_type, is_grantable
order by grantee;

\t
select '---------------------'
union all
select 'EXECUTION PERMISSIONS'
union all
select '---------------------';
\t

SELECT p1.grantee,p1.is_grantable,p1.privilege_type,p1.routine_schema,p1.routine_name
FROM information_schema.role_routine_grants p1
join pg_proc p2 on p1.routine_name = p2.proname
join pg_roles p3 on p2.proowner = p3.oid
where p1.grantee <> p3.rolname
order by p1.grantee,p1.routine_schema,p1.routine_name;

\t
select '-------------------'
union all
select 'DEFAULT PERMISSIONS'
union all
select '-------------------';
\t

select pg_get_userbyid(d.defaclrole) as user, n.nspname as schema, case d.defaclobjtype when 'r' then 'tables' when 'f' then 'functions' when 'S' then 'sequences' end as object_type,array_to_string(d.defaclacl, ' + ')  as default_privileges
from pg_catalog.pg_default_acl d
left join pg_catalog.pg_namespace n on n.oid = d.defaclnamespace
order by 1,2,3;

\t
select '-------------------------------------'
union all
select 'SCRIPT END ' || current_timestamp::text
union all
select '-------------------------------------';
\t
