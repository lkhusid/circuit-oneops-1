require 'json'
require 'fileutils'

module SolrAuth

  module AuthUtils

    @@secrete_dir = "/app/solr_secrets"
    @@secrete_file_name = "solr_secrete_file"

    def self.auth_enabled?
      return File.file?("#{@@secrete_dir}/#{@@secrete_file_name}")
    end

    def self.get_solr_admin_credentials()
      file = File.read("#{@@secrete_dir}/#{@@secrete_file_name}")
      secrete_file = JSON.parse(file)
      return secrete_file['admin_user']
    end

    def self.get_solr_user_credentials(user)
      file = File.read("#{@@secrete_dir}/#{@@secrete_file_name}")
      secrete_file = JSON.parse(file)
      return secrete_file[user]
    end

    def self.add_credentials_if_required(req)

      unless !SolrAuth::AuthUtils.auth_enabled?
        admin_creds = SolrAuth::AuthUtils.get_solr_admin_credentials
        req.basic_auth(admin_creds['username'], admin_creds['password'])
      end

    end

  end

end

class AuthConfigurer

  include FileUtils

  @@secrete_dir = "/app/solr_secrets"
  @@secrete_file_name = "solr_secrete_file"

  # The solr_install_dir argument is expected to be "/app/solr7 or /app/solr6", the directory under which the solr is installed on the compute
  #
  def initialize(host, port, solr_admin_user, solr_admin_password, solr_app_user, solr_password, zk_classpath, zk_host, solr_install_dir)
    @host = host
    @port = port
    @solr_admin_user = solr_admin_user
    @solr_admin_password = solr_admin_password
    @solr_app_user = solr_app_user
    @solr_password = solr_password
    @zk_classpath = zk_classpath
    @zk_host = zk_host
    @solr_install_dir = solr_install_dir
  end

  def enable_authentication()

    puts "Enabling Authentication for Solr"
    authentication_uri = "/solr/admin/authentication"
    authorization_uri = "/solr/admin/authorization"

    upload_security_json_with_no_credentials()

    add_admin_user(authentication_uri)
    add_admin_user_to_role(authorization_uri, ["admin"])
    add_permissions_to_role(authorization_uri)

    # add solr app user
    add_user(authentication_uri, @solr_app_user, @solr_password)
    add_user_to_role(authorization_uri, @solr_app_user, ["app"])

  end

  def disable_authentication()
    puts "Disabling authentication for Solr"
    upload_security_json_with_no_credentials()
  end

  # This method creates a file which contains the Solr user credentials
  # for the recipes and monitor scripts to use
  # We also store the app user credentials although we do not need it and do not use it for our purposes
  # This could be useful further down the line to migrate to secrete-client OneOps component

  def create_secrete_file()

    payload = {
        "admin_user" => {
            "username" => @solr_admin_user,
            "password" => @solr_admin_password,
        },
        #TODO should the key be "app_user"
        @solr_app_user => {
            "username" => @solr_app_user,
            "password" => @solr_password
        }
    }

    # open and write to a file with ruby

    FileUtils.mkdir_p(@@secrete_dir, :mode => 0700)
    FileUtils.chown('app', 'app', @@secrete_dir)

    file_name = "#{@@secrete_dir}/#{@@secrete_file_name}"

    puts "Creating the Solr secrete file: #{file_name}"

    open("#{file_name}", 'w') { |f|
      f.puts(payload.to_json)
    }

    FileUtils.chown('app', 'app', "#{file_name}")

  end

  def delete_secret_file()
    file_name = "#{@@secrete_dir}/#{@@secrete_file_name}"
    puts "Deleting the Solr secrete file: #{file_name}"
    File.delete(file_name)  if File.exist?(file_name)
  end


  # This method uploads the security.json file content to the zookeeper. It just uploads
  # the default template file with no users, roles, permissions added to it
  def upload_security_json_with_no_credentials()

    payload = {
        "authentication" => {
            "class" => "solr.BasicAuthPlugin"
        },
        "authorization" => {
            "class" => "solr.RuleBasedAuthorizationPlugin"
        }
    }


    cmd = "#{@solr_install_dir}/server/scripts/cloud-scripts/zkcli.sh -zkhost #{@zk_host} -cmd put  /security.json   \'#{payload.to_json}\'  2>&1"
    puts "Uploading the basic template security.json file using cmd #{cmd}"

    result = `#{cmd}`

    if $? != 0
      puts "***FAULT:FATAL=#{result}"
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end

  end

  def add_admin_user(url)

    puts "Adding the Solr admin user: #{@solr_admin_user}"
    payload = {
        "set-user" => {
            @solr_admin_user => @solr_admin_password
        }
    }

    Solr::RestClient.post(@host, @port, url, payload.to_json)

  end

  def add_user(url, user, password)
    puts "Adding the Solr app user: #{user}"
    payload = {
        "set-user" => {
            user => password
        }
    }

    Solr::RestClient.post(@host, @port, url, payload.to_json, @solr_admin_user, @solr_admin_password)

  end



  def add_admin_user_to_role(url, roles)
    puts "Adding Solr admin user #{@solr_admin_user} to roles: #{roles}"
    payload = {
        "set-user-role" => {
            @solr_admin_user => roles
        }
    }
    Solr::RestClient.post(@host, @port, url, payload.to_json)

  end

  def add_user_to_role(url, user, roles)
    puts "Adding Solr app user #{user} to #{roles}"
    payload = {
        "set-user-role" => {
            user => roles
        }
    }
    Solr::RestClient.post(@host, @port, url, payload.to_json, @solr_admin_user, @solr_admin_password)

  end

  def add_permissions_to_role(url)
    puts "Adding permissions to the admin and app roles"
    payload = build_perms_payload()
    Solr::RestClient.post(@host, @port, url, payload)

  end

  # This method builds the payload for uploading permissions assigned to the
  # to the admin and app roles. The admin role will be assigned to the solr admin user and the app role will be assigned to the solr app user
  # The Solr app user will be able to perform all the admin/regular read operations on the user, he will also be able insert/update/delete
  # documents from the solr

  def build_perms_payload()
    permissions = [
        {"name" => "update", "role" => ["admin","app"]},
        {"name" => "read", "role" => ["admin","app"]},
        {"name" => "schema-read", "role" => ["admin", "app"]},
        {"name" => "config-read", "role" =>["admin","app"]},
        {"name" => "collection-admin-read", "role" => ["admin","app"]},
        {"name" => "config-admin-read", "role" => ["admin","app"]},
        {"name" =>  "security-edit", "role" => "admin"},
        {"name" =>  "security-read", "role" => "admin"},
        {"name" => "schema-edit", "role" => "admin"},
        {"name" => "config-edit", "role" => "admin"},
        {"name" =>  "collection-admin-edit", "role" => "admin"},
        {"name" => "config-admin-edit", "role" => "admin"}

    ]

    perm_elems = Array.new
    key = "\"set-permission\""
    permissions.each do |perm|
      perm_elems.push(key + ":" + perm.to_json)
    end

    payload = perm_elems.join(",\n")

    payload = "{#{payload}}"

    return payload

  end

end

