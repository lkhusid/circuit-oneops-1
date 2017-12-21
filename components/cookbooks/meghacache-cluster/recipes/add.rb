dns_record=node.workorder.payLoad.ManagedVia.map { |n| n['ciAttributes']['dns_record'] }.join(',')
puts "***RESULT:dns_record=#{dns_record}" 

