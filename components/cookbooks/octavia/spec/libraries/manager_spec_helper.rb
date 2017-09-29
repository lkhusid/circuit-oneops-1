  require 'webmock/rspec'
  require File.expand_path('../../../spec/spec_helper', __FILE__)

  require File.expand_path('../../../libraries/models/tenant_model', __FILE__)
  require File.expand_path('../../../libraries/loadbalancer_manager', __FILE__)
  require File.expand_path('../../../libraries/health_monitor_manager', __FILE__)

  require File.expand_path('../../../libraries/network_manager', __FILE__)

  module Helpers
    def token_helper
      token_string = '{
      "access": {
          "tenantName": "tenant_name",
          "token": {
              "id": "cbc36478b0bd8e67e89469c7749d4127"
          }
      }
  }'

      subnet_details ='{
      "subnets": [
          {
              "name": "private-subnet",
              "id": "08eae331-0402-425a-923c-34f7cfe39c1b"

          }
      ]
  }'
      stub_request(:post, "http://10.0.2.15:5000/v2.0/tokens").
          with(:body => "{\"auth\": {\"tenantName\": \"tenant_name\", \"passwordCredentials\": {\"username\": \"username\", \"password\": \"password\"}}}",
               :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
          to_return(:status => 200, :body => token_string, :headers => {})

      stub_request(:get, "http://10.0.2.15:9696/v2.0/subnets?name=provider1-v4").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
          to_return(:status => 200, :body => subnet_details, :headers => {})


    end

    def parent_helper_method


      lb_json = '{
      "loadbalancer": {
          "description": "simple lb",
          "admin_state_up": true,
          "project_id": "1a3e005cf9ce40308c900bcb08e5320c",
          "tenant_id": "1a3e005cf9ce40308c900bcb08e5320c",
          "provisioning_status": "ACTIVE",
          "listeners": [{"id": "ad1236b9-b490-44c9-bfe8-48beb86e3130"}],
          "vip_address": "10.0.0.2",
          "vip_subnet_id": "013d3059-87a4-45a5-91e9-d721068ae0b2",
          "id": "8e5aee5f-5dda-43bc-809c-fd5ee2a191e4",
          "operating_status": "ONLINE",
          "name": "unit-test-lb-http",
          "pools": [{"id": "8e5aee5f-5dda-43bc-809c-fd5ee2a191e4"}]
      }
  }'
      stub_request(:get, "http://10.0.2.15:9696/v2.0/lbaas/loadbalancers/8e5aee5f-5dda-43bc-809c-fd5ee2a191e4").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 200, :body => lb_json, :headers => {})

      stub_request(:get, "http://10.0.2.15:9696/v2.0/lbaas/loadbalancers?name=8e5aee5f-5dda-43bc-809c-fd5ee2a191e4").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 404, :body => "", :headers => {})



      lb_list_json = '{
      "loadbalancer": {
          "description": "simple lb",
          "admin_state_up": true,
          "project_id": "1a3e005cf9ce40308c900bcb08e5320c",
          "tenant_id": "1a3e005cf9ce40308c900bcb08e5320c",
          "provisioning_status": "ACTIVE",
          "listeners": [],
          "vip_address": "10.0.0.2",
          "vip_subnet_id": "013d3059-87a4-45a5-91e9-d721068ae0b2",
          "id": "8e5aee5f-5dda-43bc-809c-fd5ee2a191e4",
          "operating_status": "ONLINE",
          "name": "unit-test-lb-http",
          "pools": []
      }
  }'


      stub_request(:post, "http://10.0.2.15:9696/v2.0/lbaas/loadbalancers").
          with(:body => "{\"loadbalancer\":{\"vip_subnet_id\":\"08eae331-0402-425a-923c-34f7cfe39c1b\",\"name\":\"unit-test-lb-http\",\"description\":\"\",\"admin_state_up\":true,\"provider\":\"octavia\"}}",
               :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 201, :body => lb_list_json, :headers => {})

      listener_json = '{
    "listener": {
        "admin_state_up": true,
        "connection_limit": 100,
        "default_pool_id": null,
        "description": "listener one",
        "id": "39de4d56-d663-46e5-85a1-5b9d5fa17829",
        "loadbalancers": [
            {
                "id": "a36c20d0-18e9-42ce-88fd-82a35977ee8c"
            }
        ],
        "name": "listener1",
        "protocol": "HTTP",
        "protocol_port": 80,
        "project_id": "1a3e005cf9ce40308c900bcb08e5320c",
        "tenant_id": "1a3e005cf9ce40308c900bcb08e5320c",
        "default_tls_container_ref": "https://barbican.endpoint/containers/a36c20d0-18e9-42ce-88fd-82a35977ee8c",
        "sni_container_refs": [
            "https://barbican.endpoint/containers/b36c20d0-18e9-42ce-88fd-82a35977ee8d",
            "https://barbican.endpoint/containers/c36c20d0-18e9-42ce-88fd-82a35977ee8e"
        ]
    }
}'

      stub_request(:post, "http://10.0.2.15:9696/v2.0/lbaas/listeners").
          with(:body => "{\"listener\":{\"loadbalancer_id\":\"8e5aee5f-5dda-43bc-809c-fd5ee2a191e4\",\"protocol\":\"HTTP\",\"protocol_port\":\"80\",\"name\":\"unit-test-lb-http-listener\",\"description\":\"\",\"admin_state_up\":true,\"connection_limit\":-1,\"default_tls_container_ref\":\"https://test.com:9311/v1/containers/a4622ffb-6312-4625-ae95-d40b407384c4\" }}",
               :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 201, :body => listener_json, :headers => {})

      listener_get_json ='{"listener": {"protocol_port": 80, "protocol": "HTTP", "description": "", "default_tls_container_ref": null, "admin_state_up": true, "loadbalancers": [{"id": "7be213af-d74f-40a6-b7df-dd02d09442b6"}], "sni_container_refs": [], "connection_limit": -1, "default_pool_id": "8e5aee5f-5dda-43bc-809c-fd5ee2a191e4", "id": "ad1236b9-b490-44c9-bfe8-48beb86e3130", "name": "unittest.dev.cloud.com-tcp-467065-lb-listener"}}'

      stub_request(:get, "http://10.0.2.15:9696/v2.0/lbaas/listeners/ad1236b9-b490-44c9-bfe8-48beb86e3130").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return({:status => 200, :body => listener_get_json, :headers => {}}, {:status => 200, :body => listener_get_json, :headers => {}}, {:status => 404, :body => listener_get_json, :headers => {}})

      pool_get_json = '{"pool": {"lb_algorithm": "ROUND_ROBIN", "protocol": "HTTP", "description": "", "admin_state_up": true, "loadbalancers": [{"id": "7be213af-d74f-40a6-b7df-dd02d09442b6"}], "tenant_id": "f7e0d5adce3344f788a646fc95f81fb4", "session_persistence": null, "healthmonitor_id": "ee027e73-231b-4d18-a3cd-41c5392345ba", "listeners": [{"id": "ad1236b9-b490-44c9-bfe8-48beb86e3130"}], "members": [{"id": "4c507d81-299e-4b1c-a153-69d2b4573277"}, {"id": "4575b28b-834e-4a7d-bdba-b9a9b7666e38"}], "id": "8e5aee5f-5dda-43bc-809c-fd5ee2a191e4", "name": "unittest.dev.cloud.com-tcp-467065-lb-pool"}}'

      stub_request(:get, "http://10.0.2.15:9696/v2.0/lbaas/pools/8e5aee5f-5dda-43bc-809c-fd5ee2a191e4").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 200, :body => pool_get_json, :headers => {})


      members_list_get_json = '{"members": [{"name": "", "weight": 1, "admin_state_up": true, "subnet_id": "b3213ad4-c702-4fdb-bed0-da2c189f1aa7", "tenant_id": "f7e0d5adce3344f788a646fc95f81fb4", "address": "2620:1c0:72:8b00:f816:3eff:fe3d:8a44", "protocol_port": 8080, "id": "4c507d81-299e-4b1c-a153-69d2b4573277"}, {"name": "", "weight": 1, "admin_state_up": true, "subnet_id": "b3213ad4-c702-4fdb-bed0-da2c189f1aa7", "tenant_id": "f7e0d5adce3344f788a646fc95f81fb4", "address": "2620:1c0:72:8b00:f816:3eff:fe60:b3a9", "protocol_port": 8080, "id": "4575b28b-834e-4a7d-bdba-b9a9b7666e38"}]}'

      stub_request(:get, "http://10.0.2.15:9696/v2.0/lbaas/pools/8e5aee5f-5dda-43bc-809c-fd5ee2a191e4/members").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 200, :body => members_list_get_json, :headers => {})

      healthmonitor_get_json = ' {"healthmonitor": {"name": "unittest.dev.cloud.com-tcp-467065-lb-ecv", "admin_state_up": true, "delay": 5, "expected_codes": "200", "max_retries": 3, "http_method": "GET", "max_retries_down": 3, "timeout": 2, "pools": [{"id": "8e5aee5f-5dda-43bc-809c-fd5ee2a191e4"}], "url_path": "/", "type": "HTTP", "id": "ee027e73-231b-4d18-a3cd-41c5392345ba"}}'


      stub_request(:delete, "http://10.0.2.15:9696/v2.0/lbaas/pools/8e5aee5f-5dda-43bc-809c-fd5ee2a191e4/members/4c507d81-299e-4b1c-a153-69d2b4573277").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 204, :body => "", :headers => {})


      stub_request(:get, "http://10.0.2.15:9696/v2.0/lbaas/healthmonitors/ee027e73-231b-4d18-a3cd-41c5392345ba").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 200, :body => healthmonitor_get_json, :headers => {})

      stub_request(:put, "http://10.0.2.15:9696/v2.0/lbaas/pools/8e5aee5f-5dda-43bc-809c-fd5ee2a191e4").
          with(:body => "{\"pool\":{\"name\":\"unittest.dev.cloud.com-tcp-467065-lb-pool\",\"description\":\"\",\"admin_state_up\":true,\"lb_algorithm\":\"ROUND_ROBIN\",\"session_persistence\":null}}",
               :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 200, :body => pool_get_json, :headers => {})



      pool_json = '{
    "pool": {
        "status": "PENDING_CREATE",
        "lb_algorithm": "ROUND_ROBIN",
        "protocol": "HTTP",
        "description": "simple pool",
        "health_monitors": [],
        "members": [],
        "status_description": null,
        "id": "af95e0ce-8a26-4f29-9524-db41e7769c73",
        "vip_id": null,
        "name": "my-pool",
        "admin_state_up": true,
        "subnet_id": "e301aed0-d9e7-498a-977c-1bbfaf14ed5d",
        "project_id": "eabfefa3fd1740a88a47ad98e132d238",
        "tenant_id": "eabfefa3fd1740a88a47ad98e132d238",
        "health_monitors_status": [],
        "provider": "haproxy"
    }
}'

      stub_request(:post, "http://10.0.2.15:9696/v2.0/lbaas/pools").
          with(:body => "{\"pool\":{\"listener_id\":\"39de4d56-d663-46e5-85a1-5b9d5fa17829\",\"protocol\":\"HTTP\",\"lb_algorithm\":\"ROUND_ROBIN\",\"name\":\"unit-test-lb-http-pool\",\"description\":\"\",\"admin_state_up\":true,\"session_persistence\":{\"type\":\"SOURCE_IP\"}}}",
               :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 201, :body => pool_json, :headers => {})

      member1_json ='{
    "member": {
        "admin_state_up": true,
        "weight": 1,
        "address": "10.243.241.27",
        "project_id": "eabfefa3fd1740a88a47ad98e132d238",
        "tenant_id": "eabfefa3fd1740a88a47ad98e132d238",
        "protocol_port": 90,
        "id": "cf024846-7516-4e3a-b0fb-6590322c836f",
        "subnet_id": "5a9a3e9e-d1aa-448e-af37-a70171f2a332"
    }
}'
      member2_json ='{
    "member": {
        "admin_state_up": true,
        "weight": 1,
        "address": "10.243.241.33",
        "project_id": "eabfefa3fd1740a88a47ad98e132d238",
        "tenant_id": "eabfefa3fd1740a88a47ad98e132d238",
        "protocol_port": 90,
        "id": "cf024846-7516-4e3a-b0fb-6590322c836f",
        "subnet_id": "5a9a3e9e-d1aa-448e-af37-a70171f2a332"
    }
}'

      stub_request(:post, "http://10.0.2.15:9696/v2.0/lbaas/pools/af95e0ce-8a26-4f29-9524-db41e7769c73/members").
          with(:body => "{\"member\":{\"address\":\"10.243.241.27\",\"protocol_port\":\"8080\",\"subnet_id\":\"08eae331-0402-425a-923c-34f7cfe39c1b\",\"name\":\"\",\"admin_state_up\":true,\"weight\":1}}",
               :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 201, :body => member1_json, :headers => {})

      stub_request(:post, "http://10.0.2.15:9696/v2.0/lbaas/pools/af95e0ce-8a26-4f29-9524-db41e7769c73/members").
          with(:body => "{\"member\":{\"address\":\"10.243.241.33\",\"protocol_port\":\"8080\",\"subnet_id\":\"08eae331-0402-425a-923c-34f7cfe39c1b\",\"name\":\"\",\"admin_state_up\":true,\"weight\":1}}",
               :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 201, :body => member2_json, :headers => {})

      stub_request(:post, "http://10.0.2.15:9696/v2.0/lbaas/pools/4c507d81-299e-4b1c-a153-69d2b4573277/members").
          with(:body => "{\"member\":{\"address\":\"2620:1c0:72:8b00:f816:3eff:fe3d:8a44\",\"protocol_port\":8080,\"subnet_id\":\"b3213ad4-c702-4fdb-bed0-da2c189f1aa7\",\"name\":\"\",\"admin_state_up\":true,\"weight\":1,\"tenant_id\":\"f7e0d5adce3344f788a646fc95f81fb4\"}}",
               :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 201, :body => member1_json, :headers => {})



      hm_json = '{
  "status" : "204",
  "healthmonitor": {
          "admin_state_up": true,
          "project_id": "eabfefa3fd1740a88a47ad98e132d238",
          "tenant_id": "eabfefa3fd1740a88a47ad98e132d238",
          "delay": 1,
          "expected_codes": "200,201,202",
          "max_retries": 5,
          "http_method": "GET",
          "timeout": 1,
          "pools": [
              {
                  "status": "ACTIVE",
                  "status_description": null,
                  "pool_id": "5a9a3e9e-d1aa-448e-af37-a70171f2a332"
              }
          ],
          "url_path": "/index.html",
          "type": "HTTP",
          "id": "b7633ade-24dc-4d72-8475-06aa22be5412"
      }
  }
  '

      stub_request(:put, "http://10.0.2.15:9696/v2.0/lbaas/healthmonitors/ad1236b9-b490-44c9-bfe8-48beb86e3130").
          with(:body => "{\"healthmonitor\":{\"http_method\":\"GET\",\"url_path\":\"/\",\"expected_codes\":\"200\",\"admin_state_up\":true}}",
               :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 200, :body => hm_json, :headers => {})

      hm_json_new = '{
    "healthmonitor": {
        "admin_state_up": true,
        "project_id": "eabfefa3fd1740a88a47ad98e132d238",
        "tenant_id": "eabfefa3fd1740a88a47ad98e132d238",
        "delay": 1,
        "expected_codes": "200,201,202",
        "max_retries": 5,
        "http_method": "GET",
        "timeout": 1,
        "pools": [
            {
                "status": "ACTIVE",
                "status_description": null,
                "pool_id": "af95e0ce-8a26-4f29-9524-db41e7769c73"
            }
        ],
        "url_path": "/index.html",
        "type": "HTTP",
        "id": "b7633ade-24dc-4d72-8475-06aa22be5412"
    }
}'

      stub_request(:post, "http://10.0.2.15:9696/v2.0/lbaas/healthmonitors").
          with(:body => "{\"healthmonitor\":{\"pool_id\":\"af95e0ce-8a26-4f29-9524-db41e7769c73\",\"type\":\"http\",\"delay\":5,\"timeout\":2,\"max_retries\":3,\"name\":\"unit-test-lb-http-ecv\",\"http_method\":\"GET\",\"url_path\":\"/\",\"expected_codes\":\"200\",\"admin_state_up\":true}}",
               :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 201, :body => hm_json_new, :headers => {})

      stub_request(:delete, "http://10.0.2.15:9696/v2.0/lbaas/healthmonitors/ee027e73-231b-4d18-a3cd-41c5392345ba").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 204, :body => "", :headers => {})


      stub_request(:delete, "http://10.0.2.15:9696/v2.0/lbaas/pools/8e5aee5f-5dda-43bc-809c-fd5ee2a191e4").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 204, :body => "", :headers => {})

      stub_request(:delete, "http://10.0.2.15:9696/v2.0/lbaas/listeners/ad1236b9-b490-44c9-bfe8-48beb86e3130").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return({:status => 204, :body => "", :headers => {}}, {:status => 403, :body => "", :headers => {}}, {:status => 200, :body => "", :headers => {}})

      stub_request(:delete, "http://10.0.2.15:9696/v2.0/lbaas/loadbalancers/8e5aee5f-5dda-43bc-809c-fd5ee2a191e4").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 204, :body => "", :headers => {})


    end


    def lb_name_list_create_success_helper_method
      lb_name_not_found = '{
      "loadbalancers": {
          }
       }'

      lb_name_found = '{
      "loadbalancers": [{
          "description": "simple lb",
          "admin_state_up": true,
          "project_id": "1a3e005cf9ce40308c900bcb08e5320c",
          "tenant_id": "1a3e005cf9ce40308c900bcb08e5320c",
          "provisioning_status": "ACTIVE",
          "listeners": [],
          "vip_address": "10.0.0.2",
          "vip_subnet_id": "013d3059-87a4-45a5-91e9-d721068ae0b2",
          "id": "8e5aee5f-5dda-43bc-809c-fd5ee2a191e4",
          "operating_status": "ONLINE",
          "name": "unit-test-lb-http",
          "pools": []
          }
]
  }'
      stub_request(:get, "http://10.0.2.15:9696/v2.0/lbaas/loadbalancers?name=unit-test-lb-http").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return({:status => 200, :body => lb_name_not_found}, {:status => 200, :body => lb_name_found})

    end

    def lb_name_list_create_fail_helper_method
      lb_name_found = '{
      "loadbalancers": [{
          "description": "simple lb",
          "admin_state_up": true,
          "project_id": "1a3e005cf9ce40308c900bcb08e5320c",
          "tenant_id": "1a3e005cf9ce40308c900bcb08e5320c",
          "provisioning_status": "ACTIVE",
          "listeners": [{"id": "ad1236b9-b490-44c9-bfe8-48beb86e3130"}],
          "vip_address": "10.0.0.2",
          "vip_subnet_id": "013d3059-87a4-45a5-91e9-d721068ae0b2",
          "id": "8e5aee5f-5dda-43bc-809c-fd5ee2a191e4",
          "operating_status": "ONLINE",
          "name": "unit-test-lb-http",
          "pools": [{"id": "8e5aee5f-5dda-43bc-809c-fd5ee2a191e4"}]
          }
]
  }'
      stub_request(:get, "http://10.0.2.15:9696/v2.0/lbaas/loadbalancers?name=unit-test-lb-http").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return({:status => 200, :body => lb_name_found})

      lb_name_not_found = '{
      "loadbalancers": {
          }
       }'

      stub_request(:get, "http://10.0.2.15:9696/v2.0/lbaas/loadbalancers?name=unit-test").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return(:status => 200, :body => lb_name_not_found, :headers => {})





    end

    def listener_get_returns_403
      listener_get_json ='{"listener": {"protocol_port": 80, "protocol": "HTTP", "description": "", "default_tls_container_ref": null, "admin_state_up": true, "loadbalancers": [{"id": "7be213af-d74f-40a6-b7df-dd02d09442b6"}], "sni_container_refs": [], "connection_limit": -1, "default_pool_id": "8e5aee5f-5dda-43bc-809c-fd5ee2a191e4", "id": "ad1236b9-b490-44c9-bfe8-48beb86e3130", "name": "unittest.dev.cloud.com-tcp-467065-lb-listener"}}'

      stub_request(:get, "http://10.0.2.15:9696/v2.0/lbaas/listeners/ad1236b9-b490-44c9-bfe8-48beb86e3130").
          with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'Host'=>'10.0.2.15:9696', 'User-Agent'=>'fog-core/1.43.0', 'X-Auth-Token'=>'cbc36478b0bd8e67e89469c7749d4127'}).
          to_return({:status => 200, :body => listener_get_json, :headers => {}}, {:status => 403, :body => "", :headers => {}})
    end


    class Helper
    def get_lb
      json_string = '{
            "loadbalancers":
            [
                {
                    "name": "unit-test-lb-http",
            "vprotocol": "http",
            "vport": "80",
            "iprotocol": "http",
            "iport": "8080",
            "sg_name": "sg01"
        }
        ]
        }'

      node = JSON.parse(json_string)

      service_lb_attributes = {}

      ecv_map = "{\"8080\":\"get /\",\"9090\":\"get /healthmonitor\"}"

      service_lb_attributes['provider'] = "octavia"
      subnet_name = "provider1-v4"
      tenant = TenantModel.new('http://10.0.2.15:5000', 'tenant_name', 'username', 'password')
      network_manager = NetworkManager.new(tenant)
      subnet_id = network_manager.get_subnet_id(subnet_name)
      lb_name = ""

      stickiness = "true"
      persistence_type = "source_ip"

      listeners = Array.new
      loadbalancers = node["loadbalancers"]
      #loadbalancers array contains a list of listeners from lb::build_load_balancers
      loadbalancers.each do |loadbalancer|
        lb_name = loadbalancer["name"]
        vprotocol = loadbalancer["vprotocol"]
        vport = loadbalancer["vport"]
        iprotocol = loadbalancer["iprotocol"]
        iport = loadbalancer["iport"]
        sg_name = loadbalancer["sg_name"]

        if vprotocol == 'https' and iprotocol == "https"
          health_monitor = initialize_health_monitor('tcp', ecv_map, lb_name, iport)
        else
          health_monitor = initialize_health_monitor(iprotocol, ecv_map, lb_name, iport)
        end

        members = Array.new
        computes = JSON.parse('[{"private_ip" : "10.243.241.27"}, {"private_ip" : "10.243.241.33"}]')
        computes.each do |compute|
          ip_address = compute["private_ip"]
          member = MemberModel.new(ip_address, iport, subnet_id)
          members.push(member)
        end

        pool = initialize_pool(iprotocol, "round-robin", lb_name, members, health_monitor, stickiness, persistence_type)
        container_ref = "https://test.com:9311/v1/containers/a4622ffb-6312-4625-ae95-d40b407384c4"
        listeners.push(initialize_listener(vprotocol, vport, lb_name, pool,nil))
      end
      loadbalancer = initialize_loadbalancer(subnet_id, "octavia", lb_name, listeners)

      return loadbalancer
    end
    end

    class Fake_class

      def info(logmessage)

      end


      def warn(logmessage)

      end
    end
  end