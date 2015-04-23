#
# Cookbook Name:: boundless
# Recipe::opengeo-suite
#

# node.normal.tomcat.app_base = "/usr/share/opengeo"

if node.java.jdk_version == 8
	node.normal.tomcat.java_options = "-Djava.awt.headless=true -Xms256m -Xmx2G -Xrs -XX:PerfDataSamplingInterval=500 -XX:+UseParallelOldGC -XX:+UseParallelGC -XX:NewRatio=2 -XX:SoftRefLRUPolicyMSPerMB=36000 -Dorg.geotools.referencing.forceXY=true -Dorg.geotools.shapefile.datetime=true -DGEOEXPLORER_DATA=#{node.ogeosuite.data_dir}/geoexplorer -DGEOSERVER_LOG_LOCATION=#{node.ogeosuite.geoserver.log_dir}/geoserver.log -DGEOSERVER_AUDIT_PATH=#{node.ogeosuite.geoserver.log_dir} -Djava.library.path=/opt/libjpeg-turbo/lib64:/usr/lib64"
else
	node.normal.tomcat.java_options = "-Djava.awt.headless=true -Xms256m -Xmx2G -Xrs -XX:PerfDataSamplingInterval=500 -XX:+UseParallelOldGC -XX:+UseParallelGC -XX:NewRatio=2 -XX:MaxPermSize=256m -XX:SoftRefLRUPolicyMSPerMB=36000 -Dorg.geotools.referencing.forceXY=true -Dorg.geotools.shapefile.datetime=true -DGEOEXPLORER_DATA=#{node.ogeosuite.data_dir}/geoexplorer -DGEOSERVER_LOG_LOCATION=#{node.ogeosuite.geoserver.log_dir}/geoserver.log -DGEOSERVER_AUDIT_PATH=#{node.ogeosuite.geoserver.log_dir} -Djava.library.path=/opt/libjpeg-turbo/lib64:/usr/lib64"
end
node.normal.java.java_home = "/usr/lib/jvm/java"

include_recipe 'chef-vault'

gs_root_auth_info = chef_vault_item("opengeo_suite", "gs_root")
$gs_root_pwd_hash = gs_root_auth_info['hash']
$gs_root_pwd_digest = gs_root_auth_info['password']

gs_admin_auth_info = chef_vault_item("opengeo_suite", "gs_admin")
$gs_admin_pwd_digest = gs_admin_auth_info['hash']
$gs_admin_usr = gs_admin_auth_info['username']
$gs_admin_pwd = gs_admin_auth_info['password']

gs_postgres_auth_info = chef_vault_item("opengeo_suite", "postgres")
$gs_postgres_usr_cfg = gs_postgres_auth_info['username']
$gs_postgres_pwd_cfg = gs_postgres_auth_info['password']

case node[:platform]

	when "centos"

		if !node.ogeosuite.geoserver.init_cluster
			directory node.application_attributes.ogeosuite_dirs.dir

			execute "mkfs -t ext4 #{node.application_attributes.ogeosuite_dirs.dev}" do
				not_if "tune2fs -l #{node.application_attributes.ogeosuite_dirs.dev}"
			end

			mount node.application_attributes.ogeosuite_dirs.dir do
				device node.application_attributes.ogeosuite_dirs.dev
				action [ :mount, :enable ]
			end
		end

		[8080, 8443, 80, 443].each { |port|
		  bash "Allow TCP #{port} through iptables" do
			user "root"
			not_if "/sbin/iptables -nL | egrep '^ACCEPT.*dpt:#{port}($| )'"
			code <<-EOH
			  iptables -I INPUT -p tcp --dport #{port} -j ACCEPT
			  service iptables save
			EOH
		  end
		}

		service "tomcat7" do
			action :nothing
		end

		yum_repository 'boundlessgeo' do
			description 'Opengeo Suite 4.5 CentOS6 Repo'
			baseurl 'http://yum.boundlessgeo.com/suite/v45/centos/6/x86_64'
			enabled true
			gpgcheck false
			notifies :stop, 'service[tomcat7]', :immediately
		end

		["#{node.tomcat.home}/conf/Catalina", "#{node.tomcat.home}/conf/Catalina/localhost"].each do |dir|
			directory dir do
				owner 'tomcat'
				mode '0755'
			end
		end

		['dashboard.xml', 'geoserver.xml', 'opengeo-docs.xml', 'geoexplorer.xml'].each do |templt|
			template "#{node.tomcat.home}/conf/Catalina/localhost/#{templt}" do
				source "#{templt}.erb"
				owner "tomcat"
				group "tomcat"
				mode 0644
			end
		end

		%w{docs examples host-manager manager ROOT}.each do |dir|
			directory "#{node.tomcat.home}/webapps/#{dir}" do
				action :delete
				recursive true
			end
		end

		directory "#{node.tomcat.home}/webapps/ROOT" do
			owner "tomcat"
			group "tomcat"
			mode 0755
		end

		cookbook_file "#{node.tomcat.home}/webapps/ROOT/index.jsp" do
			source "tomcat_index.jsp"
			owner "tomcat"
			group "tomcat"
			mode 0644
		end

		%w{opengeo geoserver-csw geoserver-wps pdal pointcloud-postgresql93 proj-epsg proj-nad proj-static geoserver-geopackage}.each do |pkg|
			package pkg
		end

		["security/masterpw.info", "security/users.properties.old"].each do |file|
			file "#{node.ogeosuite.geoserver.data_dir}/{file}" do
				action :delete
			end
		end

		include_recipe 'java'

		%w{libclib_jiio.so libmlib_jai.so}.each do |file|
			s3_file "#{node.normal.java.java_home}/jre/lib/amd64/#{file}" do
				bucket node.ogeosuite.s3.bucket
				remote_path "#{node.ogeosuite.s3.bucket_path}/jai/#{file}"
				owner 'root'
				group 'root'
				mode 0755
			end
		end

		%w{clibwrapper_jiio.jar jai_codec.jar jai_core.jar jai_imageio.jar mlibwrapper_jai.jar}.each do |file|
			s3_file "#{node.normal.java.java_home}/jre/lib/ext/#{file}" do
				bucket node.ogeosuite.s3.bucket
				remote_path "#{node.ogeosuite.s3.bucket_path}/jai/#{file}"
				owner 'root'
				group 'root'
				mode 0644
			end
		end

		directory "/var/log/geoserver" do
			recursive true
			owner "tomcat"
			group "tomcat"
			mode 0755
		end

		directory "#{Chef::Config[:file_cache_path]}/gs_extensions"

		# geoserver-mongodb
		%w{geoserver-2.6-SNAPSHOT-wms-eo-plugin.zip geoserver-2.6-SNAPSHOT-app-schema-plugin.zip geoserver-2.6-SNAPSHOT-arcsde-plugin.zip geoserver-2.6-SNAPSHOT-feature-pregeneralized-plugin.zip geoserver-2.6-SNAPSHOT-imagemap-plugin.zip geoserver-2.6-SNAPSHOT-imagemosaic-jdbc-plugin.zip 
		   geoserver-2.6-SNAPSHOT-libjpeg-turbo-plugin.zip geoserver-2.6-SNAPSHOT-oracle-plugin.zip geoserver-2.6-SNAPSHOT-pyramid-plugin.zip geoserver-2.6-SNAPSHOT-querylayer-plugin.zip geoserver-2.6-SNAPSHOT-wcs2_0-eo-plugin.zip geoserver-2.6-SNAPSHOT-monitor-hibernate-plugin.zip 
		   geoserver-2.6-SNAPSHOT-monitor-plugin.zip geoserver-2.6-SNAPSHOT-ogr-plugin.zip geoserver-2.6-SNAPSHOT-sqlserver-plugin.zip geoserver-2.6-SNAPSHOT-xslt-plugin.zip geoserver-2.6-SNAPSHOT-printing-plugin.zip geoserver-2.6-SNAPSHOT-gdal-plugin.zip geoserver-2.6-SNAPSHOT-css-plugin.zip
		   geoserver-2.6-SNAPSHOT-sldservice-plugin.zip geoserver-2.6-SNAPSHOT-python-plugin.zip geoserver-2.6-SNAPSHOT-mbtiles-plugin.zip geoserver-2.6-SNAPSHOT-netcdf-plugin.zip geoserver-2.6-SNAPSHOT-netcdf-out-plugin.zip geoserver-2.6-SNAPSHOT-groovy-plugin.zip mongodb.zip}.each do |file|
			s3_file "#{Chef::Config[:file_cache_path]}/gs_extensions/#{file}" do
				bucket node.ogeosuite.s3.bucket
				remote_path "#{node.ogeosuite.s3.bucket_path}/geoserver_extensions/gs_2.6.x/#{file}"
			end
			execute "unzip -u -n #{Chef::Config[:file_cache_path]}/gs_extensions/#{file} -d #{node.ogeosuite.webapps}/geoserver/WEB-INF/lib"
		end

		execute "chown -R tomcat:tomcat #{node.ogeosuite.webapps}; find #{node.ogeosuite.webapps}/geoserver/WEB-INF/lib -type d -exec chmod 755 {} +; find #{node.ogeosuite.webapps}/geoserver/WEB-INF/lib -type f -exec chmod 644 {} +" do
			returns [0,1]
		end

		file "#{node.ogeosuite.webapps}/geoserver/WEB-INF/lib/postgresql-8.4-701.jdbc3.jar" do
			action :delete
		end

		s3_file "#{node.tomcat.lib_dir}/postgresql-9.3-1102.jdbc41.jar" do
			bucket node.ogeosuite.s3.bucket
			remote_path "#{node.ogeosuite.s3.bucket_path}/postgresql-9.3-1102.jdbc41.jar"
			owner "tomcat"
			group "tomcat"
			mode "0644"
		end

		s3_file "#{node.ogeosuite.geoserver.data_dir}/user_projections/esri.properties" do
			bucket node.ogeosuite.s3.bucket
			remote_path "#{node.ogeosuite.s3.bucket_path}/esri.properties"
			owner "tomcat"
			group "tomcat"
			mode "0644"
		end

		node.ogeosuite.supporting_packages.each do |pkg| 
			s3_file "#{Chef::Config[:file_cache_path]}/#{pkg["rpm"]}" do
				bucket node.ogeosuite.s3.bucket
				remote_path "#{node.ogeosuite.s3.bucket_path}/#{pkg["rpm"]}"
			end
			package "#{pkg["name"]}" do
				source "#{Chef::Config[:file_cache_path]}/#{pkg["rpm"]}"
			end
		end

		template "#{node.ogeosuite.geoserver.data_dir}/controlflow.properties" do
			source "controlflow.properties.erb"
			mode 0644
			notifies :restart, 'service[tomcat]', :immediately if File.exists?("/etc/init.d/tomcat")
			notifies :restart, 'service[tomcat7]', :delayed if !File.exists?("/etc/init.d/tomcat")
		end

		%w{mod_xml.py mod_gs_contact.py}.each do |file|
			cookbook_file "#{Chef::Config[:file_cache_path]}/#{file}" do
				source file
			end
		end

		if node.ogeosuite.geoserver.set_pwd == true
			node.ogeosuite.geoserver.pwd_files.each do |file|
				template "#{node.ogeosuite.geoserver.data_dir}/#{file["dir"]}/#{file["fname"]}" do
					source "#{file["fname"]}.erb"
					owner "tomcat"
					group "tomcat"
					mode 0640
				end
			end
		end

		template "#{node.ogeosuite.geoserver.data_dir}/security/config.xml" do
			source "config.xml.erb"
			owner "tomcat"
			group "tomcat"
			mode 0640
			notifies :restart, 'service[tomcat]', :immediately if File.exists?("/etc/init.d/tomcat")
			notifies :restart, 'service[tomcat7]', :delayed if !File.exists?("/etc/init.d/tomcat")
		end

		template "#{node.ogeosuite.webapps}/geoserver/WEB-INF/web.xml" do
				source "nocluster_web.xml.erb"
				owner "tomcat"
				group "tomcat"
				mode 0644
				notifies :restart, 'service[tomcat]', :immediately if File.exists?("/etc/init.d/tomcat")
				notifies :restart, 'service[tomcat7]', :delayed if !File.exists?("/etc/init.d/tomcat")
		end

		%w{wcs.xml wfs.xml}.each do |file|
			cookbook_file "#{node.ogeosuite.geoserver.data_dir}/#{file}" do
				source file
				owner "tomcat"
				group "tomcat"
				mode 0644
			end
		end

		service "tomcat" do
			action [ :stop, :disable ]
			only_if { File.exists?("/etc/init.d/tomcat") }
			retries 4
			retry_delay 10
		end

		ruby_block "Rename tomcat init.d" do
			block do
				File.rename("/etc/init.d/tomcat", "/etc/init.d/tomcat.orig")
			end
			only_if { File.exists?("/etc/init.d/tomcat") }
			notifies :start, 'service[tomcat7]', :immediately
		end

		ruby_block "Wait for #{node.ogeosuite.geoserver.data_dir}/monitoring directory" do
			block do
				retries = 0
				begin
					retries = retries + 1
					sleep 5
				end while !Dir.exist?("#{node.ogeosuite.geoserver.data_dir}/monitoring") and retries < 10
			end
			not_if { Dir.exists?("#{node.ogeosuite.geoserver.data_dir}/monitoring") }
		end

		%w{content.ftl filter.properties footer.ftl header.ftl monitor.properties}.each do |file|
			cookbook_file "#{node.ogeosuite.geoserver.data_dir}/monitoring/#{file}" do
				source "gs_monitor/#{file}"
				owner "tomcat"
				group "tomcat"
				mode 0644
				notifies :restart, 'service[tomcat7]'
			end
		end

		execute "python #{Chef::Config[:file_cache_path]}/mod_xml.py -d #{node.ogeosuite.geoserver.data_dir}"
		execute "python #{Chef::Config[:file_cache_path]}/mod_gs_contact.py -u #{$gs_admin_usr} -p \"#{$gs_admin_pwd}\""

	else
		Chef::Log.info("Unsupported platform #{node[:platform]}")
end
