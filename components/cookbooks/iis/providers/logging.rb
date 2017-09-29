LOGGING_PROPERTIES = ["logFormat", "directory", "enabled", "period", "logTargetW3C"]

def whyrun_supported?
  true
end

def iis_available?
  OO::IIS::Detection.aspnet_enabled? and OO::IIS::Detection.major_version >= 7
end
private :iis_available?

def load_current_resource
  @iis_logging = OO::IIS.new.logging(new_resource.site_name)
  @web_site = OO::IIS.new.web_site(new_resource.site_name)
  @current_resource = new_resource.class.new(new_resource.name)

  if iis_available?
    iis_logging_attributes = @iis_logging.get_logging_attributes
    LOGGING_PROPERTIES.each do |property|
      @current_resource.send(property, iis_logging_attributes[ property ])
    end
  end
end

def resource_needs_change_for?(property)
  new_resource.send(property) != current_resource.send(property)
end
private :resource_needs_change_for?

def resource_needs_change?
  resource_needs_change = false
  LOGGING_PROPERTIES.each do |property|
     resource_needs_change ||= resource_needs_change_for?(property)
  end
  resource_needs_change
end
private :resource_needs_change?

action :configure do
  modified = false
  if @web_site.exists?
    if resource_needs_change?
      @iis_logging.assign_logging_attributes(get_logging_attributes)
      modified = true
      Chef::Log.info "The web site #{new_resource.site_name} logging properties has been updated"
    end
  end
  new_resource.updated_by_last_action(modified)
end

def get_logging_attributes
  iis_logging_attributes = Hash.new({})
  LOGGING_PROPERTIES.each do |property|
    iis_logging_attributes[property] = new_resource.send(property)
  end
  iis_logging_attributes
end
