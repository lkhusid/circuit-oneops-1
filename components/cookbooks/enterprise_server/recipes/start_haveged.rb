execute "systemctl enable haveged" do
  returns [0,1]
end

execute "service haveged start" do
  returns [0,1]
end
