%w(aspnet_counters dotnet_counters iis_service_status system_counters web_connections).each do | script_file_name |
  template "C:\\cygwin64\\opt\\nagios\\libexec\\#{script_file_name}.ps1" do
    source "#{script_file_name}.ps1.erb"
  end
end
