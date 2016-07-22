variable "vpc_region" {}
variable "tfstate_bucket" {}
variable "ami_id" {}

provider "aws" {
    region = "${var.vpc_region}"
}

resource "terraform_remote_state" "vpc" {
	backend = "s3"
	config {
		region = "${var.vpc_region}"
		bucket = "${var.tfstate_bucket}"
		key = "aws_training/vpc/terraform.tfstate"
	}
}

resource "aws_security_group" "bastion" {
    name="bastion_hosts"
    description="Allows ssh to bastion hosts"
    vpc_id="${terraform_remote_state.vpc.output.aws_vpc_vpc1_id}"
    egress {
        from_port=0
        to_port=0
        protocol="-1"
        cidr_blocks=["0.0.0.0/0"]
    }
    ingress {
        from_port=22
        to_port=22
        protocol="tcp"
        cidr_blocks=["0.0.0.0/0"]
    }
}


resource "aws_instance" "bastion_host" {
    ami = "${var.ami_id}"
    instance_type = "t2.micro"
    subnet_id="${element(split(",",terraform_remote_state.vpc.output.public_subnets), 1)}"
    vpc_security_group_ids=["${aws_security_group.bastion.id}"]
    tags = {
        Name="Randy-Bastion"
    }
    associate_public_ip_address=true
}

output "aws_instance_bastion_host_public_ip" {
	value = "${aws_instance.bastion_host.public_ip}"
}
output "aws_instance_bastion_host_public_dns" {
    value = "${aws_instance.bastion_host.public_dns}"
}