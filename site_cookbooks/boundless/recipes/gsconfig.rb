package "git"

git "#{Chef::Config[:file_cache_path]}/gsconfig" do
	repository "https://github.com/boundlessgeo/gsconfig.git"
	#revision "master"
	action :sync
end

execute "python setup.py install" do
	cwd "#{Chef::Config[:file_cache_path]}/gsconfig"
end


