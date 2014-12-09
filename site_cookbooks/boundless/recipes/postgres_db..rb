#
# Cookbook Name:: boundless
# Recipe::postgresdb
#


case node[:platform]

    when "centos"
		# service "tomcat7"

		node.normal.tomcat.jndi = true

		node.normal.tomcat.jndi_connections = [
		{ "datasource_name" => "gscatalog", "driver" =>  "org.postgresql.Driver", "user" => $gs_postgres_usr_cfg, "pwd" => $gs_postgres_pwd_cfg, "max_active" => 40, "max_idle" => 10, "max_wait" => -1,
		  "connection_string" => "postgresql://#{node.deployment.databases.postgis.endpoint}:#{node.deployment.databases.postgis.port}/#{node.ogeosuite.geoserver.db_name}" },
		{ "datasource_name" => "gscatalog", "driver" =>  "org.postgresql.Driver", "user" => $gs_postgres_usr_cfg, "pwd" => $gs_postgres_pwd_cfg, "max_active" => 40, "max_idle" => 10, "max_wait" => -1,
		  "connection_string" => "postgresql://#{node.deployment.databases.postgis.endpoint}:#{node.deployment.databases.postgis.port}/#{node.geoserver.db_name}" }
		]

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

				bash "Create database for Geoserver config store" do
					code <<-EOH
						query='PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -t -c "select count(1) from pg_catalog.pg_roles where rolname = '"'geoserver'"'"'
						role_exists=`eval $query`
						if [ $role_exists -eq 0 ] ; then
							PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -c "CREATE ROLE #{$gs_postgres_usr_cfg} WITH PASSWORD '#{$gs_postgres_pwd_cfg}' CREATEDB CREATEROLE LOGIN IN ROLE rds_superuser;"
						fi
					EOH
					sensitive true
				end
				[node.ogeosuite.geoserver.db_name, node.geoserver.db_name].each do |db_name|
					bash "Create database #{db_name} for Geoserver" do
						code <<-EOH
							query='PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -t -c "select count(1) from pg_catalog.pg_database where datname = '"'#{db_name}'"'"'
							db_exists=`eval $query`
							if [ $db_exists -eq 0 ] ; then
								PGPASSWORD=#{$gs_postgres_pwd_cfg} psql -h #{node.deployment.databases.postgis.endpoint} -U #{$gs_postgres_usr_cfg} -d postgres -c "CREATE DATABASE #{db_name} OWNER #{$gs_postgres_usr_cfg};"
							fi
						EOH
						sensitive true
					end
				end
			end

        service "tomcat7" do
            action :restart
            only_if "service tomcat7 status | grep stopped"
        end
    else
        Chef::Log.info("Unsupported platform #{node[:platform]}")
end

