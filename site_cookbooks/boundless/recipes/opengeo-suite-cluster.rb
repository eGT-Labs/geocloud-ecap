#
# Cookbook Name:: boundless
# Recipe::opengeo-suite-cluster
#

include_recipe "mu-glusterfs::client"

case node[:platform]
when "centos"

	bash "Allow TCP 5701:5704 through iptables" do
		user "root"
		not_if "/sbin/iptables -nL | egrep '^ACCEPT.*dpts:5701:5704($| )'"
		code <<-EOH
			iptables -I INPUT -p tcp --dport 5701:5704 -j ACCEPT
			service iptables save
		EOH
	end

	%w{jdbcconfig.zip cluster.zip}.each do |file|
		s3_file "#{Chef::Config[:file_cache_path]}/gs_extensions/#{file}" do
			bucket node.suite.s3.bucket
			remote_path "#{node.suite.s3.bucket_path}/geoserver_extensions/gs_2.6.x/#{file}"
		end
		execute "unzip -u -n #{Chef::Config[:file_cache_path]}/gs_extensions/#{file} -d #{node.suite.webapps}/geoserver/WEB-INF/lib"
	end

	execute "chown -R tomcat:tomcat #{node.suite.webapps}; find #{node.suite.webapps}/geoserver/WEB-INF/lib -type d -exec chmod 755 {} +; find #{node.suite.webapps}/geoserver/WEB-INF/lib -type f -exec chmod 644 {} +" do
		returns [0, 1]
		notifies :restart, 'service[tomcat7]', :immediately if !Dir.exist?("#{node.suite.geoserver.data_dir}/cluster"
		notifies :run, "ruby_block[Wait for #{node.suite.geoserver.data_dir}/cluster directory]"
	end

	ruby_block "Wait for #{node.suite.geoserver.data_dir}/cluster directory" do
		block do
			retries = 0
			begin
				retries = retries + 1
				sleep 5
			end while !Dir.exist?("#{node.suite.geoserver.data_dir}/cluster") and retries < 10
		end
		not_if { Dir.exists?("#{node.suite.geoserver.data_dir}/cluster") }
	end

	node.normal.tomcat.jndi = true

	node.normal.tomcat.jndi_connections = [
		{ 
			"datasource_name" => "gscatalog", "driver" => "org.postgresql.Driver", "user" => $gs_postgres_usr_cfg, "pwd" => $gs_postgres_pwd_cfg, "max_active" => 40, "max_idle" => 10, "max_wait" => -1,
			"connection_string" => "postgresql://#{node.deployment.databases.postgis.endpoint}:#{node.deployment.databases.postgis.port}/#{node.suite.geoserver.config_db_name}" 
		}
	]

	# Steal this from John
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

		directory node.suite.glusterfs_base_dir do
			recursive true
			owner 'tomcat'
			group 'tomcat'
			mode 0755
		end

		["geoexplorer", "geoserver"].each do |dir|
			execute "cp -pr #{node.suite.data_dir}/#{dir} #{node.suite.glusterfs_base_dir}" do
				not_if { Dir.exists?("#{node.suite.glusterfs_base_dir}/#{dir}") }
			end
		end

		execute "mv #{node.suite.data_dir} #{node.suite.data_dir}.orig" do
			not_if { Dir.exists?("#{node.suite.data_dir}.orig") }
		end

		link node.suite.data_dir do
			to node.suite.glusterfs_base_dir
		end

		node.suite.clstr.cfg_files.each do |tpl|
			template "#{tpl['directory']}/#{tpl['name']}" do
				source "#{tpl['name']}.erb"
				mode 0644
				owner tpl['owner']
				group tpl['owner']
				notifies :restart, 'service[tomcat7]'
			end
		end

		template "#{node.suite.geoserver.data_dir}/jdbcconfig/jdbcconfig.properties" do
			source "jdbcconfig.properties_init_db.erb"
			mode 0644
			owner "tomcat"
			group "tomcat"
			only_if "PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -t -c \"select count(1) from pg_catalog.pg_database where datname = '#{node.suite.geoserver.config_db_name}'\"| grep 0"
			notifies :restart, 'service[tomcat7]'
		end

		if node.application_attributes.existing_deployment == false
			node.normal.suite.geoserver.init_db = true
			node.normal.suite.geoserver.import_cfg_to_postgres = true

			bash "Create database for Geoserver config store" do
				code <<-EOH
					query='PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -t -c "select count(1) from pg_catalog.pg_roles where rolname = '"'geoserver'"'"'
					role_exists=`eval $query`
					if [ $role_exists -eq 0 ] ; then
						PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -c "CREATE ROLE #{$gs_postgres_usr_cfg} WITH PASSWORD '#{$gs_postgres_pwd_cfg}' CREATEDB CREATEROLE LOGIN IN ROLE rds_superuser;"
					fi
				
					query='PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -t -c "select count(1) from pg_catalog.pg_database where datname = '"'#{node.suite.geoserver.config_db_name}'"'"'
					db_exists=`eval $query`
					if [ $db_exists -eq 0 ] ; then
						PGPASSWORD=#{$gs_postgres_pwd_cfg} psql -h #{node.deployment.databases.postgis.endpoint} -U #{$gs_postgres_usr_cfg} -d postgres -c "CREATE DATABASE #{node.suite.geoserver.config_db_name} OWNER #{$gs_postgres_usr_cfg};"
					fi
				EOH
			end
		end

		execute "service tomcat7 restart" do
			notifies :run, "ruby_block[Wait for shared database]", :immediately
			only_if "grep import=true #{node.suite.geoserver.data_dir}/jdbcconfig/jdbcconfig.properties"
		end

		ruby_block "Wait for shared database" do
			block do
				retries = 0
				begin
					retries = retries + 1
					sleep 5
				end while retries == 10
			end
			action :nothing
		end

	else
		execute "mv #{node.suite.data_dir} #{node.suite.data_dir}.orig" do
			not_if { Dir.exists?("#{node.suite.data_dir}.orig") }
		end

		link node.suite.data_dir do
			to node.suite.glusterfs_base_dir
			notifies :restart, 'service[tomcat7]'
		end
	end

else
	Chef::Log.info("Unsupported platform #{node[:platform]}")
end

