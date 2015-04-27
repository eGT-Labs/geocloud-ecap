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
You can add azskip or deploy_id if needed
 `mu-deploy /opt/mu/var/geocloud_platform/applications/opengeo_suite/master.yml -p create_db=true`
You will also have to create a vault before deploying:
`knife vault create opengeo_suite postgres '{"username": "anyusername", "password": "anypassword"}'`
