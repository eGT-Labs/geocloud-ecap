#
# Cookbook Name:: usgs
# Recipe:: apps
#
# Copyright 2015, John Aguinaldo
#
# All rights reserved - Do Not Redistribute
#

case node[:platform]
	when "centos"

		[80, 443].each { |port|
			bash "Allow TCP #{port} through iptables" do
				user "root"
				not_if "/sbin/iptables -nL | egrep '^ACCEPT.*dpt:#{port}($| )'"
				code <<-EOH
					iptables -I INPUT -p tcp --dport #{port} -j ACCEPT
					service iptables save
				EOH
			end
		}

		package "php"

		execute "setsebool -P httpd_can_network_connect 1" do
			not_if "grep httpd_can_network_connect=1 /etc/selinux/targeted/modules/active/booleans.local"
		end

		web_app "vhosts" do
			server_name "malariamap.usgs.gov"
			server_aliases [ node.fqdn, node.hostname ]
			docroot node.apache.docroot_dir
			allow_override "All"
			template "vhosts.conf.erb"
		end

		s3_file "#{Chef::Config[:file_cache_path]}/malariamap.zip" do
			bucket "malariamap"
			remote_path "/malariamap-www.zip"
		end

		execute "unzip -u -n #{Chef::Config[:file_cache_path]}/malariamap.zip -d #{node.apache.docroot_dir}" do
			not_if { Dir.exist?("#{node.apache.docroot_dir}/css") }
		end

		execute "sed -i 's_\^.ht_\^\\.ht_' #{node.apache.conf_dir}/httpd.conf" do
			only_if "grep -F ^.ht #{node.apache.conf_dir}/httpd.conf"
			notifies :reload, "service[apache2]", :delayed
		end

		execute "find #{node.apache.docroot_dir} -type d -exec chmod 755 {} +; find #{node.apache.docroot_dir} -type f -exec chmod 644 {} +; chcon -R -h -t httpd_sys_content_t #{node.apache.docroot_dir}" do
			returns [0,1]
		end

		template "#{node.apache.dir}/conf-enabled/proxy_ajp.conf" do
			source "proxy_ajp.conf.erb"
			mode 0644
			notifies :reload, "service[apache2]", :delayed
		end
	else
		Chef::Log.info("Unsupported platform #{node[:platform]}")
end
