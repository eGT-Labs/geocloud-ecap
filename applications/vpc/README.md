VPC Baskets of Kittens
======================
These BOKs are used to create standalone VPC containers that can be used to contain other deployments.  Deploying into existing VPCs is a supported deployment model, as is deploying while creating a VPC at the same time.

- dev_only.json launches a development VPC and bastion that can be targeted for multiple deploys.  It includes the other "dev_*" BOKs
- The other VPC BOKs are not yet operational

Usage
-----
Create a dev style VPC for future deployments:
`cap-deploy -n /opt/ecap/geocloud-ecap/applications/vpc/dev_only.json -p azskip=us-east-1a`