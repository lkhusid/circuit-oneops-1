# cluster_helper - Library functions
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
