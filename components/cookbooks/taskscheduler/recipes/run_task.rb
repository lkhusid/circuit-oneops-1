task_scheduler = node['taskscheduler']

taskscheduler task_scheduler.task_name do
  action :run
end
