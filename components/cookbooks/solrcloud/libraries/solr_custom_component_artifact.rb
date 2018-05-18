# SolrCustomComponent snapshot download recipe
#
# If the requested version is a snapshot, this recipe is used to find the latest
# snapshot version and download it.
#

require 'rexml/document'
require 'net/http'

class Chef::Recipe::SolrCustomComponentArtifact


  def self.get_file_name(descriptor)
    artifact_descriptor = descriptor.split(":")
    artifact_id = artifact_descriptor[1]
    artifact_version = artifact_descriptor[2]
    artifact_extension = artifact_descriptor.fetch(3, "jar")
    artifact_file = "#{artifact_id}-#{artifact_version}.#{artifact_extension}"
    return artifact_file
  end

  def self.get_artifact_url(descriptor, urlbase)
    # Descriptor is group:artifactId:version:extension
    artifact_descriptor = descriptor.split(':')
    artifact_urlbase = urlbase
    artifact_group = artifact_descriptor[0].gsub(/\./, "/")
    artifact_id = artifact_descriptor[1]
    artifact_version = artifact_descriptor[2]
    artifact_extension = artifact_descriptor.fetch(3, "jar")
    artifact_dir = "#{artifact_urlbase}/#{artifact_group}/#{artifact_id}/"

    # if (artifact_version =~ /LATEST/)
    #   artifact_version = get_latest_version(artifact_dir)
    # end

    artifact_dir = "#{artifact_urlbase}/#{artifact_group}/#{artifact_id}/#{artifact_version}"
    artifact_file = "#{artifact_id}-#{artifact_version}.#{artifact_extension}"

    if (artifact_version.to_s =~ /SNAPSHOT/)
      snapshot_name = ""
      Chef::Log.info("Looking for metadata at #{artifact_dir}")
      artifact_metadata = "#{artifact_dir}/maven-metadata.xml"
      xmlDoc = get_xml_doc(artifact_metadata)
      xmlDoc.elements.each('metadata/versioning/snapshotVersions/snapshotVersion') do |version|
        Chef::Log.debug("version: #{version}")
        if (version.get_text('extension') == artifact_extension)
          snapshot_name = version.get_text('value')
        end
      end
      artifact_url = "#{artifact_dir}/#{artifact_id}-#{snapshot_name}.#{artifact_extension}"
    else
      artifact_url = "#{artifact_dir}/#{artifact_file}"
    end
    return artifact_url, artifact_version
  end

  def self.get_latest_version(artifact_dir)
    latest_version = ""
    Chef::Log.info("Looking for metadata at #{artifact_dir}")
    artifact_metadata = "#{artifact_dir}/maven-metadata.xml"
    xmlDoc = get_xml_doc(artifact_metadata)
    xmlDoc.elements.each('metadata/versioning') do |version|
      Chef::Log.info("Version: #{version}")
      latest_version = version.get_text('latest')
    end
    if latest_version.empty?
      puts "***FAULT:FATAL= Latest version not found"
      Chef::Log.error("Latest Version Not Found In :\n#{metadata}")
    else
      return latest_version
    end
  end

  def self.get_xml_doc(artifact_metadata)
    begin
      url = URI(artifact_metadata)
      metadata = Net::HTTP.get(url)
      xmlDoc = REXML::Document.new(metadata)
    rescue REXML::ParseException => e
      puts "***FAULT:FATAL= URL does not exist: #{url} Exception: #{e.message}"
      Chef::Log.error("URL does not exist: #{url} Exception: #{e.message}")
    end
    return xmlDoc
  end
end