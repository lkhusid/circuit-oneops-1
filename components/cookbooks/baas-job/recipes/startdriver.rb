require 'rubygems'
require 'json'

### Check installed java version
command = "java -version" 
cmd = Mixlib::ShellOut.new(command).run_command
Chef::Log.info("##Found java version: #{cmd.stdout}, errors if any: #{cmd.stderr}")

### Retrieve parameters
appUser = "#{node['baas-job']['app-user']}"
baasContext = "#{node['baas-job']['baas-context']}"
processOwner = "#{node['baas-job']['process-owner']}"
baasDir = "/" + appUser + "/" + baasContext
driverDir =  baasDir + "/" + "#{node['baas-job']['baas-driver-dir']}"
driverVersion = "#{node['baas-job']['driver-version']}"
scmRootDir = "/" + appUser + "/scm/"

### check if the environment is prod or nonprod ###
derivedRunEnv = "stg0"
profile = node[:workorder][:payLoad][:Environment][0][:ciAttributes][:profile].downcase
Chef::Log.info("Got env profile as #{profile}")
if profile.include? "prod"
    Chef::Log.info("Deployment taking place in production environment")
    derivedRunEnv = "prod"
end
Chef::Log.info("Final derivedRunEnv= #{derivedRunEnv}")

driverId="#{node['baas-job']['driver-id']}"

runEnv = "#{node['baas-job']['run-env']}"
Chef::Log.info("User-provided runOnEnv value == #{runEnv}")
if runEnv.to_s.empty?
  runEnv = derivedRunEnv
  Chef::Log.info("Setting runOnEnv value to environment-derived one == #{runEnv}")
end

Chef::Log.info("User-provided driver-version value == #{driverVersion}")
if driverVersion.to_s.empty?
  cloud_name = node[:workorder][:cloud][:ciName]
  baas_cloud_service = node[:workorder][:services][:baascloudservice][cloud_name][:ciAttributes]
  driverVersion = baas_cloud_service[:driver_version]
  Chef::Log.info("Setting driverVersion value to default cloud-service defined value == #{driverVersion}")
end

logsDir = baasDir + "/logs"
driverLogPath = logsDir + "/driver.log"
userJobLogPath = logsDir + "/jobs.log"

jobConfig = ""
Chef::Log.info "Reading job entries for first jobtype"
jobtype_1 = "#{node['baas-job']['job-type-1']}"
jobMap1 = "#{node['baas-job']['job_map_1']}"
cfg = JSON.parse(jobMap1)
cfg.each_key { |key|
	val = BaasJsonHelper.parse_json(cfg[key]).to_s
	jobConfig = jobConfig + "#{jobtype_1}" + "^" + "#{key}" + "_"
	Chef::Log.info( "JobConfig during first type pass: " + jobConfig)
}
Chef::Log.info "Finished reading entries for first jobtype"

Chef::Log.info "Reading job entries for second jobtype"
jobtype_2 = "#{node['baas-job']['job-type-2']}"
jobMap2 = "#{node['baas-job']['job_map_2']}"
cfg = JSON.parse(jobMap2)
cfg.each_key { |key|
    val = BaasJsonHelper.parse_json(cfg[key]).to_s
    jobConfig = jobConfig + "#{jobtype_2}" + "^" + "#{key}" + "_"
    Chef::Log.info( "JobConfig during second type pass: " + jobConfig)
}
Chef::Log.info "Finished reading entries for second jobtype"

if (jobConfig.end_with? "_")
  Chef::Log.info("JobConfig ends with underscore: " + jobConfig)
  jobConfig = jobConfig.chop
else
	Chef::Log.info("JobConfig doesn't end with underscore: " + jobConfig)
end

Chef::Log.info("final-job-config = " + jobConfig)
commandToExecute = "java -Dbaas.root.dir=#{baasDir} -Djob.conf.details=#{jobConfig} -Dcom.walmart.platform.config.runOnEnv=#{runEnv} -Dcom.walmart.platform.config.appName=baas-oo-driver -Dbaas.driver.identifier=#{driverId} -Dscm.root.dir=#{scmRootDir} -Dlog.file.path=#{driverLogPath} -Dapp.version=#{driverVersion} -jar #{driverDir}/baas-oneops-#{driverVersion}.jar > #{userJobLogPath} 2>&1 &"

Chef::Log::info("Adding baas-job initd script")
template '/etc/init.d/baasdriver' do
  source 'baasdriver-init.erb'
  owner 'root'
  group 'root'
  mode 00755
  variables(:start_baas_command => commandToExecute,
            :grep_string_baas_process => "com.walmart.platform.config.appName=baas-oo-driver ")
end

execute 'enableMeshDaemon' do
	command 'chkconfig --add baasdriver'
	user	'root'
end

### Start Service Mesh process ###
include_recipe "baas-job::restart"
