
# Cookbook Name:: presto
# Recipe:: presto_helper
# These functions contain shared logic
#
# Copyright 2016, Walmart Labs
#
# Apache License, Version 2.0
#

def find_nexus_url()
  # Find the Nexus URL
  nexus_url = ""

  # Look in the cloud variables first to see if a value is specified
  cloud_vars = node.workorder.payLoad.OO_CLOUD_VARS
  cloud_vars.each do |var|
    if var[:ciName] == "nexus"
      nexus_url = "#{var[:ciAttributes][:value]}"
    end
  end

  if nexus_url == ""
    # The variables did not have a value...look in the services.
    cloud_name = node[:workorder][:cloud][:ciName]

    # Look in the defined services
    if (!node[:workorder][:services]["maven"].nil?)
      nexus_url = node[:workorder][:services]['maven'][cloud_name][:ciAttributes][:url]
    end
  end

  if nexus_url != ""
    # Fix it up if one was found
    nexus_url = fix_nexus_url(nexus_url)
  end

  return nexus_url
end

def fix_nexus_url(orig_nexus_url)
  new_nexus_url = orig_nexus_url

  Chef::Log.info("fix_nexus_url: in: #{orig_nexus_url}")

  urlArray = orig_nexus_url.split("/")

  # Expect the string to be:
  #
  # [http:|https:]//[server]
  #
  # or
  #
  # [http:|https:]//[server]/nexus
  #
  if (urlArray[0] == 'http:' || urlArray[0] == 'https:') && (urlArray[1] == '') && (urlArray.length == 3 || ((urlArray.length == 4) && (urlArray[3] == 'nexus')))
    # Make sure the URL ends with "nexus"
    new_nexus_url = urlArray[0] + "//" + urlArray[2] + "/nexus"
  end

  Chef::Log.info("fix_nexus_url: out: #{new_nexus_url}")

  return new_nexus_url
end
