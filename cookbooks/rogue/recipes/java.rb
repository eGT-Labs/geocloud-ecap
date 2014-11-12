link "/usr/bin/java" do
  to node['java']['java_home'] + '/bin/java'
  user 'root'
end


