instance = node['sql_server']['instance_name']
service_name = (instance != 'MSSQLSERVER') ? "MSSQL$#{instance}" : instance
agent_service_name = (instance == 'MSSQLSERVER') ? 'SQLSERVERAGENT' : "SQLAgent$#{instance}"

windows_service agent_service_name do
  action [:stop]
end

windows_service service_name do
  action [:stop]
end
