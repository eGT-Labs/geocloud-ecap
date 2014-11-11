#
# Cookbook Name:: boundless
# Recipe::opengeo-suite-ad
#

::Chef::Recipe.send(:include, Chef::Mixin::ShellOut)

node.normal.geoserver.ad.enabled = true

case node[:platform]
    when "centos"

		role_id = shell_out("grep '<id>' #{node.ogeosuite.geoserver.data_dir}/security/role/ad/config.xml")
		if role_id.stdout.empty?
			$ad_role_id = "<id>33516643:148c9b995fe:-8000</id>"
		else
			$ad_role_id = role_id.stdout
		end

		provider_id = shell_out("grep '<id>' #{node.ogeosuite.geoserver.data_dir}/security/auth/ad/config.xml")
		if provider_id.stdout.empty?
			$ad_provider_id = "<id>-6143a188:148c98eb412:-8000</id>"
		else
			$ad_provider_id = provider_id.stdout
		end

		%w{role auth}.each do |type|
			directory "#{node.ogeosuite.geoserver.data_dir}/security/#{type}/ad" do
				recursive true
				owner "tomcat"
				group "tomcat"
				mode 0750
			end
			template "#{node.ogeosuite.geoserver.data_dir}/security/#{type}/ad/config.xml" do
				source "gs_ad/config_#{type}.xml.erb"
				owner "tomcat"
				group "tomcat"
				mode 0640
			end
		end
        service "tomcat7" do
            action :restart
			#not_if  { File.exists?("#{node.ogeosuite.geoserver.data_dir}/cluster") }
        end

    else
        Chef::Log.info("Unsupported platform #{node[:platform]}")
end
