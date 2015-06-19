README.md

#### Create a vault
`knife vault create opengeo_suite gs_admin '{"username": "admin", "password": "geoserver"}'`
Geoserver doesn't support changing the password(s) via the REST API. After changing the default you will have to update password(s) in your vault.
To get around that you can store the hash of the password(s) in a vault, and change `default.suite.geoserver.set_pwd = false` to `default.suite.geoserver.set_pwd = true`

#### Deploy a complete stack
Will create a VPC and a bastion. and deploy the OpenGeo instance in the new VPC 
Use azskip only if there is a none functional availability zone in your account  
`mu-deploy /opt/mu/var/geocloud_platform/applications/opengeo_suite/master.yml -p azskip=us-east-1a`

#### Deploy OpenGeo Suite only
Will deploy into an existing stack without creating a VPC and a bastion. No need to use azskip
You will have to create the VPC separately. See the VPC section.
`mu-deploy /opt/mu/var/geocloud_platform/applications/opengeo_suite/master.yml -p deploy_id=GEOCLOUD-DEV-2015042522-TA`

#### Deploy stack with PostgresSQL RDS
You will have to create a vault before deploying the first time:

`knife vault create opengeo_suite postgres '{"username": "anyusername", "password": "anypassword"}'`

You can add azskip or deploy_id if needed

 `mu-deploy /opt/mu/var/geocloud_platform/applications/opengeo_suite/master.yml -p create_db=true`
 
Control the public or nonpublic visibility of the databases.  Default is to make database available only in private subnets for security: 

`mu-deploy  /opt/mu/var/geocloud_platform/applications/opengeo_suite/master.yml -p create_db=true -p azskip=us-east-1a -p appname=ogrds`

whereas 

`mu-deploy  /opt/mu/var/geocloud_platform/applications/opengeo_suite/master.yml -p create_db=true -p azskip=us-east-1a -p appname=ogrdspub -p public_db=true`

will override the private subnet default and deploy the database to publically accessible subnets
