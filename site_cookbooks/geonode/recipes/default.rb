#
# Cookbook Name:: geonode
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
# Do this via apt cookbook when there is time, but...
#execute "add-apt-repository -y ppa:#{node[:some_repo]}" do
execute "add-apt-repository -y ppa:geonode/testing" do
  user "root"
end

execute "apt-get update" do
  user "root"
end

execute "apt-get -y install geonode" do
  user "root"
end

package "expect" do
	action :install
end

bash "create superuser" do
    user "ubuntu"
    code <<-EOF
    /usr/bin/expect -c 'spawn usr/sbin/geonode createsuperuser --username admin --email robert.patt-corner@eglobaltech.com
    expect "Password: "
    send "rpcpass\r"
    expect "Password (again):"
    send "rpcpass\r"
    expect eof'
    EOF
end

=begin
user "geonode" do
	action :create
end

#go back to this once we abstract the db
template "/etc/geonode/local_settings.py" do
	source "local_settings.erb"
	mode 0644
	owner "root"
	group "root"
=end
ruby_block "permit load balancer access" do
  block do
    dns = node.deployment.loadbalancers['geonode-lb']['dns']
    line = "ALLOWED_HOSTS=['localhost','#{node.ec2.private_ip_address}','#{dns}']"
        puts line
    file = Chef::Util::FileEdit.new("/etc/geonode/local_settings.py")
    file.insert_line_if_no_match("/ALLOWED_HOSTS.*$/",line)
    file.write_file
  end
  not_if "grep -q ALLOWED_HOSTS= /etc/geonode/local_settings.py"
end

service "apache2" do
	action :restart
end

