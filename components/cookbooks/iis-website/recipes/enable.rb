features = [
  'Web-Default-Doc',
  'Web-Http-Errors',
  'Web-Static-Content',
  'Web-Http-Redirect',
  'Web-Http-Logging',
  'Web-Request-Monitor',
  'Web-Http-Tracing',
  'Web-Stat-Compression',
  'Web-Dyn-Compression',
  'Web-Filtering',
  'Web-Basic-Auth',
  'Web-Windows-Auth',
  'Web-Net-Ext',
  'Web-Net-Ext45',
  'Web-Asp-Net',
  'Web-Asp-Net45',
  'Web-ISAPI-Ext',
  'Web-ISAPI-Filter',
  'Web-Mgmt-Console',
  'Web-Scripting-Tools',
  'Web-Mgmt-Service',
  'Net-Framework-Core',
  'NET-Framework-45-Core',
  'NET-Framework-45-ASPNET',
  'Web-AppInit'
]

dotnetframework = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Dotnetframework/ }

dotnetframework.each do | framework |
  runtime = framework["ciAttributes"]
  if runtime.has_key?("install_dotnetcore") && runtime.install_dotnetcore == "true"
   features.delete('Web-Net-Ext')
   features.delete('Web-Asp-Net')
   features.delete('Net-Framework-Core')
   node.set['workorder']['rfcCi']['ciAttributes']['install_dotnetcore'] = "true"
  end
end

Chef::Log.info("WindowsFeatures: #{features}")

powershell_script 'installing windows features' do
  code "Install-WindowsFeature #{features.join(',')}"
  not_if "if ((Get-WindowsFeature #{features.join(',')} | ?{ $_.Installed -match $true }).count -eq #{features.count}) { $true } else { $false }"
  guard_interpreter :powershell_script
end
