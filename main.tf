provider "aws" {
  alias   = "london"
  region  = var.REGION["london"]
}

provider "aws" {
  alias   = "paris"
  region  = var.REGION["paris"]
}

# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "5.54.1"
#     }
#   }
#   required_version = "~> 1.3"
# }

#CREATE A VPC IN LONDON REGION
resource "aws_vpc" "main" {
  cidr_block = var.CIDR
  provider   = aws.london
  tags = {
    Name = "MainVPC-${terraform.workspace}"
  }
}

#CREATE A INTERNET GATEWAY IN LONDON VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MainIGW-${terraform.workspace}"
  }
  provider = aws.london
  depends_on = [aws_vpc.main]
}

#GET THE AVAILABILITY ZONES IN THE REGION
data "aws_availability_zones" "available" {
  state = "available"
  provider = aws.london
}

#CREATE A PUBLIC SUBNET 1
resource "aws_subnet" "pubsub1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.PUBSUBNET1
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "PublicSubnet-${terraform.workspace}"
  }
  provider = aws.london
  depends_on = [aws_vpc.main]
}

#CREATE A ROUTE TABLE FOR MAIN VPC
resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MainPublicRouteTable-${terraform.workspace}"
  }
  provider = aws.london
  depends_on = [aws_vpc.main]
}

#ASSOCIATE PUBLIC SUBNET WITH ROUTE TABLE
resource "aws_route_table_association" "main_rt_association" {
  subnet_id      = aws_subnet.pubsub1.id
  route_table_id = aws_route_table.main_rt.id
  provider = aws.london
  depends_on = [aws_subnet.pubsub1]
}

#CREATE A DEFAULT ROUTE THROUGH INTERNET GATEWAY FOR ALL OUTBOUND TRAFFIC
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.main_rt.id
  destination_cidr_block = var.INT_CIDR
  gateway_id             = aws_internet_gateway.igw.id
  provider = aws.london
}

##################################PARIS##################################
#CREATE 2ND VPC IN PARIS REGION
resource "aws_vpc" "other" {
  cidr_block = var.CIDR2
  provider   = aws.paris
  tags = {
    Name = "MainVPC-${terraform.workspace}"
  }
}

#GET THE AVAILABILITY ZONES IN PARIS REGION
data "aws_availability_zones" "availableinparis" {
  provider = aws.paris
  state = "available"
}

#CREATE A PRIVATE SUBNET
resource "aws_subnet" "privatesub" {
  vpc_id            = aws_vpc.other.id
  provider = aws.paris
  cidr_block        = var.PVTSUB1
  availability_zone = data.aws_availability_zones.availableinparis.names[0]
  tags = {
    Name = "PrivateSubnet-${terraform.workspace}"
  }
  depends_on = [aws_vpc.other]
}

#CREATE A ROUTE TABLE FOR PRIVATE VPC
resource "aws_route_table" "private_rt_table" {
  vpc_id = aws_vpc.other.id
  provider = aws.paris
  tags = {
    Name = "MainPublicRouteTable-${terraform.workspace}"
  }
  depends_on = [aws_vpc.other]
}

#ASSOCIATE PRIVATE SUBNET TO THE ROUTE TABLE
resource "aws_route_table_association" "PVTSUBTORT" {
  route_table_id = aws_route_table.private_rt_table.id
  subnet_id      = aws_subnet.privatesub.id
  provider = aws.paris
  depends_on = [aws_subnet.privatesub]
}

#VPC PEERING CONNECTIONS
resource "aws_vpc_peering_connection" "vpc_peering" {
  peer_owner_id = "866934333672"
  peer_vpc_id = aws_vpc.other.id
  vpc_id      = aws_vpc.main.id
  auto_accept = false
  peer_region = var.REGION["paris"]
  provider    = aws.london
  depends_on  = [aws_vpc.main, aws_vpc.other]
}

#VPC PEERING CONNECTIONS
resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  auto_accept = true
  provider    = aws.paris
  depends_on  = [aws_vpc.main, aws_vpc.other]
}

#ROUTE TABLE FROM MAIN VPC TO OTHER VPC THROUGH PEERING
resource "aws_route" "maintoother" {
  route_table_id            = aws_route_table.main_rt.id
  provider = aws.london
  destination_cidr_block    = aws_vpc.other.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  depends_on = [aws_route_table.main_rt, aws_vpc_peering_connection.vpc_peering]
}

#ROUTE TABLE FROM OTHER VPC TO MAIN VPC THROUGH PEERING CONENCTION
resource "aws_route" "othertomain" {
  route_table_id            = aws_route_table.private_rt_table.id
  provider = aws.paris
  destination_cidr_block    = aws_vpc.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  depends_on = [aws_route_table.private_rt_table, aws_vpc_peering_connection.vpc_peering]
}

#CREATE SECURITY GROUPS FOR THE VPC ALLOWING SSH/ HTTP/ HTTPS/ 8080/ PING
resource "aws_security_group" "allow_inbound_outbound" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "TFSG-${terraform.workspace}"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.INT_CIDR]
    description = "Allow HTTP traffic"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.INT_CIDR]
    description = "Allow HTTPS traffic"
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.INT_CIDR]
    description = "Allow TOMCAT traffic"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.INT_CIDR]
    description = "Allow SSH traffic"
  }
  ingress {
    from_port   = 8 #echo request (TYPE 8) can accept only echo requests
    to_port     = 0 #echo reply (TYPE 0) can give back only echo replies
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow PING"
  }
  egress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.INT_CIDR]
    protocol    = "tcp"
    description = "Allow all outbound traffic"
  }
  depends_on = [aws_vpc.main]
}
##