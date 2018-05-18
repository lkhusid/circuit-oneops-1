#
# save (pushes the config to the standby) and logout
#

action :default do
  conn = @new_resource.connection || node.ns_conn

  req = 'object= { "logout":{} }'
  
  resp = conn.request(
    :method=>:post,
    :path=>"/nitro/v1/config/logout",
    :body => URI::encode(req))
  
  puts "logout response status: #{resp.status}"
  resp_obj = JSON.parse(resp.body)
  
  if resp_obj["errorcode"] != 0
    Chef::Log.error( "logout failed. resp: #{resp_obj.inspect}")    
    exit 1      
  else
    Chef::Log.info( "logout ok. resp: #{resp_obj.inspect}")    
  end  
  
end

def load_current_resource
  @current_resource = Chef::Resource::NetscalerSaveconfiglogout.new(@new_resource.name)
end
