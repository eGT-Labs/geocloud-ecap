node.default['postgis']['version'] = '2.0.4'
node.default['postgis']['template_name'] = 'template_postgis'
node.default['postgis']['locale'] = 'en_US.utf8'

# apt_repository "opengeo" do
  # uri 'http://apt.opengeo.org/suite/v4/ubuntu/'
  # distribution 'lucid'
  # components ['main']
  # key 'http://apt.opengeo.org/gpg.key'
# end

if node.rogue.postgis.install_from_source
	include_recipe 'build-essential'
	# Download PostGIS
	remote_file "#{Chef::Config['file_cache_path']}/postgis-#{node['postgis']['version']}.tar.gz" do
	  source "http://download.osgeo.org/postgis/source/postgis-#{node['postgis']['version']}.tar.gz"
	  notifies :run, "bash[install_postgis]", :immediately
	end

	# Compile PostGIS
	bash "install_postgis" do
	  user "root"
	  cwd Chef::Config[:file_cache_path]
	  code <<-EOH
		tar -zxf postgis-#{node['postgis']['version']}.tar.gz
		(cd postgis-#{node['postgis']['version']}/ && ./configure && make && make install)
	  EOH
	  action :nothing
	end
else
	["postgresql-9.3-postgis-2.1", "postgresql-9.3-postgis-2.1-scripts"].each do |pkg|
		package pkg
	end
end

if node['postgis']['template_name']
  execute 'create_postgis_template' do
    not_if "psql -qAt --list | grep -q '^#{node['postgis']['template_name']}\|'", :user => 'postgres'
    user 'postgres'
    command <<-CMD
    (createdb -E UTF8 --locale=#{node['postgis']['locale']} #{node['postgis']['template_name']} -T template0) &&
    (psql -d #{node['postgis']['template_name']} -f `pg_config --sharedir`/contrib/postgis-2.1/postgis.sql) &&
    (psql -d #{node['postgis']['template_name']} -f `pg_config --sharedir`/contrib/postgis-2.1/spatial_ref_sys.sql) &&
    (psql -d #{node['postgis']['template_name']} -f `pg_config --sharedir`/contrib/postgis-2.1/postgis_comments.sql) &&
    (psql -d #{node['postgis']['template_name']} -f `pg_config --sharedir`/contrib/postgis-2.1/rtpostgis.sql) &&
    (psql -d #{node['postgis']['template_name']} -f `pg_config --sharedir`/contrib/postgis-2.1/raster_comments.sql) &&
    (psql -d #{node['postgis']['template_name']} -f `pg_config --sharedir`/contrib/postgis-2.1/topology.sql) &&
    (psql -d #{node['postgis']['template_name']} -f `pg_config --sharedir`/contrib/postgis-2.1/topology_comments.sql) &&
    (psql -d #{node['postgis']['template_name']} -f `pg_config --sharedir`/contrib/postgis-2.1/legacy.sql)
    CMD
    action :run
  end
end