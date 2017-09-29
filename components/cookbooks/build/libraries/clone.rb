require "chef/resource/git"
#overriding clone method so that branches other than master can also be pulled if mentioned in revision
class Chef::Provider::Git
  def clone

    Chef::Log.info "calling overridden method"
    converge_by("clone from #{@new_resource.repository} into #{@new_resource.destination}") do
      remote = @new_resource.remote

      args = []
      args << "-b #{@new_resource.revision}" unless @new_resource.revision == 'master'
      args << "-o #{remote}" unless remote == 'origin'
      args << "--depth #{@new_resource.depth}" if @new_resource.depth

      Chef::Log.info "#{@new_resource} cloning repo #{@new_resource.repository} to #{@new_resource.destination}"

      clone_cmd = "git clone #{args.join(' ')} \"#{@new_resource.repository}\" \"#{@new_resource.destination}\""
      shell_out!(clone_cmd, run_options)
    end

  end
end