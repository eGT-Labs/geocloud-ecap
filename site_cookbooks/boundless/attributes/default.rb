node.normal.java.java_home = '/usr/lib/jvm/java'
node.normal.java.install_flavor = 'oracle'
node.normal.java.jdk_version = 8
node.normal.java.oracle.accept_oracle_download_terms = true
node.normal.java.oracle.jce.enabled = true

if platform_family?("windows")
	default.suite.java_max_heap_size = '2G'
else
	default.suite.java_max_heap_size = "#{ ( node.memory.total.to_i * 0.6 ).floor / 1024 }m"
end

default.suite.version = 4.6
if node.suite.version == 4
	default.suite.geoserver.version = 2.5
elsif node.suite.version == 4.5
	default.suite.geoserver.version = 2.6
elsif node.suite.version == 4.6
	default.suite.geoserver.version = 2.7
end

default.geoserver.cntrl_flw.timeout = 120
default.geoserver.cntrl_flw.user = 8
default.geoserver.cntrl_flw.ows.global = 300
default.geoserver.cntrl_flw.ows.wcs.getcoverage = 8
default.geoserver.cntrl_flw.ows.wms.getmap = 16
default.geoserver.cntrl_flw.ows.wfs.getfeature.msexcel = 4
default.geoserver.ad.dc1_dns = "dc1.egt.local"
default.geoserver.ad.dc2_dns = "dc2.egt.local"
default.geoserver.ad.domain_cmpnt = "dc=egt,dc=local"
default.geoserver.ad.grp_srch_base = "ou=egt"
default.geoserver.ad.admn_grp = "eGTAdmins"
default.geoserver.ad.netbios_name = "egt"
default.geoserver.ad.admin_role = "ROLE_EGTADMINS"
default.geoserver.ad.enabled = false

default.suite.data_dir = "/var/lib/opengeo"
default.suite.webapps = "/usr/share/opengeo"
default.suite.geoserver.log_dir = "/var/log/geoserver/#{node.ec2.instance_id}"
default.suite.geoserver.data_dir = "#{node.suite.data_dir}/geoserver"
default.suite.geoserver.gwc_dir = "#{node.suite.data_dir}/geowebcache"
default.suite.geoexplorer.data_dir = "#{node.suite.data_dir}/geoexplorer"
default.suite.geoserver.config_db_name = "geoserver_config"
default.suite.geoserver.data_db_name = "geoserver_data"
default.suite.geoserver.set_pwd = false
default.suite.geoserver.init_cluster = false
default.suite.geoserver.init_db = false
default.suite.geoserver.import_cfg_to_postgres = false
default.suite.geoserver.pwd_files = [
    { "fname" => "masterpw.digest", "dir" => "security" },
    { "fname" => "users.xml", "dir" => "security/usergroup/default" }
    #{ "fname" => "passwd", "dir" => "security/masterpw/default" },
]

default.suite.supporting_packages = [
    { "name" => "msttcorefonts", "rpm" => "msttcorefonts-2.5-1.noarch.rpm" },
    { "name" => "libjpeg-turbo-official", "rpm" => "libjpeg-turbo-official-1.4.0.x86_64.rpm" }
]

default.suite.s3_bucket = "geocloud-public"
default.suite.s3_bucket_path = "/Geoserver"

default.suite.auth = [
    { 'data_bag' => 'opengeo_suite', 'data_bag_item' => "gs_root" },
    { 'data_bag' => 'opengeo_suite', 'data_bag_item' => "gs_admin" },
    { 'data_bag' => 'opengeo_suite', 'data_bag_item' => "postgres" }
]

default.application_attributes.suite_dirs = { "dev" => "/dev/xvdf", "dir" => node.suite.data_dir }

default.suite.clstr.cfg_files = [
    { "name" => "jdbcconfig.properties", "directory" => "#{node.suite.geoserver.data_dir}/jdbcconfig",  "owner" => "tomcat"},
    { "name" => "cluster.properties", "directory" => "#{node.suite.geoserver.data_dir}/cluster",  "owner" => "tomcat" },
    { "name" => "hazelcast.xml", "directory" => "#{node.suite.geoserver.data_dir}/cluster",  "owner" => "tomcat" },
    { "name" => "web.xml", "directory" => "#{node.suite.webapps}/geoserver/WEB-INF",  "owner" => "root" }
]

if node.suite.geoserver.init_cluster
	default.suite.glusterfs_base_dir = "#{node.glusterfs.client.mount_path}/opengeo"
end
