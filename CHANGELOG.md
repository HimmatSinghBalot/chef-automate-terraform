# chef-automate-terraform CHANGELOG
This file is used to list changes made in each version of the chef-automate-terraform plan.

## 3.0.0 (2017-06-07)

- Now using the aws_ami Terraform data source to select the latest available Ubuntu 16.04 AMI
- Chef Automate, Server, and ChefDK package names/URLs are now variables
- Set defaults for packages to Automate 0.8.5, Server 12.25.7, and ChefDK 1.4.3
- Removed apt-get upgrade since we're pulling recently patched AMIs

## 2.1.0 (2017-04-06)

- Updated to use latest official AWS Ubuntu 16.04 LTS AMIs
- Updated Chef Server to 12.14.0
- Updated Chef Automate Server to 0.7.151
- BUGFIX: Added 'X-Contact' AWS EC2 Tag to Automate Server and Job Runners
- Renamed variables file to follow terraform.tfvars convention

## 2.0.0 (2017-02-02)

- Updated to use Official AWS Ubuntu 16.04 AMIs
- Added us-east-2 to AMI list
- Updated Chef Server to 12.12.0
- Updated Chef Automate Server to 0.6.136
- Updated ChefDK to 1.2.22
- Removed Push Jobs Server
- Added SSH Job Runners
- Added 'X-Contact' AWS EC2 Tag

## 1.0.0 (2016-08-05)

- Initial Release
