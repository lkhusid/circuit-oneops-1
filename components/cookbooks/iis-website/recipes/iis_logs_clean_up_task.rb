log_file_directory = node['iis-website']['log_file_directory']
logs_retention_days = node['iis-website']['logs_retention_days']
logs_cleanup_up_time = node['iis-website']['logs_cleanup_up_time']


task_name = "IISLogsCleanup"
task_description = "Daily Cleanup of IIS logs"

task_action = (node[:workorder][:rfcCi][:rfcAction] == 'add') ? :create : :update

Chef::Log.info("Task Action: #{task_action}")

taskscheduler task_name do
  action task_action
  description task_description
  path "Powershell.exe"
  arguments "-NoProfile -WindowStyle Hidden -command \"& {Get-ChildItem -Path #{log_file_directory}\\w3svc* -Recurse | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt (get-date).AddDays(-#{logs_retention_days}) } | remove-item -force}\""
  user_id "SYSTEM"
  type 'daily'
  start_day Time.now().strftime("%Y-%m-%d")
  start_time logs_cleanup_up_time
end
