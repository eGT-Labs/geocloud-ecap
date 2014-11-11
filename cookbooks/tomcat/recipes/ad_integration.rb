#
# Cookbook Name:: tomcat
# Recipe:: ad_integration
#
# Copyright 2014, eGlobalTech
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'chef-vault'

node.normal.tomcat.ad.integration = true

auth_info = chef_vault_item(node.tomcat.ad.auth.data_bag, node.tomcat.ad.auth.data_bag_item)
$tomcat_ad_usr = auth_info['username']
$tomcat_ad_pwd = auth_info['password']


case node[:platform]
    when "centos"

		template "#{node.tomcat.webapp_dir}/manager/WEB-INF/web.xml" do
			source "manager_web.xml.erb"
			owner 'tomcat'
			group 'tomcat'
			mode 0644
		end

    else
        Chef::Log.info("Unsupported platform #{node[:platform]}")
end

