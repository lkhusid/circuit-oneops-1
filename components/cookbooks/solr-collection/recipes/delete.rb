#
# Cookbook Name :: solr-collection
# Recipe :: delete.rb
#
#
#
# On delete collection, delete cron job for backups
if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi.ciAttributes
else
  ci = node.workorder.ci.ciAttributes
end
node.set['collection_name'] = ci['collection_name']
node.set['solr']['user'] = "app"
include_recipe 'solr-collection::schedule_backup'