gem_package "ruby-shadow" do
  action :install
end

user $rogue_os_usr do
  home '/home/rogue'
  supports :manage_home => true
  shell '/bin/bash'
  password $rogue_os_pwd
  sensitive true
end

group "rogue" do
  action :create
  append true
  members "rogue"
end

group "sudo" do
  action :modify
  members "rogue"
  append true
end

group "roguecat" do
  action :create
  append true
  members "rogue"
end

user $unison_os_usr do
  shell '/bin/bash'
  home '/home/unison'
  password $unison_os_pwd
  sensitive true
end

user 'www-data' do
  action :create
  system true
  shell  '/bin/false'
  home   '/var/www'
end

group "www-data" do
  action :create
  append true
  members "www-data"
end

directory '/var/www' do
  group "rogue"
  owner "www-data"
  mode 0755
end