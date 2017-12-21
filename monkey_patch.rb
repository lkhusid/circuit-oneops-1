require 'fileutils'

=begin

Address hashie warning spam.

https://github.com/berkshelf/berkshelf/pull/1668

=end
require "hashie"
require "hashie/logger"
Hashie.logger = Logger.new(nil)

=begin 

Expose WORKORDER environment variable for kitchen/verifier/busser

=end

require "kitchen"
require "kitchen/version"

module Kitchen
  class Instance
    def converge_action
      if !verifier[:transport].eql?("local")
        banner "Converging #{to_str}..."

        elapsed = action(:converge) do |state|
          if legacy_ssh_base_driver?
            legacy_ssh_base_converge(state)
          else
            provisioner.call(state)
          end
        end
        info("Finished converging #{to_str} #{Util.duration(elapsed.real)}.")
      else
        banner "Skipping converging step"
      end
      self
    end 

    def legacy_ssh_base_setup(state)
      warn("Running legacy setup for '#{driver.name}' Driver")
      # TODO: Document upgrade path and provide link
      # warn("Driver authors: please read http://example.com for more details.")
      if !verifier[:transport].eql?("local")
        driver.setup(state)
      else
        banner "Skipping #{driver.name}  setup step"
      end
    end
  end
end 


module Kitchen
  module Driver
    class Proxy < Kitchen::Driver::SSHBase
      def reset_instance(state)
        if config[:transport] && config[:transport].eql?("local")
          info("Transport mode #{config[:transport]} so no-ops")
        else
          if cmd = config[:reset_command]
            info("Resetting instance state with command: #{cmd}")
            ssh(build_ssh_args(state), cmd)
          end
        end
      end
    end
  end
end

require "kitchen/verifier/busser"

module Kitchen
  module Verifier
    class Busser

      def busser_env
        root = config[:sandbox] ? config[:sandbox] : config[:root_path] 
        busser_root = config[:busser_root] ? config[:busser_root] : root
        gem_home = config[:gem_home] ? config[:gem_home] : remote_path_join(root, "gems")
        gem_path = config[:gem_path] ? config[:gem_path] : nil
        gem_cache = config[:gem_cache] ? config[:gem_cache] : remote_path_join(root, "cache")

        array_env_var = [
          shell_env_var("BUSSER_ROOT", busser_root),
          shell_env_var("GEM_HOME", gem_home),
          shell_env_var("GEM_CACHE", gem_cache),
          shell_env_var("WORKORDER", ENV['WORKORDER'])
        ]
        array_env_var.push(shell_env_var("GEM_PATH", gem_path)) if gem_path

        array_env_var.join("\n")
          .tap { |str| str.insert(0, reload_ps1_path) if windows_os? }
      end

      def run_command
        return if local_suite_files.empty?
        if config[:transport] && config[:transport].eql?("local")
          config[:sandbox] = sandbox_path
        end

        if config[:sudo] && config[:sudo].eql?("false")
          cmd = config[:busser_bin].dup
                                       .tap { |str| str.insert(0, "& ") if powershell_shell? }
        else
          cmd = sudo(config[:busser_bin]).dup
                                       .tap { |str| str.insert(0, "& ") if powershell_shell? }
        end

        prefix_command(<<-CMD).chomp
          #{busser_env} ; #{cmd} test #{plugins.join(" ").gsub!("busser-", "")}
        CMD
      end
    end
  end
end

=begin
  
Monkey patch ridley/chef/cookbook/metadata to safeguard
in scenario where name is not lowercase in metadata. 

=end
require "ridley"

module Ridley::Chef
  class Cookbook
    class Metadata
      def name(arg = nil)
        arg = arg.nil? ? nil : arg.downcase
        set_or_return(
          :name,
          arg,
          :kind_of => [ String ]
        )
      end
    end
  end
end

=begin 

Ensure that while copying sandbox it will have
the correct structure with lowercase.

=end

module Kitchen
  module Provisioner
    module Chef
      class CommonSandbox
        def cp_this_cookbook
          info("Preparing current project directory as a cookbook")
          debug("Using metadata.rb from #{metadata_rb}")

          cb_name = MetadataChopper.extract(metadata_rb).first || raise(UserError,
                                                                        "The metadata.rb does not define the 'name' key." \
                                                                          " Please add: `name '<cookbook_name>'` to metadata.rb and retry")

          cb_name.downcase!

          cb_path = File.join(tmpbooks_dir, cb_name)

          glob = Util.list_directory(config[:kitchen_root])

          FileUtils.mkdir_p(cb_path)
          FileUtils.cp_r(glob, cb_path)
        end
      end
    end
  end
end

=begin
  
Modify existing chef_solo to run extra command before
actual execution of chef_solo.

=end

require "kitchen/provisioner/chef_base"

module Kitchen
  module Provisioner
    class ChefSolo < ChefBase
      def prepare_script
        info("Preparing script")

        if config[:script]
          debug("Using script from #{config[:script]}")
          FileUtils.cp_r(config[:script], sandbox_path)
        else
          prepare_stubbed_script
        end

        FileUtils.chmod(0755,
          File.join(sandbox_path, File.basename(config[:script])))
      end
 
      # Create a minimal, no-op script in the sandbox path.
      #
      # @api private
      def prepare_stubbed_script
        base = powershell_shell? ? "bootstrap.ps1" : "bootstrap.sh"
        config[:script] = File.join(sandbox_path, base)
        info("#{File.basename(config[:script])} not found " \
          "so Kitchen will run a stubbed script. Is this intended?")
        File.open(config[:script], "wb") do |file|
          if powershell_shell?
            file.write(%{Write-Host "NO BOOTSTRAP SCRIPT PRESENT`n"\n})
          else
            file.write(%{#!/bin/sh\necho "NO BOOTSTRAP SCRIPT PRESENT"\n})
          end
        end
      end

      def run_command
        config[:log_level] = "info" if !modern? && config[:log_level] = "auto"
        cmd = sudo(config[:chef_solo_path]).dup
                                           .tap { |str| str.insert(0, "& ") if powershell_shell? }

        ## begin of bootstrap
        # added shell provision to run before converge
        script = remote_path_join(
          config[:root_path], File.basename(config[:script])
        )

        code = powershell_shell? ? %{& "#{script}"} : sudo(script)
        ## end of bootstrap 

        chef_cmd("#{code} ; #{cmd}")
      end

      def create_sandbox
        super
        prepare_config_rb
        prepare_script
      end
    end
  end
end
