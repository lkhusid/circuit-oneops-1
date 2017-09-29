dbname = node['database']['dbname']
username = node['database']['username']
password = node['database']['password']

mssql = node['workorder']['payLoad']['DependsOn'].select { |db|
  db['ciClassName'].split('.').last == 'Mssql' }

cmd = "Invoke-Sqlcmd -Query \"$QUERY$\""

#1. Create database
sqlcmd = "IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = N'#{dbname}')
CREATE DATABASE [#{dbname}] "
Chef::Log.info("Create DB: #{dbname}")
powershell_script 'Create-Database' do
  code cmd.gsub("$QUERY$",sqlcmd)
end

#2. Create login
if username.include?("\\")
  sqlcmd = "IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'#{username}')
CREATE LOGIN [#{username}] FROM WINDOWS WITH DEFAULT_DATABASE=[#{dbname}]"
else
  sqlcmd = "IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'#{username}')
CREATE LOGIN [#{username}] WITH PASSWORD=N'#{password}',DEFAULT_DATABASE=[#{dbname}], CHECK_POLICY=ON"
end

Chef::Log.info("Create login: #{username}")
powershell_script 'Create-Login' do
  code cmd.gsub("$QUERY$",sqlcmd)
end

#3. Create database user and make him a db_owner
sqlcmd = "IF NOT EXISTS (select * from sys.database_principals where type = N'S' and name = N'#{username}')
BEGIN
  CREATE USER [#{username}] FOR LOGIN [#{username}]
  EXEC sp_addrolemember N'db_owner', N'#{username}'
END"
Chef::Log.info("Create database user: #{username}")
powershell_script 'Create-DBUser' do
  code cmd.gsub("$QUERY$",sqlcmd) + " -Database '#{dbname}'"
end
