include_recipe 'tomcat'

node.normal.tomcat.java_options = "-Djava.awt.headless=true -Xmx1024m -XX:MaxPermSize=256m -XX:+UseConcMarkSweepGC"

group "tomcat7" do
  action :modify
  append true
  members ["unison", "rogue"]
end

directory node['tomcat']['home'] do
  group node["tomcat"]["group"]
  owner node["tomcat"]["user"]
end
