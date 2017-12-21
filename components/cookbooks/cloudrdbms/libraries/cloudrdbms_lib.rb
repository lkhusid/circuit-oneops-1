# Cloud RDBMS oneops pack - library

require 'rexml/document'
require 'net/http'

class Chef::Recipe::CloudrdbmsArtifact

  def self.get_latest_version (artifact_dir, artifact_version)
    # there are 3 'return' statements here:
    # return #1: will return the LATEST RELEASE version
    # return #2: will return the LATEST SNAPSHOT version
    # return #3: will return a specific RELEASE version (it could coincide with the LATEST, or not)

    if (artifact_version =~ /LATEST-RELEASE/)
      # user chose version = "LATEST-RELEASE"  -  so we need to find out what the latest really is. We parse the XML file 'maven-metadata.xml' found in nexus:
      latest_version = ""
      Chef::Log.info("CloudRDBMS Looking for metadata at #{artifact_dir}")
      artifact_metadata = "#{artifact_dir}/maven-metadata.xml"
      xmlDoc = get_xml_doc(artifact_metadata)
      xmlDoc.elements.each('metadata/versioning') do |version|
        latest_version = version.get_text('release')
      end #xmlDoc
      if latest_version.empty?
        puts "CloudRDBMS FAULT:FATAL= Latest version not found"
        Chef::Log.error("CloudRDBMS Latest Version Not Found in #{metadata}")
      else
        return latest_version, latest_version, "#{artifact_dir}/#{latest_version}/mysql-agent-#{latest_version}.zip"
      end #if latest_version.empty?
    end #if (artifact_version =~ /LATEST-RELEASE/)

    if (artifact_version =~ /LATEST-SNAPSHOT/)
      # user chose version = "LATEST-SNAPSHOT"  -  so we need to find out what the latest really is. We parse the XML file 'maven-metadata.xml' found in nexus. We parse 2 different 'maven-metadata.xml' files:
      latest_version = ""
      Chef::Log.info("CloudRDBMS change the nexus URL path, replace pangaea_releases with pangaea_snapshots")
      artifact_dir.gsub! 'pangaea_releases', 'pangaea_snapshots'
      Chef::Log.info("CloudRDBMS Looking for SNAPSHOT metadata at #{artifact_dir}")
      artifact_metadata = "#{artifact_dir}/maven-metadata.xml"
      xmlDoc = get_xml_doc(artifact_metadata)
      xmlDoc.elements.each('metadata/versioning') do |version|
        latest_version = version.get_text('latest')
      end #xmlDoc
      if latest_version.empty?
        puts "CloudRDBMS FAULT:FATAL= Latest SNAPSHOT version not found"
        Chef::Log.error("CloudRDBMS Latest SNAPSHOT Version Not Found in #{metadata}")
      else
        # parse the second 'maven-metadata.xml' file - there could be multiple builds under the same SNAPSHOT version
        snapshot_name = ""
        Chef::Log.info("CloudRDBMS found SNAPSHOT metadata latest version #{latest_version}.  Need to search again to find the latest build for that snapshot version")
        Chef::Log.info("CloudRDBMS Looking for SNAPSHOT metadata at #{artifact_dir}/#{latest_version}")
        artifact_metadata = "#{artifact_dir}/#{latest_version}/maven-metadata.xml"
        xmlDoc = get_xml_doc(artifact_metadata)
        xmlDoc.elements.each('metadata/versioning/snapshotVersions/snapshotVersion') do |version|
          #Chef::Log.info("CloudRDBMS SNAPSHOT version: #{version}")
          if (version.get_text('extension') == 'zip')
            Chef::Log.info("CloudRDBMS SNAPSHOT /snapshotVersion: #{version}")
            snapshot_name = version.get_text('value')
          end #if (version.get_text('extension') == 'zip')
        end #xmlDoc
        #Chef::Log.info("CloudRDBMS SNAPSHOT URL #{artifact_dir}/#{latest_version}/mysql-agent-#{snapshot_name}.zip")
        # when we unzip the snapshot zip file, the folder name that gets created does not have the same name as the zip file. The variable 'latest_version' below will help us to create the symbolic link to the correct "unzipped" directory. For example we unzip 'mysql-agent-0.2.14-20160609.201323-1.zip', directory 'mysql-agent-0.2.14-SNAPSHOT' gets created
        return snapshot_name, latest_version, "#{artifact_dir}/#{latest_version}/mysql-agent-#{snapshot_name}.zip"
      end #if latest_version.empty?
    end #if (artifact_version =~ /LATEST-SNAPSHOT/)

    # user chose a specific version instead of "LATEST-RELEASE" or "LATEST-SNAPSHOT" - just return that specific version:
    Chef::Log.info("CloudRDBMS user chose a specific version")
    return artifact_version, artifact_version, "#{artifact_dir}/#{artifact_version}/mysql-agent-#{artifact_version}.zip"
  end

  def self.get_xml_doc (artifact_metadata)
    begin
      url = URI(artifact_metadata)
      metadata = Net::HTTP.get(url)
      xmlDoc = REXML::Document.new(metadata)
    rescue REXML::ParseException => e
      puts "CloudRDBMS FAULT:FATAL= URL does not exist: #{url} Exception: #{e.message}"
      Chef::Log.error("CloudRDBMS URL does not exist: #{url} Exception: #{e.message}")
    end
    return xmlDoc
  end

  ### This method returns the backup_id of the current cluster
  def self.get_backup_id_from_node(node)
    metadata_json=node[:workorder][:payLoad][:DependsOn][0][:ciAttributes][:metadata]
    metadata=JSON.parse(metadata_json)
    `echo CloudrdbmsArtifact get_backup_id_from_node >/tmp/CloudrdbmsArtifact-get_backup_id_from_node.log`
    `echo org #{metadata["organization"]} assembly #{metadata["assembly"]} environment #{metadata["environment"]} platform #{metadata["platform"]} >>/tmp/CloudrdbmsArtifact-get_backup_id_from_node.log`
    return self.get_backup_id(metadata["organization"], metadata["assembly"], metadata["environment"], metadata["platform"])
  end

  ### This method returns the md5 hash of a fully qualified platform name
  def self.get_backup_id(orgName, assemblyName, environmentName, platformName)
    ### Get the backup id as the full platform name and convert it to lower case
    backup_id = "<#{orgName}-#{assemblyName}-#{environmentName}-#{platformName}>"
    backup_id.downcase!
    hashed_backup_id = Digest::MD5.hexdigest(backup_id)
    return hashed_backup_id
  end

  ### if a parameter is not set, it will default to current cluster
  def self.get_backup_id_with_defaults(node, orgName, assemblyName, environmentName, platformName)
    metadata_json=node[:workorder][:payLoad][:DependsOn][0][:ciAttributes][:metadata]
    metadata=JSON.parse(metadata_json)
    `echo CloudrdbmsArtifact get_backup_id_with_defaults >/tmp/CloudrdbmsArtifact-get_backup_id_with_defaults.log`
    `echo original values typed in the oneops RESTORE ACTION orgName #{orgName} assemblyName #{assemblyName} environmentName #{environmentName} platformName #{platformName} >>/tmp/CloudrdbmsArtifact-get_backup_id_with_defaults.log`

    ### set the default value as the current cluster
    orgName = metadata["organization"] if orgName.to_s.strip.length == 0
    assemblyName = metadata["assembly"] if assemblyName.to_s.strip.length == 0
    environmentName = metadata["environment"] if environmentName.to_s.strip.length == 0
    platformName = metadata["platform"] if platformName.to_s.strip.length == 0
    `echo modified orgName #{orgName} assemblyName #{assemblyName} environmentName #{environmentName} platformName #{platformName} >>/tmp/CloudrdbmsArtifact-get_backup_id_with_defaults.log`
    `echo the original values might be empty then the 4 values will be obtained from the oneops WORKORDER and will represent the current deployment >>/tmp/CloudrdbmsArtifact-get_backup_id_with_defaults.log`

    return self.get_backup_id(orgName, assemblyName, environmentName, platformName)
  end

  def self.parseGrastate(lines)
    txid = {}
    uuidline = lines.find { |line| line.include?("uuid:")}
    if uuidline == nil || uuidline.empty?
      return nil
    end
    txid[":uuid"] =  uuidline.split(/\s+/)[1].strip

    seqnoline = lines.find { |line| line.include?("seqno:")}
    if seqnoline == nil || seqnoline.empty?
      return nil
    end

    txid[":seqno"] =  seqnoline.split(/\s+/)[1].strip
    return txid
  end

  def self.getGrastate(node_ip)
    uri = URI.parse("http://#{node_ip}:8080/grastate")
    begin
      response = Net::HTTP.get_response(uri)
      if response != nil && response.code == "200" && response.body != nil
        lines = response.body.split(/\n+/)
        if lines != nil || lines.size > 0
          return parseGrastate(lines)
        end
      end
    rescue
      return nil
    end
    return nil
  end

  def self.getGrastateLocally()
    lines = IO.readlines('/var/lib/mysql/grastate.dat')
    parseGrastate lines
  rescue
    return nil
  end
end
