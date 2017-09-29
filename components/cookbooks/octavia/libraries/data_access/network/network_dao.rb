require File.expand_path('../../../../libraries/requests/network/network_request', __FILE__)

class NetworkDao

  def initialize(tenant)
    fail ArgumentError, 'tenant is nil' if tenant.nil?

    @network_request = NetworkRequest.new(tenant)
  end

  def get_network_id(network_name)
    fail ArgumentError, 'network_name is nil' if network_name.nil? || network_name.empty?

    filters = {'name' => network_name}
    response = @network_request.list_networks(filters)
    network_dto = JSON.parse(response[:body])['networks']

    return network_dto[0]['id']
  end

  def get_ip_availability_network(network_id)
    fail ArgumentError, 'network_id is nil' if network_id.nil? || network_id.empty?

    filters = {'network_id' => network_id}
    response = @network_request.get_ip_availability(filters)

    return JSON.parse(response[:body])['network_ip_availabilities']

  end
end