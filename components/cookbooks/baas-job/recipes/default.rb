require 'rubygems'
require 'net/https'
require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
Chef::Log::info("Cloud name is " + cloud_name)

appUser = "#{node['baas-job']['app-user']}"
baasContext = "#{node['baas-job']['baas-context']}"
processOwner = "#{node['baas-job']['process-owner']}"
baasDir = "/" + appUser + "/" + baasContext
jobsDir = baasDir + "/jobs"
jobTypesDir = baasDir + "/jobtypes"
driverDir =  baasDir + "/" + "#{node['baas-job']['baas-driver-dir']}"
logsDir = baasDir + "/logs"

baas_service = node[:workorder][:services][:baascloudservice]
if !baas_service.nil? && !baas_service[cloud_name].nil?
  baas_cloud_service = node[:workorder][:services][:baascloudservice][cloud_name][:ciAttributes]
  Chef::Log::info("baas_repo_url == " + baas_cloud_service[:repository_url])
  Chef::Log::info("driver_version == " + baas_cloud_service[:driver_version])
else
  Chef::Log.error("baascloudservice cloud service not defined for this cloud, so cannot proceed with deployment")
  exit 1
end

### Create baas driver directory ###
Chef::Log::info("Creating the driver jar directory #{driverDir} if not present...")
directory driverDir do
	owner processOwner
	group processOwner
	mode '0777'
	recursive true
	action :create
end

### Download driver jar file ###
Chef::Log::info("Downloading the baas driver jar...")
driverRepoUrl = baas_cloud_service[:repository_url]
driverVersion = "#{node['baas-job']['driver-version']}"
Chef::Log.info("User-provided driver-version value == #{driverVersion}")
if driverVersion.to_s.empty?
  driverVersion = baas_cloud_service[:driver_version]
  Chef::Log.info("Setting driverVersion value to cloud-service defined value == #{driverVersion}")
end

driverJarNexusUrl = driverRepoUrl + "/" + driverVersion + "/baas-oneops-" + driverVersion + ".jar"
Chef::Log::info("BaaS driver remote url: #{driverJarNexusUrl}")

remote_file "#{driverDir}/baas-oneops-#{driverVersion}.jar" do
	source driverJarNexusUrl
	owner processOwner
	group processOwner
	mode '0755'
	action :create_if_missing
end

### create logmon logs directory ###
directory '/log/logmon' do
    owner processOwner
    group processOwner
    mode '0777'
    recursive true
    action :create
end

### Retrieve parameters ###
driverId="#{node['baas-job']['driver-id']}"
if driverId.to_s.empty?
  Chef::Log.error("No driver ID found which is a mandatory field.")
  exit 1
end

### Process all provided jobtype 1 related job ID and artifacts ###
jobMap1 = "#{node['baas-job']['job_map_1']}"
cfg = JSON.parse(jobMap1)
Chef::Log.info"##conf_directive_entries: #{cfg}"
cfg.each_key { |key|
	val = BaasJsonHelper.parse_json(cfg[key]).to_s
    Chef::Log.info "#vsrpKIV-#{key}=#{val}"
    jobArtifactDir = jobsDir + "/" + key + "/artifact"
    
    Chef::Log::info("Creating the job scripts directory #{jobArtifactDir} if not present...")
	directory jobArtifactDir do
        owner processOwner
        group processOwner
        mode '0777'
        recursive true
        action :create
	end
	
	### Resolve name for job script file ###
	artifactRemoteUrl = "#{val}"
	Chef::Log.info("artifactRemoteUrl is " + artifactRemoteUrl)
	jobArtifactName = File.basename(artifactRemoteUrl)
	
	### Download job script file from remote location ###
	finalArtifactPath = jobArtifactDir + "/" + jobArtifactName
	Chef::Log::info("Downloading the job script file #{jobArtifactName} from #{artifactRemoteUrl}")
	remote_file finalArtifactPath do
        source artifactRemoteUrl 
        owner processOwner
        group processOwner
        mode '0777'
        action :create_if_missing
	end
}

### Process all provided jobtype 2 related job ID and artifacts ###
jobMap2 = "#{node['baas-job']['job_map_2']}"
cfg = JSON.parse(jobMap2)
Chef::Log.info"##conf_directive_entries: #{cfg}"
cfg.each_key { |key|
	val = BaasJsonHelper.parse_json(cfg[key]).to_s
    Chef::Log.info "#vsrpKIV-#{key}=#{val}"
    jobArtifactDir = jobsDir + "/" + key + "/artifact"
    
    Chef::Log::info("Creating the job scripts directory #{jobArtifactDir} if not present...")
	directory jobArtifactDir do
        owner processOwner
        group processOwner
        mode '0777'
        recursive true
        action :create
	end
	
	### Resolve name for job script file ###
	artifactRemoteUrl = "#{val}"
	Chef::Log.info("artifactRemoteUrl is " + artifactRemoteUrl)
	jobArtifactName = File.basename(artifactRemoteUrl)
	
	### Download job script file from remote location ###
	finalArtifactPath = jobArtifactDir + "/" + jobArtifactName
	Chef::Log::info("Downloading the job script file #{jobArtifactName} from #{artifactRemoteUrl}")
	remote_file finalArtifactPath do
        source artifactRemoteUrl 
        owner processOwner
        group processOwner
        mode '0777'
        action :create_if_missing
	end
}     

if jobMap1.to_s.empty? 
  Chef::Log::warn("No entry found in job-map1")
  if jobMap2.to_s.empty?
    Chef::Log::error("No entry found in job-map2 as well, deployment cannot proceed")
    exit 1
  end
end

### Create job logs directory ###
Chef::Log::info("Creating the logs directory #{logsDir} if not present...")
directory logsDir do
        owner processOwner
        group processOwner
        mode '0777'
        recursive true
        action :create
end

### Extract artifacts from any tarballs ###
include_recipe "baas-job::extractfiles"

### Start BaaS driver application ###
include_recipe "baas-job::startdriver"

### Verify if the process started successfully ###
include_recipe "baas-job::status"

### END ###