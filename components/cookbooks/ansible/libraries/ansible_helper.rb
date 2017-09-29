require 'psych'
require 'tempfile'

def parse_url(content = nil, _multi = true)
  unless content.nil?
    begin
      yml = Psych.load(content)

      if yml.is_a?(String)
        parsed_urls = []
        begin
          content.each_line do |line|
            begin
              uri = URI.split(URI.escape(line))
              scheme = uri[0]
              user_info = uri[1].nil? ? '' : "#{uri[1]}@"
              host = uri[2]
              port = uri[3].nil? ? '' : ":#{uri[3]}"
              path = uri[5].nil? ? '' : uri[5]
              query = uri[7].nil? ? '' : URI.decode(uri[7])

              queries = query.split('&')

              query_hash = {}

              queries.each do |q|
                (k, v) = q.split('=')
                query_hash[k] = v
              end

              query_hash['scm'] = 'git' if path.end_with? '.git'

              url = "#{scheme}://#{user_info}#{host}#{port}#{path}"

              parsed_urls.push(url: url, query: query_hash)

              return parsed_urls
            rescue URI::InvalidURIError => e
              puts "**FAULT:FATAL=You've provided invalid URL: #{line}"
              Chef::Log.fatal!("Invalid URI parsing for #{line}")
            end
          end
        end
      elsif yml.is_a?(Array)
        return content
      end
    rescue Psych::SyntaxError => e
      puts '***FAULT:FATAL=Your content is neither a valid YAML or a valid URL'
    end
  end
end

def run_playbook(playbook = nil)
  playbook_dir = Dir::Tmpname.make_tmpname "#{Chef::Config['file_cache_path']}/ansible_playbook", nil

  process_url(playbook, playbook_dir) if playbook.is_a?(Array)
end

def process_url(playbook = nil, playbook_dir = nil)
  directory playbook_dir do
    recursive true
  end.run_action(:create)

  playbook_file = "#{playbook_dir}/playbook.yml"

  if playbook.is_a?(Array)
    if playbook[0][:query].key?('scm') && playbook[0][:query]['scm'].eql?('git')
      Chef::Log.info('Installing role from git repo')
      revision = playbook[0][:query].key?('tag') ? playbook[0][:query]['tag'] : 'master'

      ruby_block 'clone git repository' do
        block do
          Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)

          shell = Mixlib::ShellOut.new("git clone -b '#{revision}' #{playbook[0][:url]} . ",
                                       live_stream: Chef::Log.logger, cwd: playbook_dir)
          shell.run_command
          shell.error!
        end
      end

      playbook_file = playbook[0][:query].key?('path') ? "#{playbook_dir}/#{playbook[0][:query]['path']}" : "#{playbook_dir}/playbook.yml"
    elsif playbook[0][:url].end_with?('.tar.gz')
      shell = Mixlib::ShellOut.new("curl -L \"#{playbook[0][:url]}\" | tar zxv --strip 1",
                                   live_stream: Chef::Log.logger, cwd: playbook_dir)
      shell.run_command
      shell.error!
      playbook_file = playbook[0][:query].key?('path') ? "#{playbook_dir}/#{playbook[0][:query]['path']}" : "#{playbook_dir}/playbook.yml"
    end

    ruby_block 'Install role ansible-galaxy' do
      block do
        Chef::Log.info("Runninag ansible-galaxy install -r #{playbook_dir}/requirements.yml")
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        shell = Mixlib::ShellOut.new("ansible-galaxy install -r #{playbook_dir}/requirements.yml",
                                     live_stream: Chef::Log.logger, cwd: playbook_dir)
        shell.run_command
        shell.error!
      end
      only_if { ::File.exist?("#{playbook_dir}/requirements.yml") }
    end

  else
    # inline yml
    file playbook_file do
      content node['workorder']['rfcCi']['ciAttributes']['playbook']
    end
  end

  # copy a local version of load_role to workspace
  execute "cp /etc/ansible/script/load_role.py #{playbook_dir}/load_role.py"

  ruby_block 'install missing role' do
    block do
      # run the role loader
      Chef::Log.info("Running: #{node['python']['binary']} #{playbook_dir}/load_role.py  -f #{playbook_file}")
      shell = Mixlib::ShellOut.new("#{node['python']['binary']} #{playbook_dir}/load_role.py  -f #{playbook_file}", live_stream: Chef::Log.logger)
      shell.run_command
      shell.error!
    end
  end

  ruby_block 'run playbook' do
    block do
      # run the role loader
      Chef::Log.info("Running: ansible-playbook #{playbook_file}")
      shell = Mixlib::ShellOut.new("ansible-playbook #{playbook_file}", live_stream: Chef::Log.logger)
      shell.run_command
      shell.error!
    end
  end
end
