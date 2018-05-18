APPLICATION_PROPERTIES = [
  "application_path",
  "application_pool"
]

VIRTUAL_DIRECTORY_PROPERTIES = [
  "virtual_directory_path",
  "virtual_directory_physical_path"
]
def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = new_resource.class.new(new_resource.name)
  @web_site = OO::IIS.new.web_site(new_resource.site_name)
  Chef::Log.fatal "Website #{site_name} does not exist. Cannot add application." unless @web_site.exists?
  assign_attributes_to_current_resource if @web_site.application_exists?(new_resource.application_path)
end

def assign_attributes_to_current_resource
  application_element = @web_site.get_application(new_resource.application_path)
  APPLICATION_PROPERTIES.each { |property_name| @current_resource.send(property_name, application_element[property_name]) }
  application_element["virtual_directories"].each do |virtual_directory|
    VIRTUAL_DIRECTORY_PROPERTIES.each { |property_name| @current_resource.send(property_name, virtual_directory[property_name]) }
  end
end

def attribute_needs_change?(property_name)
  @current_resource.send(property_name) != new_resource.send(property_name)
end

action :create do
  if @web_site.application_exists?(new_resource.application_path)
     Chef::Log.info "Application #{new_resource.application_path} already exists"
  else
    converge_by("Creating application #{new_resource.application_path}") do
      @web_site.create_application(get_attributes)
      Chef::Log.info "Successfully created new application #{new_resource.application_path}."
      new_resource.updated_by_last_action(true)
    end
  end
end

action :update do
  if @web_site.application_exists?(new_resource.application_path)
    attributes = {}
    virtual_directory_attributes = {}
    APPLICATION_PROPERTIES.each { |property_name| attributes[property_name] = new_resource.send(property_name) if attribute_needs_change?(property_name) }
    VIRTUAL_DIRECTORY_PROPERTIES.each { |property_name| virtual_directory_attributes[property_name] = new_resource.send(property_name) if attribute_needs_change?(property_name) }
    virtual_directory_attributes["virtual_directory_path"] = new_resource.send("virtual_directory_path") unless virtual_directory_attributes.empty?
    attributes["virtual_directory"] = virtual_directory_attributes unless virtual_directory_attributes.empty?
    if attributes.empty?
      Chef::Log.info "Application already up to date. No changes required."
    else
      Chef::Log.info "Attributes to update are #{attributes}"
      attributes["application_path"] = new_resource.send("application_path")
      converge_by("Updating application #{new_resource.application_path}") do
        @web_site.update_application(attributes)
        Chef::Log.info "Successfully updated application #{new_resource.application_path}."
        new_resource.updated_by_last_action(true)
      end
    end
  else
    Chef::Log.info "Application with path #{new_resource.application_path} does not exist. Please make sure that the application exists."
  end
end

action :delete do
  if @web_site.application_exists?
    converge_by("Deleting application #{new_resource.application_path}") do
      @web_site.delete_application(new_resource.application_path)
      Chef::Log.info "Successfully deleted application #{new_resource.application_path}"
      new_resource.updated_by_last_action(true)
    end
  else
    Chef::Log.info "Application with path #{new_resource.application_path} does not exist. Please make sure that the application exists."
  end
end

def get_virtual_directory_attributes
  attributes = {}
  VIRTUAL_DIRECTORY_PROPERTIES.each { |property_name| attributes[property_name] = new_resource.send(property_name) }
  attributes
end

def get_attributes
  attributes = {}
  APPLICATION_PROPERTIES.each { |property_name| attributes[property_name] = new_resource.send(property_name) }
  attributes["virtual_directory"] = get_virtual_directory_attributes
  attributes
end
