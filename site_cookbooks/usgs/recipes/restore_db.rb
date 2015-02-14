#
# Cookbook Name:: usgs
# Recipe:: restore_db
#
# Copyright 2015, John Aguinaldo
#
# All rights reserved - Do Not Redistribute
#

case node[:platform]
	when "centos"

		s3_file "#{Chef::Config[:file_cache_path]}/postgis-malaria-dump.sql" do
			bucket "malariamap"
			remote_path "/postgis-malaria-dump_blob.sql"
		end

		bash "Restore malariamap database" do
			code <<-EOH
				query='PGPASSWORD=#{node.deployment.databases.postgis.password} psql -h #{node.deployment.databases.postgis.endpoint} -U #{node.deployment.databases.postgis.username} -t -c "select count(1) from pg_catalog.pg_database where datname = '"'#{node.geoserver.db_name}'"'"'
				db_exists=`eval $query`
				if [ $db_exists -eq 1 ] ; then
					postgis_restore.pl "#{Chef::Config[:file_cache_path]}/postgis-malaria-dump.sql" | PGPASSWORD=#{$gs_postgres_pwd_cfg} psql -h #{node.deployment.databases.postgis.endpoint} -U #{$gs_postgres_usr_cfg} -d #{node.geoserver.db_name} 2> /var/chef/cache/postgis-errors.txt
				fi
			EOH
			sensitive true
			only_if "PGPASSWORD=#{$gs_postgres_pwd_cfg} psql -h #{node.deployment.databases.postgis.endpoint} -U #{$gs_postgres_usr_cfg} -d #{node.geoserver.db_name} -t -c \"select count(1) from information_schema.tables where table_name = 'all_cities'\"| grep 0"
		
		end

	else
		Chef::Log.info("Unsupported platform #{node[:platform]}")
end


# PGPASSWORD=#{$gs_postgres_pwd_cfg} psql -h #{node.deployment.databases.postgis.endpoint} -U #{$gs_postgres_usr_cfg} -d #{node.geoserver.db_name} -f /usr/pgsql-9.3/share/contrib/postgis-2.1/legacy.sql
# PGPASSWORD=#{$gs_postgres_pwd_cfg} pg_restore -h #{node.deployment.databases.postgis.endpoint} -U #{$gs_postgres_usr_cfg} -d #{node.geoserver.db_name} -O -w -x "#{Chef::Config[:file_cache_path]}/postgis-malaria-dump.sql"
