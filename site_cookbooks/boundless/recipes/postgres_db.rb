#
# Cookbook Name:: boundless
# Recipe::postgres_db
#

gs_postgres_auth_info = chef_vault_item("opengeo_suite", "postgres")
$gs_postgres_usr_cfg = gs_postgres_auth_info['username']
$gs_postgres_pwd_cfg = gs_postgres_auth_info['password']

case node[:platform]
	when "centos"
	# service "tomcat7"

	node.normal.tomcat.jndi = true

	node.normal.tomcat.jndi_connections = [
		{
			"datasource_name" => "gscatalog", "driver" =>  "org.postgresql.Driver", "user" => $gs_postgres_usr_cfg, "pwd" => $gs_postgres_pwd_cfg, "max_active" => 40, "max_idle" => 10, "max_wait" => -1,
			"connection_string" => "postgresql://#{node.deployment.databases.postgis.endpoint}:#{node.deployment.databases.postgis.port}/#{node.suite.geoserver.config_db_name}" 
		},
		{
			"datasource_name" => "gsdata", "driver" =>  "org.postgresql.Driver", "user" => $gs_postgres_usr_cfg, "pwd" => $gs_postgres_pwd_cfg, "max_active" => 40, "max_idle" => 10, "max_wait" => -1,
			"connection_string" => "postgresql://#{node.deployment.databases.postgis.endpoint}:#{node.deployment.databases.postgis.port}/#{node.suite.geoserver.data_db_name}" 
		}
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
					query='PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -t -c "select count(1) from pg_catalog.pg_roles where rolname = '"'#{$gs_postgres_usr_cfg}'"'"'
					role_exists=`eval $query`
					if [ $role_exists -eq 0 ] ; then
						PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -c "CREATE ROLE #{$gs_postgres_usr_cfg} WITH PASSWORD '#{$gs_postgres_pwd_cfg}' CREATEDB CREATEROLE LOGIN IN ROLE rds_superuser;"
					fi
				EOH
				sensitive true
			end
			[node.suite.geoserver.config_db_name, node.suite.geoserver.data_db_name].each do |db_name|
				bash "Create database #{db_name} for Geoserver" do
					code <<-EOH
						query='PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -t -c "select count(1) from pg_catalog.pg_database where datname = '"'#{db_name}'"'"'
						db_exists=`eval $query`
						if [ $db_exists -eq 0 ] ; then
							PGPASSWORD=#{$gs_postgres_pwd_cfg} psql -h #{node.deployment.databases.postgis.endpoint} -U #{$gs_postgres_usr_cfg} -d postgres -c "CREATE DATABASE #{db_name} OWNER #{$gs_postgres_usr_cfg};"
							PGPASSWORD=#{$gs_postgres_pwd_cfg} psql -h #{node.deployment.databases.postgis.endpoint} -U #{$gs_postgres_usr_cfg} -d #{db_name} -c "CREATE EXTENSION postgis; CREATE EXTENSION fuzzystrmatch; CREATE EXTENSION postgis_tiger_geocoder; CREATE EXTENSION postgis_topology; ALTER SCHEMA tiger OWNER TO rds_superuser; ALTER SCHEMA topology OWNER TO rds_superuser;"
							PGPASSWORD=#{$gs_postgres_pwd_cfg} psql -h #{node.deployment.databases.postgis.endpoint} -U #{$gs_postgres_usr_cfg} -d #{db_name} -c "CREATE FUNCTION exec(text) returns text language plpgsql volatile AS \\$f\\$ BEGIN EXECUTE \\$1; RETURN \\$1; END; \\$f\\$; SELECT exec('ALTER TABLE ' || quote_ident(s.nspname) || '.' || quote_ident(s.relname) || ' OWNER TO rds_superuser') FROM (SELECT nspname, relname FROM pg_class c JOIN pg_namespace n ON (c.relnamespace = n.oid) WHERE nspname in ('tiger','topology') AND relkind IN ('r','S','v') ORDER BY relkind = 'S') s;"
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
