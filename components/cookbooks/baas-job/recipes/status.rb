Chef::Log.info("Executing baas-job.status() recipe")
svrname = node['hostname']
Chef::Log.info("Using server: #{svrname}")

processExpr = "com.walmart.platform.config.appName=baas-oo-driver "
ruby_block 'BAAS_JOB_PROCESS_STATUS' do
  block do
    pid = %x(pgrep -f "#{processExpr}")
    
    if (!pid.nil? && !pid.empty?)
      Chef::Log.info("Baas job process id is: " + pid)
    else
    	processError = "No running process found for Baas job #{node['baas-job']['job-id']}"
    	puts "***FAULT:FATAL=#{processError}"
        Chef::Log.error(processError)
        raise processError
    end
  end
end
