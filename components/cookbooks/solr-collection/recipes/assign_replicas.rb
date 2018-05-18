#
# Cookbook Name :: solr-collection
# Recipe :: assign_replicas.rb
#
# The recipe distributes the replicas of given shard across all clouds.
#

extend SolrCollection::Util
# Wire SolrCollection Util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCollection::Util)


require 'json'
require 'set'


#########################################################################
# This class distributes the replicas of a collection such that:
#    1) Replicas are distributed equally among all the clouds
#    2) Within a cloud, nodes with lesser number of cores have a higher
#       chance of getting a new replica
#########################################################################
class ReplicaAssigner

    include SolrCollection::Util

    # User inputs that wont change
    @collection_name
    @num_shards
    @replication_factor
    @max_shards_per_node
    @collections_for_node_sharing
    @port_num

    # Information from the pack and OneOps
    @cloud_to_compute_map
    @compute_to_cloud_map

    # Information deduced from above variables and Solr.
    # Some example entries possible in cloud_ip_core_map:
    #  ["dal5"]["ip1"] = 5
    #  ["dal5"]["ip2"] = 7
    @cloud_ip_core_map


    # Constructor for ReplicaAssigner
    def initialize (collection_name, num_shards, replication_factor, max_shards_per_node,
                    port_num, collections_for_node_sharing, cloud_to_compute_map)
        @collection_name              = collection_name
        @num_shards                   = num_shards
        @replication_factor           = replication_factor
        @max_shards_per_node          = max_shards_per_node
        @collections_for_node_sharing = collections_for_node_sharing
        @port_num                     = port_num
        @cloud_to_compute_map         = cloud_to_compute_map

        Chef::Log.info("collections_for_node_sharing: #{@collections_for_node_sharing}")

        @compute_to_cloud_map = Hash.new
        @cloud_to_compute_map.each { |cloud, computes|
            computes.each { |ip|
                @compute_to_cloud_map[ip] = cloud
            }
        }
    end


    # Special value to skip the node-sharing intelligence altogether
    # Useful for OOTest like scenarios
    def skip_node_sharing()
        if (@collections_for_node_sharing.length == 1 and @collections_for_node_sharing[0] == "NO_OP_BY_DEFAULT") then
            return true
        end
        return false
    end


    # Refreshes the number of cores per compute by calling CLUSTERSTATUS api
    def refresh_cluster_state()

        Chef::Log.info("Refreshing cluster state from Solr")

        # Reset cores-per-ip data structure
        @cloud_ip_core_map = Hash.new
        @cloud_to_compute_map.each { |cloud, computes|
            @cloud_ip_core_map[cloud] = Hash.new
            computes.each { |ip|
                @cloud_ip_core_map[cloud][ip] = 0
            }
        }
        @cloud_ip_core_map.each { |cloud, ip_core_map|
            Chef::Log.info("cloud_ip_core_map (#{@cloud_ip_core_map.size} clouds): Cloud #{cloud} has #{ip_core_map.size} IPs")
        }

        # Get cluster state from Solr
        params = {
            :action => "CLUSTERSTATUS"
        }
        clusterstatus_resp_obj = collection_api("localhost", @port_num.to_s, params)
        collections = clusterstatus_resp_obj["cluster"]["collections"]

        # Refresh our core-per-ip data structure
        shared_ips   = Set.new()
        unshared_ips = Set.new()
        own_ips      = Set.new()
        collections.each { |coll_name, coll_info|
            shards = coll_info["shards"]
            shards.each { |shard_name, shard_info|
                replicas = shard_info["replicas"]
                replicas.each { |replica_name, replica_info|
                    node_name = replica_info["node_name"]
                    ip = node_name.slice(0, node_name.index(':'))
                    cloud = @compute_to_cloud_map[ip]

                    @cloud_ip_core_map[cloud][ip] += 1
                    if (coll_name == @collection_name) then
                        own_ips.add(ip)
                    elsif (@collections_for_node_sharing.index(coll_name) != nil) then
                        shared_ips.add(ip)
                    else
                        unshared_ips.add(ip)
                    end
                }
            }
        }

        if (!skip_node_sharing()) then
            handle_shared_ips(shared_ips, unshared_ips, own_ips)
        end
    end


    ################################################################################################
    # There can be four kind of IPs
    #      shared_ips     :  IPs with cores from the shared collections
    #      unshared_ips   :  IPs with cores from un-shared collections
    #      own_ips        :  IPs with cores from the current collection
    #      zero_core_ips  :  IPs with no cores
    #
    # If shared_ips and zero_core_ips are both present, we want to ignore the zero_core_ips because
    # otherwise our minimum-core algorithm will select the zero_core_ips and the collection will start
    # using more IPs than the shared_ips
    #
    #
    # Why do we need to distinguish between the own_ips and shared_ips?
    #
    # If we count own_ips as part of shared_ips, then we loose the ability to differentiate when the
    # IPs are from other shared collections and when they are from the current collection executing as
    # the very first collection. In the latter case, we do not want to filter the zero_core_ips because
    # in the latter case, we want the collection to use its own_ips as well as zero_core_ips
    ################################################################################################
    def handle_shared_ips(shared_ips, unshared_ips, own_ips)

        Chef::Log.info("own_ips: #{own_ips.sort.to_json}, shared_ips: #{shared_ips.sort.to_json}")

        shared_and_unshared = shared_ips & unshared_ips
        if (shared_and_unshared.length > 0) then
            msg = "Following IPs host both shared and unshared collections: #{shared_and_unshared.sort.to_json}. "
            msg += "This is not a recommended way to configure your collection components. "
            msg += "We will count these IPs as shared and use them for this collection"
            Chef::Log.warn(msg)
            unshared_ips = unshared_ips - shared_and_unshared
        end

        Chef::Log.info("Making sure that #{unshared_ips.size} unshared_ips are removed")
        @cloud_ip_core_map.each { |cloud, ip_core_map|
            ip_core_map.delete_if { |ip, core_count|
                unshared_ips.include? ip
            }
        }
        @cloud_ip_core_map.delete_if { |cloud, ip_core_map|
            ip_core_map.size == 0
        }
        if (@cloud_ip_core_map.size == 0) then
            raise "cloud_ip_core_map is empty which means that no IPs are left for this collection. Please add more machines or share this collection with other collections"
        end

        if (shared_ips.length == 0) then
            # Only own_ips and zero_core_ips are present in cloud_ip_core_map
            # Just use all of them
            return
        end

        # Filter all the zero-core-IPs because we must use only the
        # shared_ips and the collection's own_ips
        @cloud_ip_core_map.each { |cloud, ip_core_map|
            ip_core_map.each { |ip, core_count|
                if (core_count == 0) then
                    Chef::Log.info("Omitting zero-core IP #{ip} since #{shared_ips.length} shared IPs are present.")
                    ip_core_map.delete(ip)
                end
            }
        }
    end


    # Example: if arr is [[1,2,3], [4,5,6], [7,8,9]]
    # Then it will return:
    #     [1, 4, 7] for n=0
    #     [2, 5, 8] for n=1
    #     [3, 6, 9] for n=2
    def select_nth_from_array_of_arrays(arr, n)
        return arr.transpose[n]
    end


    # Sort the clouds by the number of nodes and cores per cloud
    # Returned list keeps clouds with more nodes first.
    # If number of nodes is same, then clouds with lesser number of cores is put first.
    def sort_clouds()
        # 'to_a' converts the map to an array each of whose element is an array of 2 elements
        # first element of every sub-array is the map's key
        # second element of every sub-array is the map's value
        # And we sort this array-of-arrays by providing a comparator
        sorted_arr = @cloud_ip_core_map.to_a.sort do |a_cloud, b_cloud|
            a_name = a_cloud[0]
            b_name = b_cloud[0]
            a_ip_core_map = a_cloud[1]
            b_ip_core_map = b_cloud[1]

            a_node_count = a_ip_core_map.length
            b_node_count = b_ip_core_map.length

            if (a_node_count != b_node_count) then
                # cloud with more nodes comes first
                # i.e. descending sort on number of nodes in cloud
                b_node_count - a_node_count
            else
                a_core_count = a_ip_core_map.values.reduce(:+)
                b_core_count = b_ip_core_map.values.reduce(:+)
                # cloud with lesser cores comes first
                # i.e. ascending sort on number of cores in cloud
                a_core_count - b_core_count
            end
        end

        Chef::Log.info("Clouds sorted (descending order for number of nodes followed by ascending order for number of cores): #{sorted_arr.to_json}")
        return sorted_arr
    end


    # For the given shard, add a replica to the given IP
    def add_replica (shard_num, ip)
        shard_name = "shard"+"#{shard_num}"
        node_name = "#{ip}:#{@port_num}_solr"
        Chef::Log.info("Adding replica for #{shard_name} to #{node_name}")
        params = {
            :action => "ADDREPLICA",
            :collection => @collection_name,
            :shard => shard_name,
            :node => node_name
        }
        response = collection_api(ip, @port_num.to_s, params)
        Chef::Log.info("#{response.to_json}")
        return true
    end


    # For the given shard, add the given number of replicas to the specified cloud
    # All nodes in a cloud are sorted on the number of cores first so that nodes
    # with least number of cores get higher preference for replica addition
    # If number of replicas required is more than the number of nodes in the cloud,
    # an exception is thrown
    def add_replicas_to_cloud (shard_num, cloud, replicas_req)
        ip_core_map = @cloud_ip_core_map[cloud]
        if (ip_core_map.length < replicas_req) then
            raise "Cloud #{cloud} has only #{ip_core_map.length} available nodes which cannot accomodate #{replicas_req} replicas"
        end
        ips_sorted_by_core = ip_core_map.sort_by { |ip, core_count|  core_count}
        Chef::Log.info("IPs sorted by core: #{ips_sorted_by_core.to_json}")
        sorted_ips = select_nth_from_array_of_arrays(ips_sorted_by_core, 0)
        fail_count = 0
        for add_count in 0..replicas_req-1
            success = add_replica(shard_num, sorted_ips[add_count])
            if (!success) then
                add_count = add_count - 1
                fail_count = fail_count + 1
            end
            if (fail_count >= sorted_ips.length) then
                raise "Failed #{fail_count} times while adding #{replicas_req} replicas to cloud #{cloud} for shard #{shard_num}. Something appears to be wrong"
            end
        end
    end


    # Replicas need to be distributed equally among the clouds.
    # So num_replicas/num_clouds is the minimum number of replicas each cloud gets.
    # If there is a remainder from num_replicas/num_clouds, then that needs to be distributed equally too.
    # However, for these remainder replicas, we choose those clouds which have both the following:
    #    - Have lesser number of cores and
    #    - Have more nodes than the minimum number of replicas
    def determine_replicas_per_cloud ()

        sorted_cloud_ip_cores = sort_clouds()
        # sorted_cloud_ip_cores is an array, each of whose elements is an array with two elements - cloud_name and compute_to_cores map
        # Example: [["dal6", {"ip1"=>9, "ip2"=>6, "ip3"=>3, "ip4"=>2}], ["dal7", {"ip1"=>7, "ip2"=>6, "ip3"=>5, "ip4"=>4}]]

        num_clouds = sorted_cloud_ip_cores.length
        # Determine how many replicas to add per cloud
        # Cloud with lower count of cores gets priority provided it has sufficient nodes to place those replicas
        min_replicas_per_cloud = @replication_factor / num_clouds
        remainder_replicas = @replication_factor % num_clouds
        replicas_per_cloud = Hash.new
        # Loop over all the clouds to distribute the replicas left over as remainder of replication_factor / num_clouds
        # Due to filtering of IPs from un-shared collections, all clouds may not have equal number of nodes left.
        # So we will add an extra replica to the cloud only if it has an extra IP available for a replica. Otherwise
        # we move over to the next cloud
        for i in 0..num_clouds-1
            cloud_info  = sorted_cloud_ip_cores[i]
            cloud_name  = cloud_info[0]
            ip_core_map = cloud_info[1]
            extra_ips   = ip_core_map.length - min_replicas_per_cloud
            if (extra_ips > 0 && remainder_replicas > 0)
                replicas_per_cloud[cloud_name] = min_replicas_per_cloud + 1
                remainder_replicas -= 1
            else
                replicas_per_cloud[cloud_name] = min_replicas_per_cloud
            end
        end
        Chef::Log.info("Replicas per cloud calculation: #{replicas_per_cloud.to_json}")
        if (remainder_replicas > 0) then
            raise "Insufficient nodes to add all #{@replication_factor} replicas. #{sorted_cloud_ip_cores.to_json}"
        end
        return replicas_per_cloud
    end


    # main method that orchestrates the assignment of replicas
    def assign_replicas()

      for shard_num in 1..@num_shards

          refresh_cluster_state

          replicas_per_cloud = determine_replicas_per_cloud()

          # Finaly, add replicas to each cloud
          replicas_per_cloud.each { |cloud, replicas_req|
              Chef::Log.info("Adding #{replicas_req} replicas for shard #{shard_num} to cloud #{cloud}")
              add_replicas_to_cloud(shard_num, cloud, replicas_req)
          }

      end # for shard_num in ...

      show_summary()
    end # function


    # Shows a summary of the allocations done for all the collections
    def show_summary()
        cloud_ip_cores = Hash.new
        @cloud_to_compute_map.each { |cloud, computes|
            cloud_ip_cores[cloud] = Hash.new
            computes.each { |ip|
                cloud_ip_cores[cloud][ip] = []
            }
        }
        params = {
            :action => "CLUSTERSTATUS"
        }
        # Capture the detailed information about clouds, IPs and cores
        clusterstatus_resp_obj = collection_api("localhost", @port_num.to_s, params)
        collections = clusterstatus_resp_obj["cluster"]["collections"]
        collections.each { |coll_name, coll_info|
            shards = coll_info["shards"]
            shards.each { |shard_name, shard_info|
                replicas = shard_info["replicas"]
                replicas.each { |replica_name, replica_info|
                    node_name = replica_info["node_name"]
                    ip = node_name.slice(0, node_name.index(':'))
                    cloud = @compute_to_cloud_map[ip]
                    cloud_ip_cores[cloud][ip].push(coll_name + ", " + shard_name + ", " + replica_name)
                }
            }
        }
        # Capture a summary of cores per cloud
        cloud_numcores_map = Hash.new
        cloud_ip_cores.each { |cloud, cloud_info|
            core_per_cloud = 0
            cloud_info.each { |ip, cores|
                core_per_cloud = core_per_cloud + cores.length
            }
            cloud_numcores_map[cloud] = core_per_cloud
        }
        # Show both the summary and the detailed information as both are helpful for verification
        Chef::Log.info("Verify cloud_numcores_map: #{cloud_numcores_map.to_json}")
        Chef::Log.info("Verify cloud_ip_cores: #{cloud_ip_cores.to_json}")
    end # function

end

Chef::Log.info("*** Placing replicas for #{node['collection_name']} ***")

collections_for_node_sharing = JSON.parse(node['collections_for_node_sharing'])
collections_for_node_sharing.collect! {|collection_name| collection_name.strip }
collections_for_node_sharing = collections_for_node_sharing.reject {|coll| coll == node['collection_name']}

cloud_provider = CloudProvider.new(node)
cloud_or_zone_to_ip_map = cloud_provider.get_zone_to_compute_ip_map()
Chef::Log.info("cloud_or_zone_to_ip_map using cloud_provider= #{cloud_or_zone_to_ip_map.to_json}")
ra = ReplicaAssigner.new(node['collection_name'],
    node['num_shards'].to_i, node['replication_factor'].to_i, node['max_shards_per_node'].to_i,
    node['port_num'].to_i, collections_for_node_sharing, cloud_or_zone_to_ip_map)


ra.assign_replicas()
