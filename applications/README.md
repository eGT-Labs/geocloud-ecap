This repository contains a range of Boundless open source geospatial services and the GeoShape/Rogue deployment of Geonode.  All have  been modified for use in the eCAP automated provisioning system.  

Requirements
==============
- eCAP server at least tag r0.1.2 or newer

Common Capabilities and BOK (Baskets of Kittens/Deployment Descriptors)
=======================================================================
- centos-ami.json defines AMIs for CentOS launches
- ubuntu-ami.json defines AMIs for Ubuntu launches
- win2k12-ami.json defines AMIs for Windows 2012 Server launches
- default_iam_node_policies.js defines shared AWS policies for launched nodes



Operational Deployments
==================
This repository is under active development and contains deployments that may not be currently operational.  See README.md in individual deployments for details of operational deployments.

geoshape_geonode Directory
--------------------------
geoshape_geonode contains the operational descriptors for GeoShape deployment.  See README.md in that directory for status, limitations and usage

VPC Directory
-------------
The vpc directory defines BOKs to create VPC's for deployment models that target and reuse existing VPCs

Other Directories
------------------
Stubs, not operational at this time