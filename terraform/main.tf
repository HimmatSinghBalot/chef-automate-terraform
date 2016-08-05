# TODO:
# - Variablize source URLs for Chef Packages
# - DNS is entirely via AWS hostnames. This may be ok, or not.
# - Evaluate sensitive key placement. This could use some refactoring.
# - Place output from Delivery setup somewhere useful
# - Add a .gitignore to exclude state files
# - Create README

variable "prefix" {
    type = "string"
    description = "Identifying string to prefix the name of generated AWS resources"
}

variable "aws_region" {
    type = "string"
    description = "AWS region to deploy in. Ex: us-west-1"
}

variable "vpc_id" {
    type = "string"
    description = "VPC ID to deploy cluster within"
}

variable "subnet" {
    type = "string"
    description = "Subnet to deploy cluster within"
}

variable "cidrs_allowed" {
    type = "list"
    description = "List of CIDR blocks allowed to access the automate cluster"
}

variable "ami" {
    type = "map"
    description = "AMI ID to use for cluster instances"
    default = {
        us-east-1 = "ami-2d39803a"
        us-west-1 = "ami-48db9d28"
        us-west-2 = "ami-d732f0b7"
    }
}

variable "key_name" {
    type = "string"
    description = "AWS SSH Key Name"
}

variable "key_path" {
    type = "string"
    description = "Path to SSH private key"
}

variable "builder_count" {
    type = "string"
    description = "Number of Automate Builders to provision"
}

variable "license_file" {
    type = "string"
    description = "Path to Chef Automate license file"
}

provider "aws" {
    region = "${var.aws_region}"
}

resource "aws_security_group" "chef-automate" {
    name = "${var.prefix}-chef-automate"

    vpc_id = "${var.vpc_id}"

    tags {
        Name = "${var.prefix}-chef-automate"
    }

    # Allow instances within the security group 
    # to communitcate with each other
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        self = true
    }

    # Push Jobs
    ingress {
        from_port = 10000
        to_port = 10003
        protocol = "tcp"
        cidr_blocks = "${var.cidrs_allowed}"
    }

    # Chef Delivery Git Server
    ingress {
        from_port = 8989
        to_port = 8989
        protocol = "tcp"
        cidr_blocks = "${var.cidrs_allowed}"
    }

    # Chef Server / Automate Server HTTPS
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = "${var.cidrs_allowed}"
    }

    # Chef Server / Automate Server HTTP
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = "${var.cidrs_allowed}"
    }

    # SSH Management Access
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = "${var.cidrs_allowed}"
    }    

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_instance" "chef-server" {
    ami = "${lookup(var.ami, var.aws_region)}"
    instance_type = "c4.xlarge"
    subnet_id = "${var.subnet}"
    vpc_security_group_ids = ["${aws_security_group.chef-automate.id}"]
    key_name = "${var.key_name}"

    root_block_device {
        volume_type = "gp2"
        volume_size = "80"
        delete_on_termination = true
    }

    tags {
        Name = "${var.prefix}-chef-server"
    }

    connection {
        type = "ssh"
        user = "ubuntu"
        agent = false
        private_key = "${file("${var.key_path}")}"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt-get update",
            "sudo apt-get -y upgrade",
            "sudo apt-get -y install wget",
            "sudo wget -P /tmp https://packages.chef.io/stable/ubuntu/14.04/chef-server-core_12.8.0-1_amd64.deb",
            "sudo dpkg -i /tmp/chef-server-core_12.8.0-1_amd64.deb",
            "sudo hostname $(hostname -f)",
            "sudo su -c 'echo $(hostname) > /etc/hostname'",
            "sudo chef-server-ctl reconfigure",
            "sudo wget -P /tmp https://packages.chef.io/stable/ubuntu/14.04/opscode-push-jobs-server_1.1.6-1_amd64.deb",
            "sudo dpkg -i /tmp/opscode-push-jobs-server_1.1.6-1_amd64.deb",
            "sudo chef-server-ctl reconfigure",
            "sudo opscode-push-jobs-server-ctl reconfigure",
            "sudo chef-server-ctl user-create delivery Delivery User delivery-user@chef.io ChefDelivery2016 --filename /home/ubuntu/delivery-user.pem",
            "sudo chef-server-ctl org-create delivery 'Chef Delivery'  --filename /home/ubuntu/delivery-validator.pem -a delivery"
        ]
    }

    provisioner "local-exec" {
        command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.key_path} ubuntu@${self.private_ip}:/home/ubuntu/delivery-user.pem ."
    }

    provisioner "local-exec" {
        command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.key_path} ubuntu@${self.private_ip}:/home/ubuntu/delivery-validator.pem ."
    }
}

resource "aws_instance" "automate-server" {
    depends_on = ["aws_instance.chef-server"]
    ami = "${lookup(var.ami, var.aws_region)}"
    instance_type = "m4.xlarge"
    subnet_id = "${var.subnet}"
    vpc_security_group_ids = ["${aws_security_group.chef-automate.id}"]
    key_name = "${var.key_name}"

    root_block_device {
        volume_type = "gp2"
        volume_size = "80"
        delete_on_termination = true
    }

    tags {
        Name = "${var.prefix}-automate-server"
    }

    connection {
        type = "ssh"
        user = "ubuntu"
        agent = false
        private_key = "${file("${var.key_path}")}"
    }

    provisioner "file" {
        source = "delivery-user.pem"
        destination = "/home/ubuntu/delivery-user.pem"
    }

    provisioner "file" {
        source = "${var.license_file}"
        destination = "/home/ubuntu/delivery.license"
    }

    provisioner "file" {
        source = "${var.key_path}"
        destination = "/home/ubuntu/ssh_key.pem"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt-get update",
            "sudo apt-get -y upgrade",
            "sudo apt-get -y install wget",
            "sudo wget -P /tmp https://packages.chef.io/stable/ubuntu/14.04/delivery_0.5.1-1_amd64.deb",
            "sudo wget -P /home/ubuntu https://packages.chef.io/stable/ubuntu/12.04/chefdk_0.16.28-1_amd64.deb",
            "sudo dpkg -i /tmp/delivery_0.5.1-1_amd64.deb",
            "sudo hostname $(hostname -f)",
            "sudo su -c 'echo $(hostname) > /etc/hostname'",
            "sudo delivery-ctl setup --license /home/ubuntu/delivery.license --key /home/ubuntu/delivery-user.pem --server-url https://${aws_instance.chef-server.private_dns}/organizations/delivery --fqdn ${self.private_dns} --enterprise delivery --configure --no-build-node"
        ]
    }
}

resource "aws_instance" "automate-builder" {
    depends_on = ["aws_instance.automate-server"]
    count = "${var.builder_count}"
    ami = "${lookup(var.ami, var.aws_region)}"
    instance_type = "t2.medium"
    subnet_id = "${var.subnet}"
    vpc_security_group_ids = ["${aws_security_group.chef-automate.id}"]
    key_name = "${var.key_name}"

    root_block_device {
        volume_type = "gp2"
        volume_size = "60"
        delete_on_termination = true
    }

    tags {
        Name = "${var.prefix}-${format("automate-builder-%02d", count.index + 1)}"
    }

    connection {
        type = "ssh"
        user = "ubuntu"
        agent = false
        private_key = "${file("${var.key_path}")}"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt-get update",
            "sudo apt-get -y upgrade",
            "sudo apt-get -y install wget",
            "sudo hostname $(hostname -f)",
            "sudo su -c 'echo $(hostname) > /etc/hostname'"
        ]
    }

    provisioner "local-exec" {
        command = "ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.key_path} ubuntu@${aws_instance.automate-server.private_ip} 'sudo delivery-ctl install-build-node --installer /home/ubuntu/chefdk_0.16.28-1_amd64.deb --fqdn ${self.private_dns} --username ubuntu --ssh-identity-file /home/ubuntu/ssh_key.pem --overwrite-registration --password nadanada'"
    }
}