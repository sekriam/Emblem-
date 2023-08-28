# Creates the VPC 

resource "aws_vpc" "emblem_vpc" {

  # IP Range for the VPC
  cidr_block = "192.168.0.0/16"

  # Enabling automatic hostname assigning
  enable_dns_hostnames = true
  tags = {
    Name = "emblem_vpc"
  }
}

resource "aws_subnet" "subnet1" {
  depends_on = [
    aws_vpc.emblem_vpc
  ]

  # VPC in which subnet has to be created
  vpc_id = aws_vpc.emblem_vpc.id

  # IP Range of this subnet
  cidr_block = "192.168.0.0/24"

  # Data Center of this subnet.
  availability_zone = "us-east-1a"

  # Enabling automatic public IP assignment on instance launch
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}

# Creates Public subnet
resource "aws_subnet" "subnet2" {
  depends_on = [
    aws_vpc.emblem_vpc,
    aws_subnet.subnet1
  ]

  # VPC in which subnet has to be created
  vpc_id = aws_vpc.emblem_vpc.id

  # IP Range of this subnet
  cidr_block = "192.168.1.0/24"

  # Data Center of this subnet.
  availability_zone = "ap-east-1b"

  tags = {
    Name = "Private Subnet"
  }
}


# Creates an Internet Gateway for the VPC
resource "aws_internet_gateway" "Internet_Gateway" {
  depends_on = [
    aws_vpc.emblem_vpc,
    aws_subnet.subnet1,
    aws_subnet.subnet2
  ]

  # VPC in which it has to be created
  vpc_id = aws_vpc.emblem_vpc.id

  tags = {
    Name = "IG-Public-&-Private-VPC"
  }
}

# Creating an Route Table for the public subnet!
resource "aws_route_table" "Public-Subnet-RT" {
  depends_on = [
    aws_vpc.emblem_vpc,
    aws_internet_gateway.Internet_Gateway
  ]

  # VPC ID
  vpc_id = aws_vpc.emblem_vpc.id

  # NAT Rule
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Internet_Gateway.id
  }

  tags = {
    Name = "Route Table for Internet Gateway"
  }
}

# Creating a resource for the Route Table Association!
resource "aws_route_table_association" "RT-IG-Association" {

  depends_on = [
    aws_vpc.emblem_vpc,
    aws_subnet.subnet1,
    aws_subnet.subnet2,
    aws_route_table.Public-Subnet-RT
  ]

  # Public Subnet ID
  subnet_id = aws_subnet.subnet1.id

  #  Route Table ID
  route_table_id = aws_route_table.Public-Subnet-RT.id
}

# Creates an Elastic IP for the NAT Gateway!
resource "aws_eip" "Nat-Gateway-EIP" {
  depends_on = [
    aws_route_table_association.RT-IG-Association
  ]
  vpc = true
}

# Creates a NAT Gateway!
resource "aws_nat_gateway" "NAT_GATEWAY" {
  depends_on = [
    aws_eip.Nat-Gateway-EIP
  ]

  # Allocating the Elastic IP to the NAT Gateway!
  allocation_id = aws_eip.Nat-Gateway-EIP.id

  # Associating it in the Public Subnet!
  subnet_id = aws_subnet.subnet1.id
  tags = {
    Name = "Nat-Gateway_Emblem"
  }
}


# Creates a Security Group for instance
resource "aws_security_group" "WS-SG" {

  depends_on = [
    aws_vpc.emblem_vpc,
    aws_subnet.subnet1,
    aws_subnet.subnet2
  ]

  description = "HTTP, PING, SSH"

  # Name of the security Group
  name = "emblem-sg1"
  
  # VPC ID in which Security group has to be created!
  vpc_id = aws_vpc.emblem_vpc.id

  # Created an inbound rule for webserver access
  ingress {
    description = "HTTP for instance"
    from_port   = 80
    to_port     = 80

    # Here adding tcp instead of http, because http in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for ping
  ingress {
    description = "Ping"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22

    # Here adding tcp instead of ssh, because ssh in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outward Network Traffic for the webserver
  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Creating security group for MySQL, this will allow access only from the instances having the security group created above.
resource "aws_security_group" "MySQL-SG" {

  depends_on = [
    aws_vpc.emblem_vpc,
    aws_subnet.subnet1,
    aws_subnet.subnet2,
    aws_security_group.WS-SG
  ]

  description = "MySQL Access only from the Webserver Instances!"
  name = "mysql-sg"
  vpc_id = aws_vpc.emblem_vpc.id

  # Created an inbound rule for MySQL
  ingress {
    description = "MySQL Access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.WS-SG.id]
  }

  egress {
    description = "output from MySQL"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

