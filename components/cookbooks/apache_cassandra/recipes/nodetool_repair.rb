#Check if repair is already running
command = "ps -eaf | grep NodeTool | grep repair | grep -v grep | wc -l"
cmd = `#{command}`
if cmd.to_i > 0
  puts "***FAULT:FATAL=Notetool repair is already in progress"
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end
sdate = Time.now.strftime("%y%m%d%H%M%S")
log_file = "/app/cassandra/log/nodetool_repair_#{sdate}.txt"
args = ::JSON.parse(node.workorder.arglist)
repair_arguments = args["repair_args"]

#Submit repair in background
`nohup /opt/cassandra/bin/nodetool repair #{repair_arguments} > #{log_file} &`

#Monitor the repair log
running = true
while running
  sleep 10
  cmd = `tail -n 100 #{log_file}`
  puts cmd
  cmd = `#{command}`
  if cmd.to_i == 0
    running = false
  end
end
