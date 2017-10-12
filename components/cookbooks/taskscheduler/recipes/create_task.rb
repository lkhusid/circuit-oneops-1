
task_scheduler = node['taskscheduler']

hostname = `hostname`.chomp.chars.first(15).join

if !task_scheduler.username.include?('\\')
  user_name = "#{hostname}\\#{task_scheduler.username}"
else
  user_name = task_scheduler.username
end

node.set['workorder']['rfcCi']['ciAttributes']['user_right'] = "SeBatchLogOnRight"
include_recipe 'windows-utils::assign_user_rights'


version = node['workorder']['rfcCi']['ciAttributes']['package_version']
package_name = task_scheduler["package_name"]
task_scheduler_path = "#{task_scheduler.physical_path}\\#{package_name}\\#{version}\\#{task_scheduler.path}"

task_action = ( node[:workorder][:rfcCi][:rfcAction] == 'update' ) ? :update : :create

taskscheduler task_scheduler.task_name do
  action task_action
  task_name task_scheduler.task_name
  description task_scheduler.task_description
  path task_scheduler_path
  arguments task_scheduler.arguments
  working_directory task_scheduler.working_directory
  user_id user_name
  password task_scheduler.password
  type task_scheduler.frequency
  execution_time_limit task_scheduler.execution_time_limit
  start_day task_scheduler.start_day
  start_time task_scheduler.start_time
  days_interval task_scheduler.days_interval.to_i
  days_of_week task_scheduler.days_of_week
  weeks_interval task_scheduler.weeks_interval.to_i
end

include_recipe 'taskscheduler::restart_task'
