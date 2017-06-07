# chef-automate-terraform
A Terraform plan to build a fully functional Chef Automate cluster in AWS

## Prequisites
* An AWS account
* AWS API keys or IAM role with access to create/modify/delete EC2 and VPC resources
* An SSH keypair setup in AWS and a copy of the private key on the machine running Terraform
* A VPC with at least one subnet that allows instances to route to the internet
* Network access to SSH from the machine running Terraform to the EC2 instances it will provision. Note: This Terraform plan assumes that the instances created will not be publiclly accessable.
* A Chef Delivery or Chef Automate license file

## Usage Instructions:
* Install Terraform from http://terraform.io
* Configure your terminal with AWS credentials
	* https://www.terraform.io/docs/providers/aws/index.html
* From your terminal, enter the terraform directory of this repo
	* Edit the terraform.tfvars file and input your desired settings
	* Run 'terraform plan' to review what Terraform will do
	* Run 'terraform apply' to initiate the provisioning process

## Post run:
* You will find the Delivery user .pem key and the Chef Org validator .pem key in the directory you ran Terraform from.
* The password for the user 'delivery' on the Chef Server is 'ChefDelivery2016'. You can and should change this after installation.
* You will find the login information for the Automate server in the file delivery-admin-credentials located in the directory you ran Terraform from.

## Development TODOs:
* DNS is entirely via AWS hostnames. This may be ok, or not.
* Evaluate sensitive key placement. This could use some refactoring.
* Add Chef Supermarket instance.
