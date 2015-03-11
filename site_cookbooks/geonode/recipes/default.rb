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




