variable "prefix" {
    type = "string"
    description = "Identifying string to prefix the name of generated AWS resources"
    default = "jbyrne"
}

variable "aws_region" {
    type = "string"
    description = "AWS region to deploy in. Ex: us-west-1"
    default = "us-west-1"
}

variable "vpc_id" {
    type = "string"
    description = "VPC ID to deploy cluster within"
    default = "vpc-01546164"
}

variable "subnet" {
    type = "string"
    description = "Subnet to deploy cluster within"
    default = "subnet-b4798dd0"
}

variable "ami" {
    type = "string"
    description = "AMI ID to use for cluster instances"
    default = "ami-48db9d28"
}

variable "key_name" {
    type = "string"
    description = "AWS SSH Key Name"
    default = "jbyrne-chef"
}

variable "key_path" {
    type = "string"
    description = "Path to SSH private key"
    default = "../ssh_keys/jbyrne.pem"
}

variable "builder_count" {
    type = "string"
    description = "Number of Automate Builders to provision"
    default = 3
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
        cidr_blocks = ["10.99.0.0/16"]
    }

    # Chef Delivery Git Server
    ingress {
        from_port = 8989
        to_port = 8989
        protocol = "tcp"
        cidr_blocks = ["10.99.0.0/16"]
    }

    # Chef Server / Automate Server HTTPS
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["10.99.0.0/16"]
    }

    # Chef Server / Automate Server HTTP
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["10.99.0.0/16"]
    }

    # SSH Management Access
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["10.99.0.0/16"]
    }    

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_instance" "chef-server" {
    ami = "${var.ami}"
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

    provisioner "remote-exec" {
        inline = [
            "sudo apt-get update",
            "sudo apt-get -y upgrade",
            "sudo apt-get -y install wget",
            "sudo wget -P /tmp https://packages.chef.io/stable/ubuntu/14.04/chef-server-core_12.8.0-1_amd64.deb",
            "sudo dpkg -i /tmp/chef-server-core_12.8.0-1_amd64.deb"
        ]
        connection {
            type = "ssh"
            user = "ubuntu"
            agent = false
            private_key = "${file("${var.key_path}")}"
        }
    }
}

resource "aws_instance" "automate-server" {
    ami = "${var.ami}"
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

    provisioner "remote-exec" {
        inline = [
            "sudo apt-get update",
            "sudo apt-get -y upgrade",
            "sudo apt-get -y install wget",
            "sudo wget -P /tmp https://packages.chef.io/stable/ubuntu/14.04/delivery_0.5.1-1_amd64.deb",
            "sudo dpkg -i /tmp/delivery_0.5.1-1_amd64.deb"
        ]
        connection {
            type = "ssh"
            user = "ubuntu"
            agent = false
            private_key = "${file("${var.key_path}")}"
        }
    }
}

resource "aws_instance" "automate-builder" {
    count = "${var.builder_count}"
    ami = "${var.ami}"
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

    provisioner "remote-exec" {
        inline = [
            "sudo apt-get update",
            "sudo apt-get -y upgrade",
            "sudo apt-get -y install wget",
            "sudo wget -P /tmp https://packages.chef.io/stable/ubuntu/12.04/chefdk_0.16.28-1_amd64.deb",
            "sudo dpkg -i /tmp/chefdk_0.16.28-1_amd64.deb"
        ]
        connection {
            type = "ssh"
            user = "ubuntu"
            agent = false
            private_key = "${file("${var.key_path}")}"
        }
    }
}