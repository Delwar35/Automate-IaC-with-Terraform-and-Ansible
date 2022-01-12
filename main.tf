# AWS plugins/dependencies will be downloaded
provider "aws" {
    region = "eu-west-1"
    # This will allow terraform to create services on eu-west-1
  
}

# Creating VPC

resource "aws_vpc" "vpc_terraform" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "eng99_delwar_vpc_terraform_jenkins"
    }
}

# Creating internet gateway

resource "aws_internet_gateway" "IG" {
    vpc_id = aws_vpc.vpc_terraform.id
    tags = {
        Name = "eng99_delwar_terraform_IG_jenkins"
    }
}

# Creating public subnet 

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc_terraform.id
  availability_zone = "eu-west-1a"
  cidr_block = "10.0.25.0/24"
  tags = {
        Name = "eng99_delwar_public_subnet_terraform_jenkins"
    }
}

# Creating private subnet

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc_terraform.id 
  availability_zone = "eu-west-1a"
  cidr_block = "10.0.26.0/24"
  tags = {
        Name = "eng99_delwar_private_subnet_terraform_jenkins"
    }
}

# Create a route table for public subnet
resource "aws_route_table" "public_rt_terraform" {
    vpc_id = aws_vpc.vpc_terraform.id
         route {
            cidr_block = "0.0.0.0/0"
            gateway_id = aws_internet_gateway.IG.id
        }
    tags = {
      "Name" = "eng99_delwar_public_rt_terraform_jenkins"
    }
}

# Route Table association to public subnet
resource "aws_route_table_association" "public_rt_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_rt_terraform.id
    }

# Create a route table for private subnet
resource "aws_route_table" "private_rt_terraform" {
    vpc_id = aws_vpc.vpc_terraform.id
         route {
            cidr_block = "0.0.0.0/0"
            gateway_id = aws_internet_gateway.IG.id
        }
    tags = {
      "Name" = "eng99_delwar_private_rt_terraform"
    }
}

# Route Table association to private subnet
resource "aws_route_table_association" "private_rt_association" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_rt_terraform.id
    }

# creating security groups for app
resource "aws_security_group" "security_group" {
    # engress rules is the outbound rules
    # allow all outbound
    vpc_id = aws_vpc.vpc_terraform.id
    egress {
        from_port = 0
        to_port = 0
        # can use "ALL" instead of "-1" 
        # "-1" and "ALL" can only be used if from_port and to_port is 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        
    }
    # ingress rules is the inbound rules

    # allow all to ssh to the machine with port 22
    ingress {
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow the app to run
    ingress {
        from_port = "3000"
        to_port = "3000"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

     tags = {
        Name = "eng99_delwar_terraform_jenkins_app_sg"
    }

} 

# creating security groups for db
resource "aws_security_group" "security_group_db" {
    # engress rules is the outbound rules
    # allow all outbound
    vpc_id = aws_vpc.vpc_terraform.id 

    egress {
        from_port = 0
        to_port = 0
        # can use "ALL" instead of "-1" 
        # "-1" and "ALL" can only be used if from_port and to_port is 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        
    }
    # ingress rules is the inbound rules

    # allow all to ssh to the machine with port 22
    ingress {
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow the db to run
    ingress {
        from_port = "27017"
        to_port = "27017"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        
    }

    tags = {
        Name = "eng99_delwar_terraform_jenkins_db_sg"
    }

  
} 


# creating app ec2 instance with a vpc and public subnet
resource "aws_instance" "app_instance" {
  # add the ami  
  ami =  "ami-07d8796a2b0f8d29c"
  # choose t2
  instance_type = "t2.micro"
  #enable public IP
  associate_public_ip_address = true
  # associating subnet
  subnet_id = aws_subnet.public_subnet.id
  # associating security group
  vpc_security_group_ids = [aws_security_group.security_group.id]
  # add tags
  tags = {
      Name = "eng99_delwar_terraform_jenkins_app"
  }
  
  key_name = "eng99" # ensure that we have key in .ssh file 
}

# creating a db ec2 instance
resource "aws_instance" "db_instance" {
  # add the ami  
  ami =  "ami-07d8796a2b0f8d29c"
  # choose t2
  instance_type = "t2.micro"
  #enable public IP
  associate_public_ip_address = true
  # associating subnet
  subnet_id = aws_subnet.private_subnet.id
  # associating security group
  vpc_security_group_ids = [aws_security_group.security_group_db.id]
  # add tags
  tags = {
      Name = "eng99_delwar_terraform_jenkins_db"
  }
  
  key_name = "eng99" # ensure that we have key in .ssh file 
}
