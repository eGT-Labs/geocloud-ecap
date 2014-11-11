#
# Cookbook Name:: boundless
# Recipe::opengeo-suite-cluster
#

include_recipe "femadata-glusterfs::client"

case node[:platform]

    when "centos"
		# service "tomcat7"
		
		bash "Allow TCP 5701:5704 through iptables" do
			user "root"
			not_if "/sbin/iptables -nL | egrep '^ACCEPT.*dpts:5701:5704($| )'"
			code <<-EOH
				iptables -I INPUT -p tcp --dport 5701:5704 -j ACCEPT
				service iptables save
			EOH
		end

        %w{geoserver-cluster geoserver-jdbcconfig}.each do |pkg|
            package pkg
        end

		node.normal.tomcat.jndi = true
		node.normal.tomcat.jndi_user = $gs_postgres_usr_cfg
		node.normal.tomcat.jndi_password = $gs_postgres_pwd_cfg

		service "tomcat7" do
			action :stop
			not_if  { File.exists?("#{node.ogeosuite.glusterfs_base_dir}/geoserver") }
		end

		found_master = false
		i_am_master = false
		node.deployment.servers.geoserver.each_pair { |name, data|
			if data['geoserver_master']
			found_master = true
				if name == Chef::Config[:node_name]
					i_am_master = true
				end
			end
		}
		if !found_master
			node.normal['deployment']['servers']['geoserver'][Chef::Config[:node_name]]['geoserver_master'] = true
			node.save
			i_am_master = true
		end

		if i_am_master

			directory node.ogeosuite.glusterfs_base_dir do
				recursive true
				owner 'tomcat'
				group 'tomcat'
				mode 0755
			end

			["geoexplorer", "geoserver"].each do |dir|
				execute "cp -pr #{node.ogeosuite.data_dir}/#{dir} #{node.ogeosuite.glusterfs_base_dir}" do
					not_if { File.exists?("#{node.ogeosuite.glusterfs_base_dir}/#{dir}") }
				end
			end

			execute "mv #{node.ogeosuite.data_dir} #{node.ogeosuite.data_dir}.orig" do
				not_if { File.exists?("#{node.ogeosuite.data_dir}.orig") }
			end

			link node.ogeosuite.data_dir do
				to node.ogeosuite.glusterfs_base_dir
			end

				node.ogeosuite.clstr.cfg_files.each do |tpl|
					template "#{tpl['directory']}/#{tpl['name']}" do
						source "#{tpl['name']}.erb"
						mode 0644
						owner tpl['owner']
						group tpl['owner']
					end
				end

				template "#{node.ogeosuite.geoserver.data_dir}/jdbcconfig/jdbcconfig.properties" do
					source "jdbcconfig.properties_init_db.erb"
					mode 0644
					owner "tomcat"
					group "tomcat"
					only_if "PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -t -c \"select count(1) from pg_catalog.pg_database where datname = '#{node.ogeosuite.geoserver.db_name}'\"| grep 0"
				end
			

			if node.application_attributes.existing_deployment == false
				node.normal.ogeosuite.geoserver.init_db = true
				node.normal.ogeosuite.geoserver.import_cfg_to_postgres = true

				bash "Create database for Geoserver config store" do
					code <<-EOH
						query='PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -t -c "select count(1) from pg_catalog.pg_roles where rolname = '"'geoserver'"'"'
						role_exists=`eval $query`
						if [ $role_exists -eq 0 ] ; then
							PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -c "CREATE ROLE #{$gs_postgres_usr_cfg} WITH PASSWORD '#{$gs_postgres_pwd_cfg}' CREATEDB CREATEROLE LOGIN IN ROLE rds_superuser;"
						fi
					
						query='PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -t -c "select count(1) from pg_catalog.pg_database where datname = '"'#{node.ogeosuite.geoserver.db_name}'"'"'
						db_exists=`eval $query`
						if [ $db_exists -eq 0 ] ; then
							PGPASSWORD=#{$gs_postgres_pwd_cfg} psql -h #{node.deployment.databases.postgis.endpoint} -U #{$gs_postgres_usr_cfg} -d postgres -c "CREATE DATABASE #{node.ogeosuite.geoserver.db_name} OWNER #{$gs_postgres_usr_cfg};"
						fi
					EOH
					sensitive true
				end
			end
		else
			execute "mv #{node.ogeosuite.data_dir} #{node.ogeosuite.data_dir}.orig" do
				not_if { File.exists?("#{node.ogeosuite.data_dir}.orig") }
			end

			link node.ogeosuite.data_dir do
				to node.ogeosuite.glusterfs_base_dir
			end
		end

        service "tomcat7" do
            action :restart
            only_if "service tomcat7 status | grep stopped"
        end
    else
        Chef::Log.info("Unsupported platform #{node[:platform]}")
end

