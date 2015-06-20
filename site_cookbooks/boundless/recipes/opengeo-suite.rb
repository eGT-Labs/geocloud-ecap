#
# Cookbook Name:: boundless
# Recipe::opengeo-suite
#

if node.java.jdk_version == 8
	node.normal.tomcat.java_options = "-Djava.awt.headless=true -Xms256m -Xmx#{node.suite.java_max_heap_size} -Xrs -XX:PerfDataSamplingInterval=500 -XX:+UseParallelOldGC -XX:+UseParallelGC -XX:NewRatio=2 -XX:SoftRefLRUPolicyMSPerMB=36000 -Dorg.geotools.referencing.forceXY=true -Dorg.geotools.shapefile.datetime=true -DGEOEXPLORER_DATA=#{node.suite.geoexplorer.data_dir} -DGEOSERVER_LOG_LOCATION=#{node.suite.geoserver.log_dir}/geoserver.log -DGEOSERVER_AUDIT_PATH=#{node.suite.geoserver.log_dir} -Djava.library.path=/opt/libjpeg-turbo/lib64:/usr/lib64"
else
	node.normal.tomcat.java_options = "-Djava.awt.headless=true -Xms256m -Xmx#{node.suite.java_max_heap_size} -Xrs -XX:PerfDataSamplingInterval=500 -XX:+UseParallelOldGC -XX:+UseParallelGC -XX:NewRatio=2 -XX:MaxPermSize=256m -XX:SoftRefLRUPolicyMSPerMB=36000 -Dorg.geotools.referencing.forceXY=true -Dorg.geotools.shapefile.datetime=true -DGEOEXPLORER_DATA=#{node.suite.geoexplorer.data_dir} -DGEOSERVER_LOG_LOCATION=#{node.suite.geoserver.log_dir}/geoserver.log -DGEOSERVER_AUDIT_PATH=#{node.suite.geoserver.log_dir} -Djava.library.path=/opt/libjpeg-turbo/lib64:/usr/lib64"
end

include_recipe 'chef-vault'
include_recipe 'boundless::postgres_db' if node.application_attributes.create_db

# Vaults commented out per Ami 4/23/15, probably back in soon

#gs_root_auth_info = chef_vault_item("opengeo_suite", "gs_root")
#$gs_root_pwd_hash = gs_root_auth_info['hash']
#$gs_root_pwd_digest = gs_root_auth_info['password']

gs_admin_auth_info = chef_vault_item("opengeo_suite", "gs_admin")
# $gs_admin_pwd_digest = gs_admin_auth_info['hash']
$gs_admin_usr = gs_admin_auth_info['username']
$gs_admin_pwd = gs_admin_auth_info['password']

case node[:platform]
when "centos"

	if !node.suite.geoserver.init_cluster
		directory node.application_attributes.suite_dirs.dir

		execute "mkfs -t ext4 #{node.application_attributes.suite_dirs.dev}" do
			not_if "tune2fs -l #{node.application_attributes.suite_dirs.dev}"
		end

		mount node.application_attributes.suite_dirs.dir do
			device node.application_attributes.suite_dirs.dev
			action [ :mount, :enable ]
		end
	end

	[8080, 8443].each { |port|
		execute "iptables -I INPUT -p tcp --dport #{port} -j ACCEPT; service iptables save" do
			not_if "iptables -nL | egrep '^ACCEPT.*dpt:#{port}($| )'"
		end
	}

	service "tomcat7" do
		action :nothing
	end

	[node.java.oracle.jce.home, File.join(node.java.oracle.jce.home, node.java.jdk_version.to_s)].each do |path|
		directory path do
			mode 0755
		end
	end

	yum_repository 'boundlessgeo' do
		description 'Opengeo Suite 4.5 CentOS6 Repo'
		baseurl 'http://yum.boundlessgeo.com/suite/v45/centos/6/x86_64'
		enabled true
		gpgcheck false
		notifies :stop, 'service[tomcat7]', :immediately
	end

	["#{node.tomcat.home}/conf/Catalina", "#{node.tomcat.home}/conf/Catalina/localhost"].each { |dir|
		directory dir do
			owner 'tomcat'
			group 'tomcat'
			mode 0755
		end
	}

	%w{dashboard.xml geoserver.xml opengeo-docs.xml geoexplorer.xml}.each { |templt|
		template "#{node.tomcat.home}/conf/Catalina/localhost/#{templt}" do
			source "#{templt}.erb"
			owner 'tomcat'
			group 'tomcat'
			mode 0644
		end
	}

	%w{docs examples host-manager manager ROOT}.each { |dir|
		directory "#{node.tomcat.home}/webapps/#{dir}" do
			action :delete
			recursive true
		end
	}

	directory "#{node.tomcat.home}/webapps/ROOT" do
		owner 'tomcat'
		group 'tomcat'
		mode 0755
	end

	cookbook_file "#{node.tomcat.home}/webapps/ROOT/index.jsp" do
		source "tomcat_index.jsp"
		owner 'tomcat'
		group 'tomcat'
		mode 0644
	end

	%w{opengeo geoserver-csw geoserver-wps pdal pointcloud-postgresql93 proj-epsg proj-nad proj-static geoserver-geopackage vim}.each { |pkg|
		package pkg
	}

	%w{security/masterpw.info security/users.properties.old}.each { |file|
		file "#{node.suite.geoserver.data_dir}/#{file}" do
			action :delete
		end
	}

	include_recipe 'java'

	%w{libclib_jiio.so libmlib_jai.so}.each { |file|
		s3_file "#{node.normal.java.java_home}/jre/lib/amd64/#{file}" do
			bucket node.suite.s3_bucket
			remote_path "#{node.suite.s3_bucket_path}/jai/#{file}"
			owner 'root'
			group 'root'
			mode 0755
		end
	}

	%w{clibwrapper_jiio.jar jai_codec.jar jai_core.jar jai_imageio.jar mlibwrapper_jai.jar}.each { |file|
		s3_file "#{node.normal.java.java_home}/jre/lib/ext/#{file}" do
			bucket node.suite.s3_bucket
			remote_path "#{node.suite.s3_bucket_path}/jai/#{file}"
			owner 'root'
			group 'root'
			mode 0644
		end
	}

	# %w{local_policy.jar US_export_policy.jar}.each do |file|
		# s3_file "#{node.java.java_home}/jre/lib/security/#{file}" do
			# bucket node.suite.s3_bucket
			# remote_path "#{node.suite.s3_bucket_path}/#{file}"
			# owner "root"
			# mode "0644"
		# end
	# end

	directory "/var/log/geoserver" do
		recursive true
		owner 'tomcat'
		group 'tomcat'
		mode 0755
	end

	directory "#{Chef::Config[:file_cache_path]}/gs_extensions"

	[
		"geoserver-#{node.suite.geoserver.version}-SNAPSHOT-feature-pregeneralized-plugin.zip", "geoserver-#{node.suite.geoserver.version}-SNAPSHOT-imagemap-plugin.zip", "geoserver-#{node.suite.geoserver.version}-SNAPSHOT-imagemosaic-jdbc-plugin.zip",
		"geoserver-#{node.suite.geoserver.version}-SNAPSHOT-libjpeg-turbo-plugin.zip", "geoserver-#{node.suite.geoserver.version}-SNAPSHOT-pyramid-plugin.zip",  "geoserver-#{node.suite.geoserver.version}-SNAPSHOT-ogr-plugin.zip", 
		"geoserver-#{node.suite.geoserver.version}-SNAPSHOT-xslt-plugin.zip", "geoserver-#{node.suite.geoserver.version}-SNAPSHOT-printing-plugin.zip", "geoserver-#{node.suite.geoserver.version}-SNAPSHOT-gdal-plugin.zip", 
		"geoserver-#{node.suite.geoserver.version}-SNAPSHOT-css-plugin.zip", "geoserver-#{node.suite.geoserver.version}-SNAPSHOT-sldservice-plugin.zip"
	].each do |file|
	# geoserver-mongodb
		s3_file "#{Chef::Config[:file_cache_path]}/gs_extensions/#{file}" do
			bucket node.suite.s3_bucket
			remote_path "#{node.suite.s3_bucket_path}/geoserver_extensions/gs_#{node.suite.geoserver.version}.x/#{file}"
		end
		execute "unzip -u -n #{Chef::Config[:file_cache_path]}/gs_extensions/#{file} -d #{node.suite.webapps}/geoserver/WEB-INF/lib"
	end

	execute "chown -R tomcat:tomcat #{node.suite.webapps}; find #{node.suite.webapps}/geoserver/WEB-INF/lib -type d -exec chmod 755 {} +; find #{node.suite.webapps}/geoserver/WEB-INF/lib -type f -exec chmod 644 {} +" do
		returns [0, 1]
	end

	file "#{node.suite.webapps}/geoserver/WEB-INF/lib/postgresql-8.4-701.jdbc3.jar" do
		action :delete
	end

	s3_file "#{node.tomcat.lib_dir}/postgresql-9.4-1201.jdbc41.jar" do
		bucket node.suite.s3_bucket
		remote_path "#{node.suite.s3_bucket_path}/postgresql-9.4-1201.jdbc41.jar"
		owner 'tomcat'
		group 'tomcat'
		mode 0644
	end

	s3_file "#{node.suite.geoserver.data_dir}/user_projections/esri.properties" do
		bucket node.suite.s3_bucket
		remote_path "#{node.suite.s3_bucket_path}/esri.properties"
		owner 'tomcat'
		group 'tomcat'
		mode 0644
	end

	node.suite.supporting_packages.each { |pkg| 
		s3_file "#{Chef::Config[:file_cache_path]}/#{pkg["rpm"]}" do
			bucket node.suite.s3_bucket
			remote_path "#{node.suite.s3_bucket_path}/#{pkg["rpm"]}"
		end
		
		package "#{pkg["name"]}" do
			source "#{Chef::Config[:file_cache_path]}/#{pkg["rpm"]}"
		end
	}

	template "#{node.suite.geoserver.data_dir}/controlflow.properties" do
		source "controlflow.properties.erb"
		mode 0644
		notifies :restart, 'service[tomcat]', :immediately if File.exists?("/etc/init.d/tomcat")
		notifies :restart, 'service[tomcat7]', :delayed if !File.exists?("/etc/init.d/tomcat")
	end

	%w{mod_xml.py mod_gs_contact.py}.each { |file|
		cookbook_file "#{Chef::Config[:file_cache_path]}/#{file}" do
			source file
		end
	}

	if node.suite.geoserver.set_pwd == true
		node.suite.geoserver.pwd_files.each { |file|
			template "#{node.suite.geoserver.data_dir}/#{file["dir"]}/#{file["fname"]}" do
				source "#{file["fname"]}.erb"
				owner 'tomcat'
				group 'tomcat'
				mode 0640
			end
		}
	end

	template "#{node.suite.geoserver.data_dir}/security/config.xml" do
		source "config.xml.erb"
		owner 'tomcat'
		group 'tomcat'
		mode 0640
		notifies :restart, 'service[tomcat]', :immediately if File.exists?("/etc/init.d/tomcat")
		notifies :restart, 'service[tomcat7]', :delayed if !File.exists?("/etc/init.d/tomcat")
	end

	template "#{node.suite.webapps}/geoserver/WEB-INF/web.xml" do
		source "nocluster_web.xml.erb"
		owner 'tomcat'
		group 'tomcat'
		mode 0644
		notifies :restart, 'service[tomcat]', :immediately if File.exists?("/etc/init.d/tomcat")
		notifies :restart, 'service[tomcat7]', :delayed if !File.exists?("/etc/init.d/tomcat")
	end

	%w{wcs.xml wfs.xml}.each { |file|
		cookbook_file "#{node.suite.geoserver.data_dir}/#{file}" do
			source file
			owner 'tomcat'
			group 'tomcat'
			mode 0644
		end
	}

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

	ruby_block "Wait for #{node.suite.geoserver.data_dir}/monitoring directory" do
		block do
			retries = 0
			begin
				retries = retries + 1
				sleep 5
			end while !Dir.exist?("#{node.suite.geoserver.data_dir}/monitoring") and retries < 10
		end
		not_if { Dir.exists?("#{node.suite.geoserver.data_dir}/monitoring") }
	end

	%w{content.ftl filter.properties footer.ftl header.ftl monitor.properties}.each { |file|
		cookbook_file "#{node.suite.geoserver.data_dir}/monitoring/#{file}" do
			source "gs_monitor/#{file}"
			owner 'tomcat'
			group 'tomcat'
			mode 0644
			notifies :restart, 'service[tomcat7]'
		end
	}

	execute "python #{Chef::Config[:file_cache_path]}/mod_xml.py -d #{node.suite.geoserver.data_dir}"
	execute "python #{Chef::Config[:file_cache_path]}/mod_gs_contact.py -u #{$gs_admin_usr} -p \"#{$gs_admin_pwd}\""

else
	Chef::Log.info("Unsupported platform #{node[:platform]}")
end
