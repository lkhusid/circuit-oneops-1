application = node.workorder.rfcCi.ciAttributes
username = application.username
user_right = application.user_right

cmd = Mixlib::ShellOut.new("net user #{username}")
cmd.run_command
Chef::Log.fatal "Account with username #{username} does not exist. Please check the username." if cmd.stderr.include?("The user name could not be found.") && !username.include?('\\')

cookbook_file "C:\\Windows\\Temp\\UserRights.ps1" do
  cookbook "windows-utils"
  source "UserRights.ps1"
  action :create
end


powershell_script "grant the user #{username}, #{user_right} rights" do
  code <<-EOH
    try
    {
      Import-Module C:\\Windows\\Temp\\UserRights.ps1
      Grant-UserRight -Account #{username} -Right #{user_right}
    }
    catch
    {
       throw "User #{username} could not be granted rights. Please make sure that the user exist."
    }
  EOH
end
