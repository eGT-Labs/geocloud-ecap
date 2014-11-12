unison_packages = ['unison', 'keychain', 'augeas-tools']

unison_packages.each do |pkg|
  package pkg do
    action :install
  end
end

