require 'json'

computes = [
    {"ciName"=>"compute-34951920-1","ciAttributes"=>{"private_ip"=>"34951920-1_11","zone"=>"{\"fault_domain\":1,\"update_domain\":1}"}},
    {"ciName"=>"compute-34951920-2","ciAttributes"=>{"private_ip"=>"34951920-2_12","zone"=>"{\"fault_domain\":1,\"update_domain\":2}"}},
    {"ciName"=>"compute-34951920-3","ciAttributes"=>{"private_ip"=>"34951920-3_13","zone"=>"{\"fault_domain\":1,\"update_domain\":3}"}},
    {"ciName"=>"compute-34951920-4","ciAttributes"=>{"private_ip"=>"34951920-4_11","zone"=>"{\"fault_domain\":1,\"update_domain\":1}"}},
    {"ciName"=>"compute-34951920-5","ciAttributes"=>{"private_ip"=>"34951920-5_12","zone"=>"{\"fault_domain\":1,\"update_domain\":2}"}},
    {"ciName"=>"compute-34951921-1","ciAttributes"=>{"private_ip"=>"34951921-1_21","zone"=>"{\"fault_domain\":2,\"update_domain\":1}"}},
    {"ciName"=>"compute-34951921-2","ciAttributes"=>{"private_ip"=>"34951921-2_22","zone"=>"{\"fault_domain\":2,\"update_domain\":2}"}},
    {"ciName"=>"compute-34951921-3","ciAttributes"=>{"private_ip"=>"34951921-3_23","zone"=>"{\"fault_domain\":2,\"update_domain\":3}"}},
    {"ciName"=>"compute-34951921-4","ciAttributes"=>{"private_ip"=>"34951921-4_21","zone"=>"{\"fault_domain\":2,\"update_domain\":1}"}}
]

collections_payload =
        {
            "collection1"=>{
              "shards"=>{
                  "shard1"=>{"replicas"=>{"core_node0"=>{"node_name"=>"34951920-1_11:8983_solr"},
                                          "core_node1"=>{"node_name"=>"34951920-2_12:8983_solr"},
                                          "core_node2"=>{"node_name"=>"34951921-1_21:8983_solr"}
                                         }},
                  "shard2"=>{"replicas"=>{"core_node3"=>{"node_name"=>"34951920-3_13:8983_solr"},
                                          "core_node4"=>{"node_name"=>"34951920-4_11:8983_solr"},
                                          "core_node5"=>{"node_name"=>"34951921-2_22:8983_solr"}
                                         }
                            }
                  }
                },
            "collection2"=>{
                "shards"=>{
                    "shard1"=>{"replicas"=>{"core_node0"=>{"node_name"=>"34951920-1_11:8983_solr"},
                                            "core_node1"=>{"node_name"=>"34951920-2_12:8983_solr"},
                                            "core_node2"=>{"node_name"=>"34951921-1_21:8983_solr"}
                    }},
                    "shard2"=>{"replicas"=>{"core_node3"=>{"node_name"=>"34951920-3_13:8983_solr"},
                                            "core_node4"=>{"node_name"=>"34951920-4_11:8983_solr"},
                                            "core_node5"=>{"node_name"=>"34951921-2_22:8983_solr"}
                    }
                    }
                }
            }
        }

uber_item_computes = [
                        {"ciName"=>"compute-240588803-1","ciAttributes"=>{"private_ip"=>"X.X.190.78","zone"=>"{\"fault_domain\":1,\"update_domain\":1}"}},
                        {"ciName"=>"compute-240588803-2","ciAttributes"=>{"private_ip"=>"X.X.190.204","zone"=>"{\"fault_domain\":2,\"update_domain\":2}"}},
                        {"ciName"=>"compute-240588803-3","ciAttributes"=>{"private_ip"=>"X.X.204.51","zone"=>"{\"fault_domain\":3,\"update_domain\":3}"}},
                        {"ciName"=>"compute-240588803-4","ciAttributes"=>{"private_ip"=>"X.X.199.55","zone"=>"{\"fault_domain\":1,\"update_domain\":4}"}},
                        {"ciName"=>"compute-240588803-5","ciAttributes"=>{"private_ip"=>"X.X.185.114","zone"=>"{\"fault_domain\":2,\"update_domain\":5}"}},
                        {"ciName"=>"compute-240588803-6","ciAttributes"=>{"private_ip"=>"X.X.134.158","zone"=>"{\"fault_domain\":3,\"update_domain\":6}"}},
                        {"ciName"=>"compute-240588803-7","ciAttributes"=>{"private_ip"=>"X.X.201.164","zone"=>"{\"fault_domain\":1,\"update_domain\":7}"}},
                        {"ciName"=>"compute-240588803-8","ciAttributes"=>{"private_ip"=>"X.X.194.173","zone"=>"{\"fault_domain\":2,\"update_domain\":8}"}},
                        {"ciName"=>"compute-240588803-9","ciAttributes"=>{"private_ip"=>"X.X.194.241","zone"=>"{\"fault_domain\":3,\"update_domain\":9}"}},
                        {"ciName"=>"compute-240588803-10","ciAttributes"=>{"private_ip"=>"X.X.194.59","zone"=>"{\"fault_domain\":1,\"update_domain\":10}"}},
                        {"ciName"=>"compute-240588815-1","ciAttributes"=>{"private_ip"=>"X.X.231.116","zone"=>"{\"fault_domain\":2,\"update_domain\":11}"}},
                        {"ciName"=>"compute-240588815-2","ciAttributes"=>{"private_ip"=>"X.X.211.144","zone"=>"{\"fault_domain\":3,\"update_domain\":12}"}},
                        {"ciName"=>"compute-240588815-3","ciAttributes"=>{"private_ip"=>"X.X.217.135","zone"=>"{\"fault_domain\":1,\"update_domain\":13}"}},
                        {"ciName"=>"compute-240588815-4","ciAttributes"=>{"private_ip"=>"X.X.215.42","zone"=>"{\"fault_domain\":2,\"update_domain\":14}"}},
                        {"ciName"=>"compute-240588815-5","ciAttributes"=>{"private_ip"=>"X.X.228.16","zone"=>"{\"fault_domain\":3,\"update_domain\":15}"}},
                        {"ciName"=>"compute-240588815-6","ciAttributes"=>{"private_ip"=>"X.X.215.7","zone"=>"{\"fault_domain\":1,\"update_domain\":16}"}},
                        {"ciName"=>"compute-240588815-7","ciAttributes"=>{"private_ip"=>"X.X.211.129","zone"=>"{\"fault_domain\":2,\"update_domain\":17}"}},
                        {"ciName"=>"compute-240588815-8","ciAttributes"=>{"private_ip"=>"X.X.221.39","zone"=>"{\"fault_domain\":3,\"update_domain\":18}"}},
                        {"ciName"=>"compute-240588815-9","ciAttributes"=>{"private_ip"=>"X.X.231.36","zone"=>"{\"fault_domain\":1,\"update_domain\":19}"}},
                        {"ciName"=>"compute-240588815-10","ciAttributes"=>{"private_ip"=>"X.X.142.170","zone"=>"{\"fault_domain\":2,\"update_domain\":20}"}},
                        {"ciName"=>"compute-240588809-1","ciAttributes"=>{"private_ip"=>"X.X.155.77","zone"=>"{\"fault_domain\":3,\"update_domain\":1}"}},
                        {"ciName"=>"compute-240588809-2","ciAttributes"=>{"private_ip"=>"X.X.237.86","zone"=>"{\"fault_domain\":1,\"update_domain\":2}"}},
                        {"ciName"=>"compute-240588809-3","ciAttributes"=>{"private_ip"=>"X.X.249.142","zone"=>"{\"fault_domain\":2,\"update_domain\":3}"}},
                        {"ciName"=>"compute-240588809-4","ciAttributes"=>{"private_ip"=>"X.X.234.125","zone"=>"{\"fault_domain\":3,\"update_domain\":4}"}},
                        {"ciName"=>"compute-240588809-5","ciAttributes"=>{"private_ip"=>"X.X.242.48","zone"=>"{\"fault_domain\":1,\"update_domain\":5}"}},
                        {"ciName"=>"compute-240588809-6","ciAttributes"=>{"private_ip"=>"X.X.234.144","zone"=>"{\"fault_domain\":2,\"update_domain\":6}"}},
                        {"ciName"=>"compute-240588809-7","ciAttributes"=>{"private_ip"=>"X.X.249.67","zone"=>"{\"fault_domain\":3,\"update_domain\":7}"}},
                        {"ciName"=>"compute-240588809-8","ciAttributes"=>{"private_ip"=>"X.X.242.131","zone"=>"{\"fault_domain\":1,\"update_domain\":8}"}},
                        {"ciName"=>"compute-240588809-9","ciAttributes"=>{"private_ip"=>"X.X.246.35","zone"=>"{\"fault_domain\":2,\"update_domain\":9}"}},
                        {"ciName"=>"compute-240588809-10","ciAttributes"=>{"private_ip"=>"X.X.252.151","zone"=>"{\"fault_domain\":3,\"update_domain\":10}"}}
                      ]

uber_item_collections = {
                          "supply_item_index"=>{
                              "shards"=>{
                                  "shard1"=>{"replicas"=>{"core_node1"=>{"node_name"=>"X.X.231.36:8983_solr"},
                                                          "core_node2"=>{"node_name"=>"X.X.249.142:8983_solr"},
                                                          "core_node3"=>{"node_name"=>"X.X.201.164:8983_solr"}
                                                         }
                                            },
                                  "shard2"=>{"replicas"=>{"core_node4"=>{"node_name"=>"X.X.215.7:8983_solr"},
                                                          "core_node5"=>{"node_name"=>"X.X.204.51:8983_solr"},
                                                          "core_node6"=>{"node_name"=>"X.X.237.86:8983_solr"}
                                                         }
                                            }
                              }
                          },
                          "flat_product_index"=>{
                              "shards"=>{
                                  "shard1"=>{"replicas"=>{"core_node1"=>{"node_name"=>"X.X.249.142:8983_solr"},
                                                          "core_node3"=>{"node_name"=>"X.X.211.144:8983_solr"},
                                                          "core_node35"=>{"node_name"=>"X.X.201.164:8983_solr"}
                                                         }
                                            },
                                  "shard2"=>{"replicas"=>{"core_node5"=>{"node_name"=>"X.X.155.77:8983_solr"},
                                                          "core_node6"=>{"node_name"=>"X.X.221.39:8983_solr"},
                                                          "core_node37"=>{"node_name"=>"X.X.185.114:8983_solr"}
                                                         }
                                            },
                                  "shard3"=>{"replicas"=>{"core_node7"=>{"node_name"=>"X.X.242.48:8983_solr"},
                                                          "core_node9"=>{"node_name"=>"X.X.231.116:8983_solr"},
                                                          "core_node38"=>{"node_name"=>"X.X.194.59:8983_solr"}
                                                         }
                                            },
                                  "shard4"=>{"replicas"=>{"core_node11"=>{"node_name"=>"X.X.246.35:8983_solr"},
                                                          "core_node34"=>{"node_name"=>"X.X.215.42:8983_solr"},
                                                          "core_node40"=>{"node_name"=>"X.X.134.158:8983_solr"}
                                                         }
                                            },
                                  "shard5"=>{"replicas"=>{"core_node13"=>{"node_name"=>"X.X.252.151:8983_solr"},
                                                          "core_node14"=>{"node_name"=>"X.X.194.173:8983_solr"},
                                                          "core_node15"=>{"node_name"=>"X.X.231.36:8983_solr"}}},
                                  "shard6"=>{"replicas"=>{"core_node16"=>{"node_name"=>"X.X.190.204:8983_solr"},
                                                          "core_node17"=>{"node_name"=>"X.X.249.67:8983_solr"},
                                                          "core_node18"=>{"node_name"=>"X.X.142.170:8983_solr"}
                                                         }
                                            },
                                  "shard7"=>{"replicas"=>{"core_node19"=>{"node_name"=>"X.X.234.144:8983_solr"},
                                                          "core_node20"=>{"node_name"=>"X.X.190.78:8983_solr"},
                                                          "core_node21"=>{"node_name"=>"X.X.211.129:8983_solr"}
                                                         }
                                            },
                                  "shard8"=>{"replicas"=>{"core_node22"=>{"node_name"=>"X.X.204.51:8983_solr"},
                                                          "core_node23"=>{"node_name"=>"X.X.237.86:8983_solr"},
                                                          "core_node33"=>{"node_name"=>"X.X.215.7:8983_solr"}
                                                         }
                                            },
                                  "shard9"=>{"replicas"=>{"core_node26"=>{"node_name"=>"X.X.194.241:8983_solr"},
                                                          "core_node32"=>{"node_name"=>"X.X.234.125:8983_solr"},
                                                          "core_node39"=>{"node_name"=>"X.X.217.135:8983_solr"}
                                                         }
                                            },
                                  "shard10"=>{"replicas"=>{"core_node28"=>{"node_name"=>"X.X.199.55:8983_solr"},
                                                           "core_node30"=>{"node_name"=>"X.X.228.16:8983_solr"},
                                                           "core_node31"=>{"node_name"=>"X.X.242.131:8983_solr"}
                                                          }
                                             }
                                  }
                          },
                          "uber_cia_data"=>{
                              "shards"=>{
                                  "shard1"=>{"replicas"=>{"core_node2"=>{"node_name"=>"X.X.242.131:8983_solr"},
                                                          "core_node3"=>{"node_name"=>"X.X.201.164:8983_solr"},
                                                          "core_node20"=>{"node_name"=>"X.X.211.129:8983_solr"}
                                                         }
                                            },
                                  "shard2"=>{"replicas"=>{"core_node4"=>{"node_name"=>"X.X.215.7:8983_solr"},
                                                          "core_node5"=>{"node_name"=>"X.X.194.59:8983_solr"},
                                                          "core_node6"=>{"node_name"=>"X.X.234.125:8983_solr"}
                                                         }
                                            },
                                  "shard3"=>{"replicas"=>{"core_node7"=>{"node_name"=>"X.X.228.16:8983_solr"},
                                                          "core_node16"=>{"node_name"=>"X.X.249.67:8983_solr"},
                                                          "core_node18"=>{"node_name"=>"X.X.199.55:8983_solr"}
                                                         }
                                            },
                                  "shard4"=>{"replicas"=>{"core_node12"=>{"node_name"=>"X.X.242.131:8983_solr"},
                                                          "core_node15"=>{"node_name"=>"X.X.221.39:8983_solr"},
                                                          "core_node19"=>{"node_name"=>"X.X.185.114:8983_solr"}
                                                         }
                                            }
                                  }
                          },
                          "flat_product_index_ca"=>{
                              "shards"=>{
                                  "shard1"=>{"replicas"=>{"core_node1"=>{"node_name"=>"X.X.246.35:8983_solr"},
                                                          "core_node2"=>{"node_name"=>"X.X.194.173:8983_solr"},
                                                          "core_node3"=>{"node_name"=>"X.X.231.116:8983_solr"}
                                                         }
                                            },
                                  "shard2"=>{"replicas"=>{"core_node4"=>{"node_name"=>"X.X.194.59:8983_solr"},
                                                          "core_node5"=>{"node_name"=>"X.X.242.48:8983_solr"},
                                                          "core_node6"=>{"node_name"=>"X.X.215.42:8983_solr"}
                                                         }
                                            }
                                  }
                          },
                          "supply_trade_item_index"=>{
                              "shards"=>{
                                  "shard1"=>{"replicas"=>{"core_node1"=>{"node_name"=>"X.X.231.36:8983_solr"},
                                                          "core_node2"=>{"node_name"=>"X.X.249.142:8983_solr"},
                                                          "core_node3"=>{"node_name"=>"X.X.194.241:8983_solr"}
                                                         }
                                            },
                                  "shard2"=>{"replicas"=>{"core_node4"=>{"node_name"=>"X.X.231.116:8983_solr"},
                                                          "core_node6"=>{"node_name"=>"X.X.234.125:8983_solr"},
                                                          "core_node8"=>{"node_name"=>"X.X.190.78:8983_solr"}
                                                         }
                                            }
                                  }
                          },
                          "uber_item_extraction"=>{
                              "shards"=>{
                                  "shard1"=>{"replicas"=>{"core_node1"=>{"node_name"=>"X.X.215.42:8983_solr"},
                                                          "core_node2"=>{"node_name"=>"X.X.246.35:8983_solr"},
                                                          "core_node3"=>{"node_name"=>"X.X.190.78:8983_solr"}
                                                         }
                                            },
                                  "shard2"=>{"replicas"=>{"core_node4"=>{"node_name"=>"X.X.228.16:8983_solr"},
                                                          "core_node5"=>{"node_name"=>"X.X.199.55:8983_solr"},
                                                          "core_node6"=>{"node_name"=>"X.X.252.151:8983_solr"}
                                                         }
                                            }
                                  }
                          },
                          "global_index_error"=>{
                              "shards"=>{
                                  "shard1"=>{"replicas"=>{"core_node1"=>{"node_name"=>"X.X.211.129:8983_solr"},
                                                          "core_node2"=>{"node_name"=>"X.X.252.151:8983_solr"},
                                                          "core_node3"=>{"node_name"=>"X.X.134.158:8983_solr"}
                                                         }
                                            },
                                  "shard2"=>{"replicas"=>{"core_node4"=>{"node_name"=>"X.X.142.170:8983_solr"},
                                                          "core_node5"=>{"node_name"=>"X.X.185.114:8983_solr"},
                                                          "core_node6"=>{"node_name"=>"X.X.234.144:8983_solr"}
                                                         }
                                            }
                                  }
                              }
                          }

def execute_and_verify(shards, replicas, computes, cloud_provider, sharing_collections, existing_collections_payload, test_id_expected_shard_map, test_id)
  replicaDistributor = ReplicaDistributor.new
  shard_num_to_iplist_map = replicaDistributor.get_shard_number_to_core_ips_map(shards, replicas, computes, cloud_provider, sharing_collections, existing_collections_payload)
  ip_to_cloud_map = replicaDistributor.get_compute_ip_to_cloud_id_map(computes, cloud_provider)

  expected_shard_num_to_iplist_map = test_id_expected_shard_map[test_id]
  puts "shard_num_to_iplist_map          = #{shard_num_to_iplist_map}"
  puts "expected_shard_num_to_iplist_map = #{expected_shard_num_to_iplist_map}"
  puts "total cores = #{shard_num_to_iplist_map.values.flatten.uniq.size}"

  shard_num_to_iplist_map.each do |shard_num, ip_list|
    msg = "# shard #{shard_num} => {"
    ip_list.each {|ip| msg = "#{msg} #{ip} : #{ip_to_cloud_map[ip]}"}
    msg = "#{msg} }"
    puts msg
  end

  # Verify that no duplicate IPs selected. i.e. multiple replicas on same IP
  selected_ip_list = shard_num_to_iplist_map.values.flatten
  duplicate_ip = selected_ip_list.detect{ |ip| selected_ip_list.count(ip) > 1 }
  if duplicate_ip != nil && duplicate_ip.empty?
    raise "Test Failed : Multiple replicas selected for on #{duplicate_ip}"
  end

  # In case of sharing nodes with existing collection, no other IPs than existing collection are selected
  puts "selected_ip_list = #{selected_ip_list}"
  if sharing_collections != nil && !sharing_collections.empty?
    expected_ips = replicaDistributor.get_existing_collection_core_ips(sharing_collections, existing_collections_payload)
    unexpected_ips = shard_num_to_iplist_map.values.flatten - expected_ips
    if !unexpected_ips.empty?
      raise "Some unexpected ips #{unexpected_ips} are being used to add replicas"
    end
  end

  # Verify the shard & replicas are same as expected
  if !shard_num_to_iplist_map.eql?expected_shard_num_to_iplist_map
    raise "Test Failed"
  else
    puts "Test Passed"
  end
end

test_id_expected_shard_map = Hash.new()
test_id_expected_shard_map["TEST_AZURE_NO_SHARING_NO_EXISTING_COLLECTIONS",] = {1=>["34951920-1_11", "34951920-2_12", "34951921-1_21"], 2=>["34951920-3_13", "34951920-4_11", "34951921-2_22"]}
test_id_expected_shard_map["TEST_AZURE_NO_SHARING",] = {1=>["34951920-3_13", "34951920-5_12", "34951921-3_23"], 2=>["34951920-2_12", "34951920-1_11", "34951921-4_21"]}
test_id_expected_shard_map["TEST_AZURE_SHARING",] = {1=>["34951920-3_13", "34951920-2_12", "34951921-1_21"], 2=>["34951920-1_11", "34951920-4_11", "34951921-2_22"]}
test_id_expected_shard_map["TEST_OPENSTACK_NO_SHARING_NO_EXISTING_COLLECTIONS",] = {1=>["34951920-1_11", "34951920-2_12", "34951921-1_21"], 2=>["34951920-3_13", "34951920-4_11", "34951921-2_22"]}
test_id_expected_shard_map["TEST_OPENSTACK_NO_SHARING",] = {1=>["34951920-5_12", "34951920-3_13", "34951921-4_21"], 2=>["34951920-1_11", "34951920-2_12", "34951921-3_23"]}
test_id_expected_shard_map["TEST_OPENSTACK_SHARING",] = {1=>["34951920-1_11", "34951920-2_12", "34951921-1_21"], 2=>["34951920-3_13", "34951920-4_11", "34951921-2_22"]}

execute_and_verify(2, 3, computes, 'azure', [], {}, test_id_expected_shard_map, "TEST_AZURE_NO_SHARING_NO_EXISTING_COLLECTIONS")
execute_and_verify(2, 3, computes, 'azure', [], collections_payload, test_id_expected_shard_map, "TEST_AZURE_NO_SHARING")
execute_and_verify(2, 3, computes, 'azure', ['collection1'], collections_payload, test_id_expected_shard_map, "TEST_AZURE_SHARING")
execute_and_verify(2, 3, computes, 'openstack', [], {}, test_id_expected_shard_map, "TEST_OPENSTACK_NO_SHARING_NO_EXISTING_COLLECTIONS")
execute_and_verify(2, 3, computes, 'openstack', [], collections_payload, test_id_expected_shard_map, "TEST_OPENSTACK_NO_SHARING")
execute_and_verify(2, 3, computes, 'openstack', ['collection1'], collections_payload, test_id_expected_shard_map, "TEST_OPENSTACK_SHARING")
