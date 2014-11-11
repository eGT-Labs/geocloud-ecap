#
# Cookbook Name:: boundless
# Recipe : geonode
#

node.normal.postgresql.enable_pgdg_yum = true
node.normal.postgresql.version = "9.3"
psql_version = 93
node.normal.postgresql.dir = "/var/lib/pgsql/#{node.postgresql.version }/data"
node.normal.postgresql.client.packages = ["postgresql#{psql_version}", "postgresql#{psql_version}-devel"]
node.normal.postgresql.server.packages = ["postgresql#{psql_version}-server"]
node.normal.postgresql.server.service_name = "postgresql-#{node.postgresql.version }"
node.normal.postgresql.contrib.packages = ["postgresql#{psql_version}-contrib"]
node.normal.postgresql.server.service_name = "postgresql-#{node.normal.postgresql.version}"

case node[:platform]
    when "centos"

		psql_pkg = "pgdg-centos93-9.3-1.noarch.rpm"

		remote_file "#{Chef::Config[:file_cache_path]}/#{psql_pkg}" do
			source "http://yum.postgresql.org/9.3/redhat/rhel-#{node.platform_version.to_i}-x86_64/#{psql_pkg}"
		end 

		package "pgdg-centos93" do
			source "#{Chef::Config[:file_cache_path]}/#{psql_pkg}"
		end

		yum_repository 'Apache-Maven' do
			description 'Apache Maven repo'
			url "http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-$releasever/$basearch"
			gpgcheck false
			enabled true
		end

        #Install dependencies 
        ['mod_wsgi', 'python-imaging', 'python-urlgrabber', 'python-paste-script', 'gdal', 'gdal-devel', 'gdal-java', 'gdal-python', 'geos', 'geos-devel', 'npm', 'geos-python',
		 'python-psycopg2', 'proj', 'proj-devel', 'proj-epsg', 'proj-nad', 'unzip', 'zip', 'gcc', 'patch', 'gettext', 'git', 'libxml2-devel', 'libxslt-devel', 'ant', 'apache-maven'].each do |pkg|
			package pkg
        end
		
		# Install npm dependencies
		#execute "npm install n -g -y; n stable"

		['n', 'npm', 'bower', 'grunt-cli'].each do |pkg|
			execute "npm install #{pkg} -g -y "
		end
		
		# Create python Virtual env
		python_virtualenv "/geonode"
		
		# Clone geonode git repo
		git '/geonode' do
			repository 'git://github.com/GeoNode/geonode.git'
		end
		
		# Install Geonode
		execute 'source /geonode/bin/activate; pip install -e geonode --allow-external pyproj --allow-unverified pyproj' do
			cwd "/geonode"
			not_if { File.exists?("/geonode/geonode") }
		end

    else
        Chef::Log.info("Unsupported platform #{node[:platform]}")
end

 