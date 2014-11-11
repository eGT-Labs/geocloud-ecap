#
# Cookbook Name:: boundless
# Recipe::opengeo-suite
#

node.normal.tomcat.app_base = "/usr/share/opengeo"
node.normal.tomcat.java_options = "-Djava.awt.headless=true -Xms256m -Xmx2G -Xrs -XX:PerfDataSamplingInterval=500 -XX:+UseParallelOldGC -XX:+UseParallelGC -XX:NewRatio=2 -XX:MaxPermSize=256m -XX:SoftRefLRUPolicyMSPerMB=36000 -Dorg.geotools.referencing.forceXY=true -Dorg.geotools.shapefile.datetime=true -DGEOEXPLORER_DATA=#{node.ogeosuite.data_dir}/geoexplorer -DGEOSERVER_LOG_LOCATION=#{node.ogeosuite.geoserver.log_dir}/geoserver.log -DGEOSERVER_AUDIT_PATH=#{node.ogeosuite.geoserver.log_dir} -Djava.library.path=/opt/libjpeg-turbo/lib64:/usr/lib64"
node.normal.java.java_home = "/usr/lib/jvm/java"
node.normal.ogeosuite.webapps = node.tomcat.app_base

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
        
		if !ogeosuite.geoserver.init_cluster
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
            action :stop
            not_if "rpm -qa | grep opengeo-server"
        end
        
        yum_repository 'boundlessgeo' do
            description 'Opengeo Suite 4.x CentOS6 Repo'
            baseurl 'http://yum.opengeo.org/suite/v4/centos/6/x86_64'
            enabled true
            gpgcheck false
            action :create
        end

        %w{opengeo-jai opengeo gdal-filegdb geoserver-css geoserver-csw geoserver-gdal geoserver-wps pdal pointcloud-postgresql93 proj-epsg proj-nad proj-static geoserver-mongodb geoserver-geopackage}.each do |pkg|
            package pkg
        end

        ["#{node.ogeosuite.geoserver.data_dir}/security/masterpw.info", "#{node.ogeosuite.geoserver.data_dir}/security/users.properties.old"].each do |file|
            file file do
                action :delete
            end
        end

        include_recipe 'java'

        %w{local_policy.jar US_export_policy.jar}.each do |file|
            s3_file "#{node.java.java_home}/jre/lib/security/#{file}" do
                bucket node.ogeosuite.s3.bucket
                remote_path "#{node.ogeosuite.s3.bucket_path}/#{file}"
                owner "root"
                mode "0644"
            end
        end

        directory "/var/log/geoserver" do
            recursive true
            owner "tomcat"
            group "tomcat"
            mode 0755
        end

        directory "#{Chef::Config[:file_cache_path]}/gs_extensions"
        %w{geoserver-2.5-SNAPSHOT-wms-eo-plugin.zip geoserver-2.5.2-app-schema-plugin.zip geoserver-2.5.2-arcsde-plugin.zip geoserver-2.5.2-feature-pregeneralized-plugin.zip geoserver-2.5.2-imagemap-plugin.zip geoserver-2.5.2-imagemosaic-jdbc-plugin.zip 
           geoserver-2.5.2-libjpeg-turbo-plugin.zip geoserver-2.5.2-oracle-plugin.zip geoserver-2.5.2-pyramid-plugin.zip geoserver-2.5.2-querylayer-plugin.zip geoserver-2.5.2-wcs2_0-eo-plugin.zip geoserver-2.5.2-monitor-hibernate-plugin.zip geoserver-2.5.2-monitor-plugin.zip}.each do |file|
            s3_file "#{Chef::Config[:file_cache_path]}/gs_extensions/#{file}" do
                bucket node.ogeosuite.s3.bucket
                remote_path "#{node.ogeosuite.s3.bucket_path}/geoserver_extensions/gs_2.5.x/#{file}"
            end
            execute "unzip -u #{Chef::Config[:file_cache_path]}/gs_extensions/#{file}" do
                cwd "#{node.ogeosuite.webapps}/geoserver/WEB-INF/lib"
            end
        end

        Dir.glob("#{node.ogeosuite.webapps}/geoserver/WEB-INF/lib/*.jar") do |file|
            file file do
                owner "root"
                mode "0644"
            end
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
                #notifies :install, "package[msttcorefonts]"
            end
            package "#{pkg["name"]}" do
                source "#{Chef::Config[:file_cache_path]}/#{pkg["rpm"]}"
                #action :nothing
            end
        end
        
        template "#{node.ogeosuite.geoserver.data_dir}/controlflow.properties" do
            source "controlflow.properties.erb"
            mode 0644
            # notifies [ :stop, :disable ], 'service[tomcat6]'
            # notifies :start, 'service[tomcat7]'
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
					sensitive true
                end
            end
        end
        
        template "#{node.ogeosuite.geoserver.data_dir}/security/config.xml" do
            source "config.xml.erb"
            owner "tomcat"
            group "tomcat"
            mode 0640
        end

        %w{wcs.xml wfs.xml}.each do |file|
            cookbook_file "#{node.ogeosuite.geoserver.data_dir}/#{file}" do
                source file
                owner "tomcat"
                group "tomcat"
                mode 0644
            end
        end

        service "tomcat6" do
            action [ :stop, :disable ]
            only_if  { File.exists?("/etc/init.d/tomcat6") }
        end
        
        ruby_block "Rename Tomcat6 init.d" do
            block do
                ::File.rename("/etc/init.d/tomcat6", "/etc/init.d/tomcat6.orig")
            end
            only_if  { File.exists?("/etc/init.d/tomcat6") }
        end

        service "tomcat7" do
            action [ :enable, :start ]
            only_if "service tomcat7 status | grep stopped"
            notifies :run, "execute[wait for tomcat7]", :immediately
            retries 4
            retry_delay 30
        end

        execute "wait for tomcat7" do
            command 'sleep 10'
            action :nothing
        end

        execute "sleep 45" do
            not_if  { File.exists?("#{node.ogeosuite.geoserver.data_dir}/monitoring") }
        end

        service "tomcat7" do
            action :restart
            not_if  { File.exists?("#{node.ogeosuite.geoserver.data_dir}/monitoring") }
        end

        %w{content.ftl filter.properties footer.ftl header.ftl monitor.properties}.each do |file|
            cookbook_file "#{node.ogeosuite.geoserver.data_dir}/monitoring/#{file}" do
                source "gs_monitor/#{file}"
                owner "tomcat"
                group "tomcat"
                mode 0644
            end
        end
        
        execute "python #{Chef::Config[:file_cache_path]}/mod_xml.py -d #{node.ogeosuite.geoserver.data_dir}" do
			sensitive true
		end
        execute "python #{Chef::Config[:file_cache_path]}/mod_gs_contact.py -u #{$gs_admin_usr} -p #{$gs_admin_pwd}" do
			sensitive true
		end

    when "ubuntu"
        apt_repository "boundlessgeo" do
            uri "http://apt.opengeo.org/suite/v4/ubuntu/"
            distribution node['lsb']['codename']
            components ["main"]
            key 'http://apt.opengeo.org/gpg.key'
            action :add
        end
        ['opengeo'].each { |pkg|
            package pkg do
                action :install
          end
        }
    else
        Chef::Log.info("Unsupported platform #{node[:platform]}")
end
