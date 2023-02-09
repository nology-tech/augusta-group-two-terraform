provider "aws" {
  region="us-east-2"
}

# Create our VPC
resource "aws_vpc" "group-two-application-deployment" {
  cidr_block = "10.16.0.0/16"

  tags = {
    Name = "group-two-application-deployment-vpc"
  }
}

resource "aws_internet_gateway" "group-two-ig" {
  vpc_id = "${aws_vpc.group-two-application-deployment.id}"

  tags = {
    Name = "group-two-ig"
  }
}

resource "aws_route_table" "group-two-rt" {
  vpc_id = "${aws_vpc.group-two-application-deployment.id}"
  
  route {
    cidr_block = "0.0.0.0/0" # Anywhere - access the internet from inside the network
    gateway_id = "${aws_internet_gateway.group-two-ig.id}"
  }
}

data "aws_ami" "db-ami" {

most_recent = true 

filter {
    name   = "name"
    values = ["augusta-baked-image-database-group-two-database*"]
  }

filter {
  name = "state"
  values = ["available"]
}

filter {
    name = "root-device-type"
    values = ["ebs"]
}

}


module "db-tier" {
  name           = "group-two-database"
  source         = "./modules/db-tier"
  vpc_id         = "${aws_vpc.group-two-application-deployment.id}"
  route_table_id = "${aws_vpc.group-two-application-deployment.main_route_table_id}"
  cidr_block              = "10.16.1.0/24" 
  user_data               = templatefile("./scripts/database_user_data.sh", {})
  ami_id                  = "${data.aws_ami.db-ami.id}"  
  map_public_ip_on_launch = false

  ingress = [
    {
      from_port = 27017
      to_port = 27017
      protocol = "tcp"
      cidr_blocks = "${module.application-tier.subnet_cidr_block}"
    }
  ]
}


data "aws_ami" "app-ami" {
  most_recent = true


filter {
    name   = "name"
    values = ["augusta-baked-image-application-group-two-application*"]
  }

  filter {
    name = "state"
    values = ["available"]
  }

    filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

module "application-tier" {
  name                    = "group-two-app"
  source                  = "./modules/application-tier"
  vpc_id                  = "${aws_vpc.group-two-application-deployment.id}"
  route_table_id          = "${aws_route_table.group-two-rt.id}"
  cidr_block              = "10.16.0.0/24"
  user_data               = templatefile("./scripts/app_user_data.sh", { mongodb_ip=module.db-tier.private_ip })
  ami_id                  = "${data.aws_ami.app-ami.id}" 
  map_public_ip_on_launch = true

  ingress = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0" # Currently open to all, will create an array for each memeber (add 32 to the end)
    }
  ]
}