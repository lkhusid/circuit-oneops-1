processExpr = "#{node['service-mesh']['service-mesh-root']}/soa-linkerd-#{node['service-mesh']['service-mesh-version']}.jar "
ruby_block 'SERVICE_MESH_PROCESS_STATUS' do
  block do
    pid = %x(pgrep -f "#{processExpr}")
    
    if (!pid.nil? && !pid.empty?)
      Chef::Log.info("Service mesh process id is: " + pid)
    else
    	processError = "No running process found for service mesh"
    	puts "***FAULT:FATAL=#{processError}"
        Chef::Log.error(processError)
        raise processError
    end
  end
end
