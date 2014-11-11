default['geoserver']['cntrl_flw']['timeout'] = 120
default['geoserver']['cntrl_flw']['user'] = 8
default['geoserver']['cntrl_flw']['ows']['global'] = 300
default['geoserver']['cntrl_flw']['ows']['wcs']['getcoverage'] = 8
default['geoserver']['cntrl_flw']['ows']['wms']['getmap'] = 16
default['geoserver']['cntrl_flw']['ows']['wfs']['getfeature']['msexcel'] = 4
default['geoserver']['ad']['dc1_dns'] = "dc1.egt.local"
default['geoserver']['ad']['dc2_dns'] = "dc2.egt.local"
default['geoserver']['ad']['domain_cmpnt'] = "dc=egt,dc=local"
default['geoserver']['ad']['grp_srch_base'] = "ou=egt"
default['geoserver']['ad']['admn_grp'] = "eGTAdmins"
default['geoserver']['ad']['netbios_name'] = "egt"
default['geoserver']['ad']['admin_role'] = "ROLE_EGTADMINS"
default['geoserver']['ad']['enabled'] = false

default['ogeosuite']['glusterfs_base_dir'] = "#{node.glusterfs.client.mount_path}/opengeo"
default['ogeosuite']['data_dir'] = "/var/lib/opengeo"
default['ogeosuite']['geoserver']['log_dir'] = "/var/log/geoserver/#{node.ec2.instance_id}"
default['ogeosuite']['geoserver']['data_dir'] = "#{node.ogeosuite.data_dir}/geoserver"
default['ogeosuite']['geoserver']['db_name'] = "geoserver"
default['ogeosuite']['geoserver']['set_pwd'] = true
default['ogeosuite']['geoserver']['init_cluster'] = false
default['ogeosuite']['geoserver']['init_db'] = false
default['ogeosuite']['geoserver']['import_cfg_to_postgres'] = false
default['ogeosuite']['geoserver']['pwd_files'] = [
    { "fname" => "masterpw.digest", "dir" => "security" },
    { "fname" => "users.xml", "dir" => "security/usergroup/default" }
    #{ "fname" => "passwd", "dir" => "security/masterpw/default" },
]

default['ogeosuite']['webapps'] = node.tomcat.app_base
default['ogeosuite']['supporting_packages'] = [
    { "name" => "msttcorefonts", "rpm" => "msttcorefonts-2.5-1.noarch.rpm" },
    { "name" => "libjpeg-turbo-official", "rpm" => "libjpeg-turbo-official-1.3.90.x86_64.rpm" }
]

default["ogeosuite"]["s3"]["bucket"] = "geocloud-public"
default["ogeosuite"]["s3"]["bucket_path"] = "/Geoserver"

default['ogeosuite']['auth'] = [
    { 'data_bag' => 'opengeo_suite', 'data_bag_item' => "gs_root" },
    { 'data_bag' => 'opengeo_suite', 'data_bag_item' => "gs_admin" },
    { 'data_bag' => 'opengeo_suite', 'data_bag_item' => "postgres" }
]

default['application_attributes']['ogeosuite_dirs'] = { "dev" => "/dev/xvdf", "dir" => node.ogeosuite.data_dir }

default['ogeosuite']['clstr']['cfg_files'] = [
    { "name" => "jdbcconfig.properties", "directory" => "#{node.ogeosuite.geoserver.data_dir}/jdbcconfig",  "owner" => "tomcat"},
    { "name" => "cluster.properties", "directory" => "#{node.ogeosuite.geoserver.data_dir}/cluster",  "owner" => "tomcat" },
    { "name" => "hazelcast.xml", "directory" => "#{node.ogeosuite.geoserver.data_dir}/cluster",  "owner" => "tomcat" },
    { "name" => "web.xml", "directory" => "#{node.ogeosuite.webapps}/geoserver/WEB-INF",  "owner" => "root" }
]

node.normal.tomcat.jndi_datasource_name = "gscatalog"
node.normal.tomcat.jndi_driver = "org.postgresql.Driver"
node.normal.tomcat.jndi_connection_string = "postgresql://#{node.deployment.databases.postgis.endpoint}:#{node.deployment.databases.postgis.port}/#{node.ogeosuite.geoserver.db_name}"
#node.normal.tomcat.jndi_user = $gs_postgres_usr_cfg
#node.normal.tomcat.jndi_password = $gs_postgres_pwd_cfg
node.normal.tomcat.jndi_max_active = 40
node.normal.tomcat.jndi_max_idle = 10
node.normal.tomcat.jndi_max_wait = -1
