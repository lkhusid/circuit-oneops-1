# Default Cloud RDBMS recipe
#
# Delegates to the "add" script.
#
# None, I dont want the initial creation of the pack to run ansible. This should only be done during replace. Otherwise managed services will
#  install the pack initially.
include_recipe "cloudrdbms:add"