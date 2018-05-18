require 'open-uri'
require 'rexml/document'

include REXML

class Chef::Recipe::MavenHelper
  def self.get_info (qualifier)
          parts = qualifier.split(":")
          return {'root' => "/#{parts[0].gsub('.', '/')}/#{parts[1]}",
            'path' => "/#{parts[0].gsub('.', '/')}/#{parts[1]}/#{parts[2]}",
                  'groupId' => parts[0],
                  'artifactId' => parts[1],
                  'version' => parts[2],
                  'type' => parts[3] }
  end

  def self.parse_attributes (qualifier)
          parts = qualifier.split(":")
          return {'artifactId' => parts[0],
                  'version' => parts[1],
                  'type' => parts[2] }
  end

  def self.get_latest_version (server, qualifier)
    Chef::Log.debug "Getting latest version"

    artifact_info = get_info(qualifier)
    metadata_doc = "#{server}#{artifact_info['root']}/maven-metadata.xml"

    Chef::Log.info("Reading from: #{metadata_doc}")

    meta_content = open(metadata_doc) { |f| f.read }

    xmlDoc =  REXML::Document.new(meta_content)
    latest = xmlDoc.root.get_text('versioning/latest')
    return latest
  end

  def self.get_all_versions (server, qualifier)
    Chef::Log.debug "Getting all versions"
    artifact_info = get_info(qualifier)
    maven_metadata = "#{server}#{artifact_info['root']}/maven-metadata.xml"
    meta_content = open(maven_metadata) { |f| f.read }
    xmlDoc =  REXML::Document.new(meta_content)
    versions = []
    xmlDoc.root.elements.each('versioning/versions/version') { |e|
      versions.push(e.text)
    }
    return versions
  end

  #Depending on the input, create a list of URLs to download
  def self.get_download_urls (server, qualifier)
    artifact_info = parse_attributes(qualifier)
    artifact_version = artifact_info['version']
    puts "Current artifact version: #{artifact_version}"

    downloads = []
    c_path = "#{server}#{artifact_info['version']}/#{artifact_info['artifactId']}-#{artifact_info['version']}.tgz"
    puts "Retreiving artifact: #{c_path}"
    downloads.push(c_path)

    #Read the metadata XML File from maven
    return downloads
  end

  # Download a URL, and write file
  def self.download(url, target_directory)
    Thread.new do
      thread = Thread.current
      body = thread[:body] = []
            file_name = "#{target_directory}/#{url.split('/')[-1]}"
      puts "Downloading: #{url}\nTo: #{file_name}"
      url = URI.parse url

      Net::HTTP.new(url.host, url.port).request_get(url.path) do |response|
                length = thread[:length] = response['Content-Length'].to_i
                     out = open(file_name, 'wb')
                response.read_body do |fragment|
                        out.write(fragment)
                  body << fragment
                  thread[:done] = (thread[:done] || 0) + fragment.length
                  thread[:progress] = thread[:done].quo(fragment.length) * 100
                end
      end
    end
  end

  def self.download_with_status(url, target_directory)
          thread = download(url, target_directory)
          puts "%.2f%%" % thread[:progress].to_f until thread.join 1
  end
end
