resource_name :elevated_script
provides :elevated_script
actions :run

property :script, String, name_property: true
property :arglist, String, default: ''
property :timeout, Integer, default: 1500
property :user, String, required: false
property :password, String, required: false

def default_interpreter_flags
  return [] if Chef::Platform.windows_nano_server?

  # Execution policy 'Bypass' is preferable since it doesn't require
  # user input confirmation for files such as PowerShell modules
  # downloaded from the Internet. However, 'Bypass' is not supported
  # prior to PowerShell 3.0, so the fallback is 'Unrestricted'
  execution_policy = Chef::Platform.supports_powershell_execution_bypass?(run_context.node) ? "Bypass" : "Unrestricted"

  [
    "-NoLogo",
    "-NonInteractive",
    "-NoProfile",
    "-ExecutionPolicy #{execution_policy}",
    # Powershell will hang if STDIN is redirected
    # http://connect.microsoft.com/PowerShell/feedback/details/572313/powershell-exe-can-hang-if-stdin-is-redirected
    "-InputFormat None",
  ]
end
    
def exit_with_error(msg)
    oneline = msg.split("\n").first
    puts "***FAULT:FATAL=#{oneline}"
    Chef::Log.error(msg)
    Chef::Application.fatal!(oneline,1)
end
 
action :run do
  cache_path = Chef::Config[:file_cache_path]
  a_path = Pathname.new(cache_path)
  script_filename = ::File.basename script, '.*'
  script_wrapper = "#{cache_path}\\#{script_filename}-wrapper.ps1" 
  
  
  #Create a wrapper script to execute the target script and report errors
  template script_wrapper do
    cookbook 'windows-utils'
    source 'Run-WrapperScript.ps1.erb'
    variables(
      script: script,
      arglist: arglist,
      cache_path: cache_path
    )
  end

  #Execute Run-ElevatedScript to create a scheduled task that will run the wrapper script
  #wrap in ruby_block to make sure it runs after the wrapper script has been created
  ruby_block 'Run-ElevatedScript' do
    block do
      service_script = "#{cache_path}\\cookbooks\\windows-utils\\files\\windows\\Run-ElevatedScript.ps1" 
      service_cmd = "#{service_script} -ExeFile #{script_wrapper} -Timeout #{new_resource.timeout.to_s}"

      if new_resource.user
        service_cmd += " -User #{new_resource.user}"
        if new_resource.password
          service_cmd += " -Password #{Chef::ReservedNames::Win32::Crypto.encrypt(password)}"
        end
      end

      cmd = "powershell.exe " + [*default_interpreter_flags].join(" ") + " -File #{service_cmd}" 
      rc = shell_out(cmd, :timeout => new_resource.timeout)

      if !rc.stderr.nil? && rc.stderr.size > 0
        exit_with_error (rc.stderr)
      end
    end
  end
  
  file script_wrapper do
    action :nothing
    subscribes :delete, 'ruby_block[Run-ElevatedScript]', :immediately
  end
  
end