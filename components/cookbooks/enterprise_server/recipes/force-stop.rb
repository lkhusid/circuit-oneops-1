bash "FORCE_STOP_ENTERPRISE_SERVER" do
  code <<-EOH
       pid=$(pgrep -f "catalina")
       if [ -n "$pid" ] ; then
            echo "Killing Enterprise Server of process $pid "
            kill -9 "$pid"
            sleep 5
            pid=$(pgrep -f "catalina")
            if [ -n "$pid" ] ; then
              echo "Could not stop tomcat."
            else
              echo "Enterprise Srver stopped"
        fi
        else
          echo "Enterprise Server not running"
        fi
      exit 0
  EOH
end