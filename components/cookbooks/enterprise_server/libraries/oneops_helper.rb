class Chef::Recipe::OneOpsHelper

  def self.get_nodes (node)
    nodes = node.workorder.payLoad.RequiresComputes
    # dns_record used for fqdn
    dns_record = ""
    nodes.each do |n|
      next if n[:ciAttributes][:dns_record].nil? || n[:ciAttributes][:dns_record].empty?
      if dns_record == ""
        dns_record = n[:ciAttributes][:dns_record]
      else
        dns_record += ","+n[:ciAttributes][:dns_record]
      end
    end
    return dns_record
  end

  def self.get_keystore_info(node)
    keystore_info={}
    depends_on_keystore=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] != 'bom.Keystore' }
    if (!depends_on_keystore.nil? && !depends_on_keystore.empty?)
        Chef::Log.info("do depend on keystore, with filename: #{depends_on_keystore[0]['ciAttributes']['keystore_filename']} ")
        keystore_info['keystore_path'] = depends_on_keystore[0]['ciAttributes']['keystore_filename']
        keystore_info['keystore_pass'] = depends_on_keystore[0]['ciAttributes']['keystore_password']
        Chef::Log.info("stashed keystore_path: #{keystore_info['keystore_path']} ")
        return keystore_info
    end
  end
end
