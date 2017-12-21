module Jolokia_proxy
  module Util
    def self.sudo_user(user)
      `ls /etc/sudoers.d | sort > /tmp/sudolist.out`
      found = `grep #{user} /tmp/sudolist.out |  wc -l`
      return found.to_i > 0
    end

  end

end