terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
provider "aws" {
  region = var.aws_region
}

#VPC_Prod_Hub
resource "aws_vpc" "prod_hub" {
  cidr_block = var.prod_hub_vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.prod_environment}-vpc"
    "Environment" = var.prod_environment
  }
}
 #VPC_Spoke_01
 resource "aws_vpc" "spoke-01" {
  cidr_block = var.spoke_01_vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "${var.spoke_01_environmet}-vpc"
    "Environment" = var.spoke_01_environmet
 }
 }
 #VPC_Spoke_02
resource "aws_vpc" "spoke-02" {
      cidr_block = var.spoke_02_vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "${var.spoke_02_environmet}-vpc"
    "Environment" = var.spoke_02_environmet
  
}
}

#Prod-hub Public Subnet
resource "aws_subnet" "prod-hub-pub" {
vpc_id = aws_vpc.prod_hub.id
count = length(var.prod_public_subnets_cidr)
cidr_block = element (var.prod_public_subnets_cidr, count.index)
availability_zone = var.availability_zone[0]
map_public_ip_on_launch = true
}

#Prod-hub Private Subnet
resource "aws_subnet" "prod-hub-private" {
vpc_id = aws_vpc.prod_hub.id
count = length(var.prod_hub_private_subnets_cidr)
cidr_block = element (var.prod_hub_private_subnets_cidr, count.index)
availability_zone = var.availability_zone[0]
map_public_ip_on_launch = false
}
#Spoke-01 Private Subnet
resource "aws_subnet" "spoke-01-private" {
vpc_id = aws_vpc.spoke-01.id
count = length(var.spoke_01_private_subnets_cidr)
cidr_block = element (var.spoke_01_private_subnets_cidr, count.index)
availability_zone = var.availability_zone[0]
map_public_ip_on_launch = false
}
#Spoke-02 Private Subnet
resource "aws_subnet" "spoke-02-private" {
vpc_id = aws_vpc.spoke-02.id
count = length(var.spoke_02_private_subnets_cidr)
cidr_block = element (var.spoke_02_private_subnets_cidr, count.index)
availability_zone = var.availability_zone[0]
map_public_ip_on_launch = false
}
#IGW Prod-hub
resource "aws_internet_gateway" "IGW_ProdHub" {
  vpc_id =aws_vpc.prod_hub.id
  tags = {
    "Name" = "$var.prod_environment-igw"
    "Environment" = var.prod_environment
  }
}
# Elastic-IP (eip) for NAT- ProdHub
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.IGW_ProdHub]
}
# NAT Gateway in Prod-hub
resource "aws_nat_gateway" "Prod_HubNAT" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.prod-hub-pub.*.id, 0)
  tags = {
    Name        = "nat-gateway-${var.prod_environment}"
    Environment = "${var.prod_environment}"
  }
}
#Transit Gateway for Prod-Hub Egress VPC 
resource "aws_ec2_transit_gateway" "ProdHub_EgressTGW" {
  description = "TGW to connect to Spoke VPC"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
}
#Create TGW Route Tables
resource "aws_ec2_transit_gateway_route_table" "RT-Egrees" {
 transit_gateway_id = aws_ec2_transit_gateway.ProdHub_EgressTGW.id

}
resource "aws_ec2_transit_gateway_route_table" "RT-Private" {
 transit_gateway_id = aws_ec2_transit_gateway.ProdHub_EgressTGW.id
  
}
#Create TGW attachment for Prod-Hub VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "prod-hub" {
  transit_gateway_id = aws_ec2_transit_gateway.ProdHub_EgressTGW.id
  vpc_id = aws_vpc.prod_hub.id
  subnet_ids = [aws_subnet.prod-hub-private[0].id]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
 
  
}
#Create TGW attachment for Spoke-01 VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke-01" {
  transit_gateway_id = aws_ec2_transit_gateway.ProdHub_EgressTGW.id
  vpc_id = aws_vpc.spoke-01.id
  subnet_ids = [aws_subnet.spoke-01-private[0].id]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}
#Create TGW attachment for Spoke-02 VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke-02" {
  transit_gateway_id = aws_ec2_transit_gateway.ProdHub_EgressTGW.id
  vpc_id = aws_vpc.spoke-02.id
  subnet_ids = [aws_subnet.spoke-02-private[0].id]
 transit_gateway_default_route_table_association = false
 transit_gateway_default_route_table_propagation = false
}


# Routing tables to route traffic for Public Subnet in Prod-Hub
resource "aws_route_table" "prod-hub-public" {
  vpc_id = aws_vpc.prod_hub.id

  tags = {
    Name        = "${var.prod_environment}-public-route-table"
    Environment = "${var.prod_environment}"
  }
}
# Routing tables to route traffic for Private Subnet- Prod Hub
resource "aws_route_table" "prod-hub-private" {
  vpc_id = aws_vpc.prod_hub.id
  tags = {
    Name        = "${var.prod_environment}-private-route-table"
    Environment = "${var.prod_environment}"
  }
}

# Routing tables to route traffic for Private Subnet- Spoke-01
resource "aws_route_table" "spoke-01-private" {
  vpc_id = aws_vpc.spoke-01.id
  tags = {
    Name        = "${var.spoke_01_environmet}-private-route-table"
    Environment = "${var.spoke_01_environmet}"
  }
}

# Routing tables to route traffic for Private Subnet- Spoke-02
resource "aws_route_table" "spoke-02-private" {
  vpc_id = aws_vpc.spoke-02.id
  tags = {
    Name        = "${var.spoke_02_environmet}-private-route-table"
    Environment = "${var.spoke_02_environmet}"
  }
}

# Route for Internet Gateway in Prod-Hub
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.prod-hub-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.IGW_ProdHub.id
}

# Route for NAT Gateway - Prodhub
resource "aws_route" "private_prod_nat_gateway" {
  route_table_id         = aws_route_table.prod-hub-private.id
  destination_cidr_block = "0.0.0.0/0"
 nat_gateway_id = aws_nat_gateway.Prod_HubNAT.id

}
resource "aws_route" "private_prod_spoke01_gateway" {
  route_table_id         = aws_route_table.prod-hub-private.id
  destination_cidr_block = "10.14.0.0/24"
 transit_gateway_id = aws_ec2_transit_gateway.ProdHub_EgressTGW.id

}
resource "aws_route" "private_prod_spoke02_gateway" {
  route_table_id         = aws_route_table.prod-hub-private.id
  destination_cidr_block = "10.15.0.0/24"
 transit_gateway_id = aws_ec2_transit_gateway.ProdHub_EgressTGW.id

}
# Route for NAT Gateway - Spoke-01
resource "aws_route" "private_spoke01_nat_gateway" {
  route_table_id         = aws_route_table.spoke-01-private.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id = aws_ec2_transit_gateway.ProdHub_EgressTGW.id
  
}
# Route for NAT Gateway - Spoke-02
resource "aws_route" "private_spoke02_nat_gateway" {
  route_table_id         = aws_route_table.spoke-02-private.id
  destination_cidr_block = "0.0.0.0/0"
 transit_gateway_id = aws_ec2_transit_gateway.ProdHub_EgressTGW.id
  
}
#Route for Egress TGW
resource "aws_ec2_transit_gateway_route" "RT_Egress01" {
  destination_cidr_block = "10.14.0.0/24"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.RT-Egrees.id
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.spoke-01.id
}
#Route for Egress TGW
resource "aws_ec2_transit_gateway_route" "RT_Egress02" {
  destination_cidr_block = "10.15.0.0/24"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.RT-Egrees.id
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.spoke-02.id
}
#Route for RT-Private TGW
resource "aws_ec2_transit_gateway_route" "RT_Private_Blackhole" {
  destination_cidr_block = "10.15.0.0/24"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.RT-Private.id
  blackhole = true
}
resource "aws_ec2_transit_gateway_route" "RT_PrivateSPOKE_blackhole" {
  destination_cidr_block = "10.14.0.0/24"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.RT-Private.id
  blackhole = true
}

resource "aws_ec2_transit_gateway_route" "RT_Private_Allow" {
  destination_cidr_block = "10.13.0.0/24"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.RT-Private.id
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.prod-hub.id
 
}


#Create ec2 instances in Prod,Spoke-01/02 to test the egress architecture
resource "aws_instance" "prod-t2" {
  ami = "ami-04e914639d0cca79a"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.prod-hub-private[0].id}"
  associate_public_ip_address = "true"
  key_name = "terraform-key"

}
resource "aws_instance" "spoke-01-t2" {
  ami = "ami-04e914639d0cca79a"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.spoke-01-private[0].id}"
associate_public_ip_address = "false"
key_name = "terraform-key"
}
resource "aws_instance" "spoke-02-t2" {
  ami = "ami-04e914639d0cca79a"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.spoke-02-private[0].id}"
  associate_public_ip_address = "false"
  key_name = "terraform-key"
}

