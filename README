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
	* Edit the main.tfvars file and input your desired settings
	* Run 'terraform plan' to review what Terraform will do
	* Run 'terraform apply' to initiate the provisioning process

## Post run:
* The process will write out the Delivery user .pem key and the Chef Org validator .pem key to the directory you ran Terraform from.
* In the output from the Terraform run, find the end of the section where it creates the Automate server. You will see the login information the server.

## Development TODOs:

* Variablize source URLs for Chef Packages
* DNS is entirely via AWS hostnames. This may be ok, or not.
* Evaluate sensitive key placement. This could use some refactoring.
* Place output from Delivery setup somewhere useful