name = node.workorder.payLoad.RealizedAs[0].ciName
initd_filename = 'filebeat'
if(name.empty? || name.nil?)
  Chef::Log.info("instance name is not set. use default.")
else
  initd_filename = initd_filename + "_" + name
end


service "#{initd_filename}" do
  action :stop
end
