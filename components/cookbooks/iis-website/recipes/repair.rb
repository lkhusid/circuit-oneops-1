windows_service 'W3SVC' do
  action :start
end

include_recipe 'iis-website::app_pool_recycle'
