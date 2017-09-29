
def get_attribute_value(attr_name)
	node.workorder.rfcCi.ciBaseAttributes.has_key?(attr_name)? node.workorder.rfcCi.ciBaseAttributes[attr_name] : node.tomcat[attr_name]
end

def tom_ver
	return "tomcat"+node[:tomcat][:version][0,1]
end

def exit_with_error(msg)
	Chef::Log.error(msg)
	puts "***FAULT:FATAL=#{msg}"
	Chef::Application.fatal!(msg)
end
