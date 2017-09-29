# coordinator_helper - Library functions
#
# These functions contain logic that is shared across multiple components.

# Parse the ciName to extract the cloud ID from it
#
# INPUT:
# ciName: The CI name to parse
#
# RETURNS:
# A string containing the numeric cloud ID, or '' if no
# name was specified
#
def cloudid_from_name(ciName)
  if ciName == nil || ciName.empty?
    # There was not a name specified.  Just return nothing.
    return ''
  end

  # The cloud ID is the second component of the CI name:
  #
  # basename-cloudid-instance
  #
  # Split on the '-' character and take the second to last component
  #
  nameComponents = ciName.split('-',-1)

  cloudid = nameComponents[nameComponents.length - 2]

  return cloudid
end

# Check the cloud configuration and ensure that it is valid.
#
# THROWS:
# Exception with a message indicating the problem.
#
def validate_clouds()
  primaryClouds = nil

  if node.workorder.payLoad.has_key?("primaryCloud")
    primaryClouds = node.workorder.payLoad.primaryCloud

    if primaryClouds.size > 1
      # There is more than one primary cloud.  There needs to be only one.
      puts "***FAULT:FATAL=There is more than one primary cloud in the deployment.  Make sure the environment contains only one primary cloud."
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end
  else
    # There are no primary clouds.
    puts "***FAULT:FATAL=There are no primary clouds in the deployment.  Make sure the environment contains one primary cloud."
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e
  end
end

# Get the ID of the primary cloud
#
# RETURNS:
# A string containing the numeric cloud ID
#
def get_primary_cloud_id()
  primaryClouds = nil

  if node.workorder.payLoad.has_key?("primaryCloud")
    primaryClouds = node.workorder.payLoad.primaryCloud
  end

  primary_cloud = primaryClouds[0]

  return primary_cloud.ciId.to_s
end

# Determines if this recipe is being run on a coordinator compute.
#
# RETURNS:
# A boolean value indicating whether this is a coordinator compute
#
def is_coord_compute()
  # Assume coordinator unless otherwise discovered
  isCoord = true

  # The indication that this presto-coordinator instance corresponds
  # to a Coordinator compute is that there is a coordConfig key in
  # the Payload, which represents the coordinator Presto configuration.
  if node.workorder.payLoad.has_key?("coordConfig")
    # This is a worker
    isCoord = false
  end

  return isCoord
end
