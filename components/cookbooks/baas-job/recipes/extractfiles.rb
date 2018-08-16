require 'rubygems'
require 'json'

 
appUser = "#{node['baas-job']['app-user']}"
baasContext = "#{node['baas-job']['baas-context']}"
processOwner = "#{node['baas-job']['process-owner']}"
baasDir = "/" + appUser + "/" + baasContext
jobsDir = baasDir + "/jobs"
jobTypesDir = baasDir + "/jobtypes"
driverDir =  baasDir + "/" + "#{node['baas-job']['baas-driver-dir']}"
logsDir = baasDir + "/logs"

### Process all provided jobtype 1 related job ID and artifacts ###
jobMap1 = "#{node['baas-job']['job_map_1']}"
cfg = JSON.parse(jobMap1)
cfg.each_key { |key|
	val = BaasJsonHelper.parse_json(cfg[key]).to_s
    jobArtifactDir = jobsDir + "/" + key + "/artifact"
    
	### Resolve name for job script file ###
	artifactRemoteUrl = "#{val}"
	Chef::Log.info("EF:artifactRemoteUrl is " + artifactRemoteUrl)
	jobArtifactName = File.basename(artifactRemoteUrl)
	
	### Download job script file from remote location ###
	finalArtifactPath = jobArtifactDir + "/" + jobArtifactName
	
	### Extract files if the artifact is one of zip/tar/.gz files
	gz_ext_names = %w(.tgz .gz .tbz .tbz2 .tb2 .bz2 .taz .Z .tlz .lz .lzma .xz)
	tar_ext_names = %w(.tar)
    if gz_ext_names.include? File.extname(finalArtifactPath)
		Chef::Log.info("EF:extracting #{finalArtifactPath} into #{jobArtifactDir}")
  		`sudo tar -xvzf #{finalArtifactPath} -C #{jobArtifactDir}`
	else
		Chef::Log.info("EF:No zipped file found to be extracted as job artifact for #{finalArtifactPath}")
    end
	if tar_ext_names.include? File.extname(finalArtifactPath)
		Chef::Log.info("EF:untarring #{finalArtifactPath} into #{jobArtifactDir}")
		
		ruby_block 'create extract for baas artifact' do
		    block do
		        Chef::Log.info("---------->STARTING EXTRACT FOR BAAS JOB ARTIFACT ")
		        # gen env vars & update .bashrc
		        `sudo tar -xvf #{finalArtifactPath} -C #{jobArtifactDir}`
		        if $?.to_i != 0
		            Chef::Log.info("EXTRACT FAILED")
		        else
		            Chef::Log.info('EXTRACT SUCCEEDED')
		        end
		    end
		end
		
###  		`sudo tar -xvf #{finalArtifactPath} -C #{jobArtifactDir}`
    else
		Chef::Log.info("EF:No tarball found to be extracted as job artifact for #{finalArtifactPath}")
    end
}

### Process all provided jobtype 2 related job ID and artifacts ###
jobMap2 = "#{node['baas-job']['job_map_2']}"
cfg = JSON.parse(jobMap2)
cfg.each_key { |key|
	val = BaasJsonHelper.parse_json(cfg[key]).to_s
    jobArtifactDir = jobsDir + "/" + key + "/artifact"
    
	### Resolve name for job script file ###
	artifactRemoteUrl = "#{val}"
	jobArtifactName = File.basename(artifactRemoteUrl)
	
	### Download job script file from remote location ###
	finalArtifactPath = jobArtifactDir + "/" + jobArtifactName
	
	### Extract files if the artifact is one of zip/tar/.gz files
	gz_ext_names = %w(.tgz .gz .tbz .tbz2 .tb2 .bz2 .taz .Z .tlz .lz .lzma .xz)
	tar_ext_names = %w(.tar)
	
    if gz_ext_names.include? File.extname(finalArtifactPath)
		Chef::Log.info("EF:extracting #{finalArtifactPath} into #{jobArtifactDir}")
  		`sudo tar -xvzf #{finalArtifactPath} -C #{jobArtifactDir}`
	else
		Chef::Log.info("EF:No zipped file found to be extracted as job artifact for #{finalArtifactPath}")
    end
	if tar_ext_names.include? File.extname(finalArtifactPath)
		Chef::Log.info("EF:untarring #{finalArtifactPath} into #{jobArtifactDir}")
		
		ruby_block 'create extract for baas artifact' do
		    block do
		        Chef::Log.info("---------->STARTING EXTRACT FOR BAAS JOB ARTIFACT ")
		        # gen env vars & update .bashrc
		        `sudo tar -xvf #{finalArtifactPath} -C #{jobArtifactDir}`
		        if $?.to_i != 0
		            Chef::Log.info("EXTRACT FAILED")
		        else
		            Chef::Log.info('EXTRACT SUCCEEDED')
		        end
		    end
		end
		
###  		`sudo tar -xvf #{finalArtifactPath} -C #{jobArtifactDir}`
    else
		Chef::Log.info("EF:No tarball found to be extracted as job artifact for #{finalArtifactPath}")
    end
}     


### Create job logs directory ###
Chef::Log::info("EF:Creating the logs directory #{logsDir} if not present...")
directory logsDir do
        owner processOwner
        group processOwner
        mode '0777'
        recursive true
        action :create
end

### Start BaaS driver application ###
include_recipe "baas-job::startdriver"

### Verify if the process started successfully ###
include_recipe "baas-job::status"

### END ###