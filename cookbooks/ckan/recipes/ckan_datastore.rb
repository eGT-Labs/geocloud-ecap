# Installs and configures the datastore extension
# Must be run after ckan::ckan_base recipe.

ENV['VIRTUAL_ENV'] = node[:ckan][:virtual_env_dir]
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{ENV['VIRTUAL_ENV']}/src"
CKAN_DIR = "#{SOURCE_DIR}/ckan"

=begin
# Create readonly pg user and database
postgresql_user node[:ckan][:datastore][:sql_user] do
  superuser false
  createdb false
  login true
  password node[:ckan][:sql_password]
end
postgresql_database node[:ckan][:datastore][:sql_db_name] do
  owner node[:ckan][:sql_user]
  encoding "utf8"
end
=end
postgresql_connection_info = {
  :host     => '127.0.0.1',
  :port     => 5432,
#  :username => node[:ckan][:sql_user],
  :password => node[:postgresql][:password][:postgres]
}

# Create a less privileged datastore user
postgresql_database_user  node[:ckan][:datastore][:sql_user] do
  connection postgresql_connection_info
  password node[:ckan][:sql_password]
  action :create
end

# create a postgresql database for the datastore with additional parameters
postgresql_database node[:ckan][:datastore][:sql_db_name] do
  connection postgresql_connection_info
  owner node[:ckan][:sql_user]
  encoding "utf8"
  action :create
end

# grant few privileges on all tables in foo db
postgresql_database_user node[:ckan][:sql_user] do
  connection postgresql_connection_info
  database_name node[:ckan][:sql_db_name]
  privileges [:all]
  action :grant
end



# Configure database variables
execute "Set up datastore database write urls" do
  user node[:ckan][:user]
  cwd node[:ckan][:config_dir]
  command "sed -i -e 's/.*datastore.write_url.*/ckan.datastore.write_url=postgresql:\\/\\/#{node[:ckan][:sql_user]}:#{node[:ckan][:sql_password]}@localhost\\/#{node[:ckan][:datastore][:sql_db_name]}/' development.ini"
end
execute "Set up datastore database read urls" do
  user node[:ckan][:user]
  cwd node[:ckan][:config_dir]
  command "sed -i -e 's/.*datastore.read_url.*/ckan.datastore.read_url=postgresql:\\/\\/#{node[:ckan][:datastore][:sql_user]}:#{node[:ckan][:sql_password]}@localhost\\/#{node[:ckan][:datastore][:sql_db_name]}/' development.ini"
end
# Add datastore to ckan.plugins
execute "add datastore to ckan.plugins in configuration" do
  user node[:ckan][:user]
  cwd node[:ckan][:config_dir]
  # first ensure any ' datastore' is removed from line, then add it again.
  command "sed -i -e '/^ckan.plugins.*/ s/ datastore//g;/^ckan.plugins.*/ s/$/ datastore/' development.ini"
end

execute "set permissions" do
  cwd CKAN_DIR
  command "paster --plugin=ckan datastore set-permissions -c #{node[:ckan][:config_dir]}/development.ini | sudo -u postgres psql --set ON_ERROR_STOP=1"
end
