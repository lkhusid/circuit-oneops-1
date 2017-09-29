#
# Cookbook Name:: presto
# Recipe:: jce
#
# Copyright 2016, Walmart Labs
#
# Apache License, Version 2.0
#

configName = node['app_name']
configNode = node[configName]

# Download and expand the JCE library
jce_url = configNode['jce_install_url']
jce_dest_file = Chef::Config[:file_cache_path] + "/jce_dist.zip"
jce_dest_dir = Chef::Config[:file_cache_path] + "/jce"

bash "download_jce" do
  user "root"
  code <<-EOF
    mkdir -p #{jce_dest_dir}
    
    /usr/bin/curl "#{jce_url}" -o "#{jce_dest_file}"

    unzip #{jce_dest_file} -d #{jce_dest_dir} >/dev/null 2>&1
    
    RETCODE=$?

    if [[ "$RETCODE" != "0" ]]; then
      echo "***FAULT:FATAL=The archive #{jce_url} is not a valid archive.  Cleaning up..."
      rm -rf "#{jce_dest_file}"
    fi

    # Allow this resource to exit gracefully.  The error
    # condition will be checked and reported by the
    # check_jce_archive resource.
    #exit $RETCODE
    exit 0
  EOF
  not_if "/bin/ls #{jce_dest_file}"
end

# Validate the library
ruby_block "check_jce_archive" do
  block do
    if !File.file?("#{jce_dest_file}")
      puts "***FAULT:FATAL=Unable to download the JCE archive.  Please check the log for details."

      # Raise an exception
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end
    
    jar_count=Dir["#{jce_dest_dir}/**/*policy.jar"].length
    
    if jar_count != 2
      puts "***FAULT:FATAL=The JCE archive file does not appear to contain the JCE files (#{jce_dest_dir}) (#{jar_count}).  Please check the log for details."

      # Raise an exception
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end
  end
end

bash "copy_jce" do
  user "root"
  code <<-EOF
      JCE_FILES="`find #{jce_dest_dir} |grep 'policy.jar$'`"
       
      for JCE_FILE in "$JCE_FILES"; do
        cp -p $JCE_FILE /usr/java/default/jre/lib/security/
      done
  EOF
end
