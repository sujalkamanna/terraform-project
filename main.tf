# VPC
resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "VPC1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "IGW for VPC1"
  }
}

# Subnets
# Public Subnet
resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.0/25"
    map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet A"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet_b" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.0.0.128/25"

  tags = {
    Name = "Private Subnet B"
  }
}


# Elastic IP for NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "nat_vpc1" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id

  tags = {
    Name = "NAT Gateway for VPC1"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Route Tables
# Public Route Table
resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Private Route Table
resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_vpc1.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_route_table_association" "private_subnet_assoc" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.route_table_private.id
}

# Security Groups
# Public EC2 SG
resource "aws_security_group" "sg_public" {
  name        = "public-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public SG"
  }
}

# Private EC2 SG
resource "aws_security_group" "sg_private" {
  name        = "private-sg"
  description = "Allow SSH from Public Subnet"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description = "SSH from Public Subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.public_subnet_a.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Private SG"
  }
}


# EC2 Instances
# Public EC2
resource "aws_instance" "public_ec2" {
  ami           = "ami-02b8269d5e85954ef" #ubuntu 
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet_a.id
  vpc_security_group_ids = [aws_security_group.sg_public.id]
  associate_public_ip_address = true

  tags = {
    Name = "Public EC2"
  }
}

# Private EC2
resource "aws_instance" "private_ec2" {
  ami           = "ami-02b8269d5e85954ef" 
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_subnet_b.id
  vpc_security_group_ids = [aws_security_group.sg_private.id]
  associate_public_ip_address = false

  tags = {
    Name = "Private EC2"
  }
}