execute "date > /opt/cassandra/nodetool.out"
results = "/opt/cassandra/nodetool.out"

args = ::JSON.parse(node.workorder.arglist)
v_custom_args = args["CustomNodetoolArg"]
v_custom_args = v_custom_args.to_s

## REMOVE LEADING SPACES
v_custom_args = v_custom_args.gsub(/^\s/,'')
## CHECK FOR EMPTY or INVALID ARGS
if v_custom_args !~ /\w/
    Chef::Log.error("NO ARGS FOUND>>>>>> " + v_custom_args)
    v_custom_args = "info"
end
if v_custom_args.eql? ''
    Chef::Log.error("INVALID ARG>>>>> " + v_custom_args)
    v_custom_args = "info"
end

Chef::Log.info("CHECKING FOR HOST Option Usage")
### FAIL IMMEDIATELY ON HOST OPTION ####
if v_custom_args =~ /^\-h\s*/i
    Chef::Log.error("HOST OPTION NOT SUPPORTED " + v_custom_args)
        exit 1
elsif v_custom_args =~ /^\-host\s*/i
    Chef::Log.error("HOST OPTION NOT SUPPORTED " + v_custom_args)
        exit 1
end

### CHECK FOR STATUS ###
if v_custom_args =~ /stat/i
    puts "using nodetool status"
    check_args = 0
elsif v_custom_args =~ /info/i
    puts "using nodetool info"
    check_args = 0
else
    check_args = 1
end


## Compare test against SUDO
action_user = node.workorder.createdBy
action_user = action_user.to_s
Chef::Log.info("ACTION USER:  " + action_user)
`ls /etc/sudoers.d | sort> /tmp/sudo.out`
test_for_access = `grep #{action_user} /tmp/sudo.out |  wc -l`
test_for_access = test_for_access.to_i

### grep for any instances of nodetool repair
check_for_repair = "ps -eaf | grep nodetool | grep repair | grep -v grep | grep -v customnodetool | wc -l"
check_repair = `#{check_for_repair}`
puts "repair #{check_repair}"
check_for_nonstats = "ps -eaf | grep nodetool | grep -v repair| grep -v grep | grep -v customnodetool | grep -v stat | wc -l"
check_nonstats = `#{check_for_nonstats}`
puts "nonstats #{check_nonstats}"
check_tot = check_repair.to_i + check_nonstats.to_i + check_args.to_i
puts "NUMBER OF ALREADY RUNNING NODETOOL OPERATIONS #{check_tot}"
unless check_tot.to_i > 1
    if test_for_access > 0
        Chef::Log.info("USER IS ALLOWED FOR LEVEL 2")
        Chef::Log.info("EXECUTE NODETOOL COMMAND")
        Chef::Log.info("NODETOOL ARGUMENT----> " + v_custom_args)
        execute "/opt/cassandra/bin/nodetool #{v_custom_args} &> /opt/cassandra/nodetool.out"
    else
        Chef::Log.info("USER IS ONLY ALLOWED FOR LEVEL 1")
        ### CHECK AGAINST blocknodetool #####
        template "/opt/cassandra/blocknodetool" do
          source "blocknodetool.erb"
          owner 'cassandra'
          group 'cassandra'
          mode '0644'
        end
        blocknodetool = "/opt/cassandra/blocknodetool"

        ## split apart argument ##
        custom_args_array = v_custom_args.split(" ")
        custom_args_array.each do |x|
                v_test = `grep #{x} #{blocknodetool} | wc -l`
                v_test_i = v_test.to_i
                if v_test_i > 0
                Chef::Log.error("THIS NODETOOL OPERATION IS NOT ALLOWED >>> " + v_custom_args)
                        exit 1
            end
        end

        ## CHECK FOR NODETOOL REPAIR ##
        Chef::Log.info("EXECUTE NODETOOL COMMAND")
        if v_custom_args =~ /repair/i
            Chef::Log.error("ONLY REPAIR -PR IS SUPPORTED")
            execute "/opt/cassandra/bin/nodetool repair -pr &> /opt/cassandra/nodetool.out"
        else
            Chef::Log.info("NODETOOL ARGUMENT----> " + v_custom_args)
            execute "/opt/cassandra/bin/nodetool #{v_custom_args} &> /opt/cassandra/nodetool.out"
        end
    end
else
    Chef::Log.error("NEED TO WAIT UNTIL RUNNING NODETOOLS OPERATIONS ARE COMPLETE")
    exit 1
end

ruby_block "=======NODETOOL OUTPUT========" do
    only_if { ::File.exists?(results) }
    block do
        print "\n"
        File.open(results).each do |line|
            print line
        end
    end
end