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

		execute "setsebool -P httpd_can_network_connect 1" do
			not_if "grep httpd_can_network_connect=1 /etc/selinux/targeted/modules/active/booleans.local"
		end

		web_app "vhosts" do
			server_name "malariamap.usgs.gov"
			server_aliases [ node.fqdn, node.hostname ]
			docroot "/var/www/html"
			allow_override "All"
			template "vhosts.conf.erb"
		end

		s3_file "#{Chef::Config[:file_cache_path]}/malariamap.zip" do
			bucket "malariamap"
			remote_path "/malariamap-www.zip"
		end

		execute "unzip -u -n #{Chef::Config[:file_cache_path]}/malariamap.zip -d /var/www/html" do
			not_if { Dir.exist?("/var/www/html/css") }
		end


		execute "find /var/www/html -type d -exec chmod 755 {} +; find /var/www/html -type f -exec chmod 644 {} +; chcon -R -h -t httpd_sys_content_t /var/www/html" do
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
