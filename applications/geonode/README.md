# GeoNode Deployment

This is a classic GeoNode deploy installed from the GeoNode PPA, orchestrated as a 1:1 autoscale group behind a load balancer, with credentials in the BOK.

TODO: extract credentials to vault

# Deploy patterns
`mu-deploy /opt/mu/var/geocloud_platform/applications/geonode/master.yaml -p appname=fullgnode`

or to deploy in an existing VPC:

`mu-deploy /opt/mu/var/geocloud_platform/applications/geonode/master.yaml -p azskip=us-east-1a -p deploy_id=FULLSHAPE-DEV-2015042214-NT -p vpc_name=fullnode-vpc`


