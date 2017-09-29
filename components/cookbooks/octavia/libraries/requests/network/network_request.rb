require File.expand_path('../../base_request.rb', __FILE__)
require 'excon'

class NetworkRequest < BaseRequest

  def list_networks(filters = {})
    request(
        :expects => 200,
        :method  => 'GET',
        :path    => '/networks',
        :query   => filters
    )
  end

  def get_ip_availability(filters = {})
    request(
        :expects => 200,
        :method  => 'GET',
        :path    => '/network-ip-availabilities',
        :query   => filters
    )
  end

end
