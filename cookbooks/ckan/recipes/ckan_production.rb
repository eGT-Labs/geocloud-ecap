include_recipe "git"
include_recipe "python"
include_recipe "database::postgresql"
include_recipe "postgresql::server"
include_recipe "postgresql::client"
include_recipe "java"
include_recipe "ckan::ckan_base"

# Create a production.ini file.  Use a template so this doesn't blow up in compile phase and we can configure it
=begin
file "#{node[:ckan][:config_dir]}/production.ini" do
  content IO.read("#{node[:ckan][:config_dir]}/development.ini")
  action :create
end
=end

template  "#{node[:ckan][:config_dir]}/production.ini" do
  source "ckan_production_ini.erb"
  owner "ckan"
  group "ckan"
  mode "0644"
end

# Install and configure apache
package "apache2" do
    action :install
end
package "libapache2-mod-rpaf" do
    action :install
end
package "libapache2-mod-wsgi" do
    action :install
end
template "#{node[:ckan][:config_dir]}/apache.wsgi" do
    source "apache.wsgi.erb"
    variables({
        :source_dir => node[:ckan][:virtual_env_dir]
    })
end
template "/etc/apache2/sites-available/ckan_#{node[:ckan][:project_name]}.conf" do
    source "apache_site_tmpl.erb"
    variables({
        :project_name => node[:ckan][:project_name],
        :server_name => node[:apache][:server_name],
        :server_alias => node[:apache][:server_alias],
        :config_dir => node[:ckan][:config_dir]
    })
end
# replace ports.conf
template "/etc/apache2/ports.conf" do
    source "apache_ports_conf.erb"
end
# enable site, and disable default
execute "enable apache site" do
    command "sudo a2ensite ckan_#{node[:ckan][:project_name]}.conf"
end
execute "disable default apache site" do
    command "sudo a2dissite 000-default"
end

# Install and configure Nginx
package "nginx" do
    action :install
end

# Grant permissions on the storage directory to the web server(s)
%w[ node[:ckan][:file_storage_dir] "#{ node[:ckan][:file_storage_dir]}/storage" ].each do |path|
  directory path do
    owner node[:apache][:file_owner]
    group node[:apache][:file_owner]
    mode '0755'
    recursive true
  end
end

# enable site, and disable default
template "/etc/nginx/sites-available/ckan_#{node[:ckan][:project_name]}" do
    source "nginx_site_tmpl.erb"
end
file "/etc/nginx/sites-enabled/default" do
    action :delete
end
link "/etc/nginx/sites-enabled/ckan_#{node[:ckan][:project_name]}" do
  to "/etc/nginx/sites-available/ckan_#{node[:ckan][:project_name]}"
  action :create
end

package "postfix" do
    action :install
end

# give jetty a kick
service "jetty" do
  supports :status => true, :restart => true, :reload => true
  action [:restart]
end

service "apache2" do
  supports :restart => true, :reload => true
  action [:enable, :restart]
end
service "nginx" do
  supports :restart => true, :reload => true
  action [:enable, :restart]
end
include_recipe "ckan::ckan_datastore"
include_recipe "ckan::ckan_datapusher"
