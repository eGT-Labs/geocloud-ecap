default['rogue']['debug'] = true
default['rogue']['version'] = 'v0.1a'

node.normal.postgresql.enable_pgdg_apt = true

# Override pgsql version and dependent attributes, per https://www.chef.io/blog/2013/12/03/doing-wrapper-cookbooks-right/
# These will need to be made deployment-specific to handle CentOS later on. Note directory from arahav
default['postgresql']['version'] = '9.4'
default['postgresql']['client']['packages'] = ["postgresql-client-#{node.postgresql.version}", "libpq-dev"]
default['postgresql']['server']['packages'] = ["postgresql-#{node.postgresql.version}"]
default['postgresql']['contrib']['packages'] = ["postgresql-contrib-#{node.postgresql.version}"]
default['postgresql']['dir'] = "/var/lib/postgresql/#{node.postgresql.version}/main"
default['postgresql']['server']['servicename'] = "postgresql-#{node.postgresql.version}"

default['postgis']['version'] = '2.1'
default['postgis']['template_name'] = 'template_postgis'
default['postgis']['locale'] = 'en_US.utf8'

default['rogue']['postgresql']['user'] = 'postgres'
default['rogue']['postgresql']['password'] = node.fetch('postgresql',{}).fetch('password', {}).fetch('postgres', 'rogue')
default['rogue']['postgresql']['port'] = node.fetch('postgresql',{}).fetch('config', {}).fetch('port', '5432')
default['rogue']['postgresql']['install_from_source'] = false
default['rogue']['postgis']['install_from_source'] = false

default['rogue']['install_docs'] = true
default['rogue']['logging']['location'] = '/var/log/rogue'
default['rogue']['setup_db'] = true

default['rogue']['networking']['database']['address'] = '127.0.0.1'

default['rogue']['rogue_geonode']['public_address'] = node.ec2.public_dns_name

default['rogue']['geoserver']['build_from_source'] = false
default['rogue']['geoserver']['use_db_client'] = true
default['rogue']['geoserver']['base_url'] = '/geoserver'
default['rogue']['geoserver']['data_dir'] = '/var/lib/geoserver_data'
default['rogue']['geoserver']['jai']['url'] = "http://download.java.net/media/jai/builds/release/1_1_3/jai-1_1_3-lib-linux-amd64-jdk.bin"
default['rogue']['geoserver']['jai_io']['url'] = "http://download.java.net/media/jai-imageio/builds/release/1.1/jai_imageio-1_1-lib-linux-amd64-jdk.bin"
default['rogue']['geoserver']['url']= "http://#{node.rogue.rogue_geonode.public_address}#{node['rogue']['geoserver']['base_url']}/"
default['rogue']['geoserver']['war'] = "http://jenkins.rogue.lmnsolutions.com/job/geoserver/lastSuccessfulBuild/artifact/geoserver_ext/target/geoserver.war"

default['rogue']['geoserver_data']['url'] = 'https://github.com/DistributedOpenUnifiedGovernmentNetwork/geoserver_data.git'
default['rogue']['geoserver_data']['branch'] = "#{node.rogue.version}"

default['rogue']['geonode']['location'] = '/var/lib/geonode/'
default['rogue']['interpreter'] = ::File.join(node['rogue']['geonode']['location'], 'bin/python')
default['rogue']['django_maploom']['auto_upgrade'] = true
default['rogue']['django_maploom']['url'] = "git+https://github.com/DistributedOpenUnifiedGovernmentNetwork/django-maploom.git#egg=django-maploom"
default['rogue']['geonode']['location'] = '/var/lib/geonode/'
default['rogue']['rogue_geonode']['branch'] = "#{node.rogue.version}"
default['rogue']['rogue_geonode']['python_packages'] = ["uwsgi", "psycopg2"]
default['rogue']['rogue_geonode']['location'] = File.join(node['rogue']['geonode']['location'], 'rogue_geonode')
default['rogue']['rogue_geonode']['url'] = 'https://github.com/DistributedOpenUnifiedGovernmentNetwork/rogue_geonode.git'
default['rogue']['rogue_geonode']['fixtures'] = ['sample_admin.json',]
default['rogue']['rogue_geonode']['settings']['ALLOWED_HOSTS'] = [node['ipaddress'], 'localhost', node.rogue.rogue_geonode.public_address]
default['rogue']['rogue_geonode']['settings']['PROXY_ALLOWED_HOSTS'] = ['*', '.lmnsolutions.com', '.openstreetmap.org']
default['rogue']['rogue_geonode']['settings']['REGISTATION_OPEN'] = false
default['rogue']['rogue_geonode']['settings']['SERVER_EMAIL'] = "server@test.local"
default['rogue']['rogue_geonode']['settings']['DEFAULT_FROM_EMAIL'] = "webmaster@test.loca"
default['rogue']['rogue_geonode']['settings']['ADMINS'] = [['ROGUE', 'ROGUE@lmnsolutions.com'],]
default['rogue']['rogue_geonode']['settings']['SITEURL'] = "http://#{node.rogue.rogue_geonode.public_address}"
default['rogue']['rogue_geonode']['settings']['OGC_SERVER']['LOCATION'] = node['rogue']['geoserver']['url']
default['rogue']['rogue_geonode']['settings']['OGC_SERVER']['PUBLIC_LOCATION'] = node['rogue']['geoserver']['url']
default['rogue']['rogue_geonode']['settings']['OGC_SERVER']['DATASTORE'] = ""
default['rogue']['rogue_geonode']['settings']['OGC_SERVER']['GEOGIT_DATASTORE_DIR'] = ::File.join(node['rogue']['geoserver']['data_dir'], 'geogit')
default['rogue']['rogue_geonode']['settings']['OGC_SERVER']['USER'] = "admin"
default['rogue']['rogue_geonode']['settings']['OGC_SERVER']['PASSWORD'] = "geoserver"
default['rogue']['rogue_geonode']['settings']['UPLOADER']['BACKEND'] = 'geonode.importer'
default['rogue']['rogue_geonode']['settings']['STATIC_ROOT'] = '/var/www/rogue'
default['rogue']['rogue_geonode']['settings']['MEDIA_ROOT'] = '/var/www/rogue/media'
default['rogue']['nginx']['locations'] = {}

default['rogue']['rogue_geonode']['settings']['DATABASES'] = {
    :default=>{:name=>'geonode', :user=>'geonode', :password=>'geonode', :host=>node.rogue.networking.database.address, :port=>'5432'},
    :geonode_imports=>{:name=>'geonode_imports', :user=>'geonode', :password=>'geonode', :host=>node.rogue.networking.database.address, :port=>'5432'}
    }
default['rogue']['geogit']['build_from_source'] = false
default['rogue']['geogit']['branch'] = "#{node.rogue.version}"

if node['rogue']['geogit']['build_from_source']
  default['rogue']['geogit']['url'] = 'https://github.com/DistributedOpenUnifiedGovernmentNetwork/GeoGit.git'
else
  default['rogue']['geogit']['url'] = 'http://jenkins.rogue.lmnsolutions.com/job/geogit/lastSuccessfulBuild/artifact/src/cli-app/target/geogit-cli-app.zip'
end

default['rogue']['geogit']['global_configuration'] = {"user"=> {"name"=>"rogue",
                                                                "email"=>"rogue@lmnsolutions.com"},
                                                      "bdbje"=> {"object_durability"=>"safe"}
                                                      }
default['rogue']['geogit']['location'] = '/var/lib/geogit'


default['rogue']['geoeserver-exts']['branch'] = '2.4.x'
default['rogue']['geoeserver-exts']['location'] = '/var/lib/geoserver-exts'
default['rogue']['geoeserver-exts']['url'] = 'https://github.com/DistributedOpenUnifiedGovernmentNetwork/geoserver-exts.git'
default['rogue']['tomcat']['log_dir'] = "${catalina.base}/logs"

default['rogue']['rogue_geonode']['settings']['CLASSIFICATION_BANNER_ENABLED'] = false
default['rogue']['rogue_geonode']['settings']['CLASSIFICATION_TEXT_COLOR'] = nil
default['rogue']['rogue_geonode']['settings']['CLASSIFICATION_BACKGROUND_COLOR'] = nil
default['rogue']['rogue_geonode']['settings']['CLASSIFICATION_TEXT'] = nil

default['rogue']['stig']['url'] = 'https://github.com/DistributedOpenUnifiedGovernmentNetwork/stig.git'
default['rogue']['stig']['branch'] = "#{node.rogue.version}"

default['rogue']['rogue-scripts']['branch'] = "#{node.rogue.version}"
default['rogue']['rogue-scripts']['location'] = '/opt/rogue-scripts'
default['rogue']['rogue-scripts']['url'] = 'https://github.com/DistributedOpenUnifiedGovernmentNetwork/rogue-scripts.git'

if node['rogue']['version'] == 'v0.1a'
  default['rogue']['rogue_geonode']['branch'] = "#{node.rogue.version}"
  default['rogue']['geoserver_data']['branch'] = "#{node.rogue.version}"
  default['rogue']['django_maploom']['auto_upgrade'] = false
  default['rogue']['geoserver']['war'] = "http://jenkins.rogue.lmnsolutions.com/userContent/geoshape-1.x/geoserver.war"

  if node['rogue']['geogit']['build_from_source']
    default['rogue']['geogit']['url'] = 'https://github.com/boundlessgeo/GeoGig.git'
    default['rogue']['geogit']['branch'] = '0.10.x'
  else
    default['rogue']['geogit']['url'] = 'http://jenkins.rogue.lmnsolutions.com/userContent/geoshape-1.x/geogit-cli-app-0.1.zip'
  end

end
