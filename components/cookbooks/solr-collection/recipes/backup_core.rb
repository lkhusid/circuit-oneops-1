include_recipe 'solr-collection::default'
ci = node.workorder.has_key?("rfcCi")?node.workorder.rfcCi : node.workorder.ci

# get input arguments
args = ::JSON.parse(node.workorder.arglist)

# input collection name must match with the collection name from metedata attributes
collection_name = args["collection_name"]
if collection_name == nil || collection_name.empty?
  raise "Collection name must be provided."
end
if !collection_name.eql?node['collection_name']
  raise "Provided collection #{collection_name} is not configured on this component. The collection name associted with this collection component is #{node['collection_name']}"
end

# get backup_location from metedata attributes
backup_location = ci.ciAttributes.backup_location
Chef::Log.info("backup_location = #{backup_location}")
if backup_location == nil || backup_location.empty?
  raise "Backup location must be provided."
end

Chef::Log.info("collection_name = #{collection_name}")
Chef::Log.info("backup_location = #{backup_location}")

# backup name will be siffixed with current timestamp in yyyymmdd_hhmmss format
time = Time.new
#time_s = time.strftime("%Y%m%d_%H%M%S")
tims_s = time.strftime("%Y_%m_%d_%H_%M_%S")

# create log file for this action so that at the end the log can be display
backup_logfile = "/app/solrdata#{node['solrmajorversion']}/logs/backup_#{collection_name}_action.log"
Chef::Log.info("backup_logfile = #{backup_logfile}")

user_dir = node['user']['dir'] 
solr_pack_dir = "#{user_dir}/solr_pack"
Chef::Log.info("user home directory : #{user_dir}")

# Execute solr core backup script /app/solr6/plugins/backup_collection_core.rb
# This script will backup the core if this node is leader and store backup in '/app_solr_backup'
cmd = "ruby #{solr_pack_dir}/backup_collection_core.rb #{collection_name} #{backup_location} #{backup_logfile}"
Chef::Log.info("command = #{cmd}")
execute "backup_core" do
    command cmd
    user "app"
end

# Show the log file contents
ruby_block "backup_solr_core" do
    only_if { ::File.exists?(backup_logfile) }
    block do
        print "\n"
        File.open(backup_logfile).each do |line|
            print line
        end
    end
end
