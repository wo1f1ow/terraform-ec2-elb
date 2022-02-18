provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  enable_dns_hostnames  = true
  enable_dns_support    = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = "${var.environment}"
  }
}

# Internet Gateway for public subnet
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = "${var.environment}"
  }
}

# Elastic IP for NAT
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
  tags = {
    Name = "${var.environment}"
  }
}

resource "aws_nat_gateway" "nat"{
  allocation_id  = aws_eip.nat_eip.id
  subnet_id      = aws_subnet.public.id
  depends_on     = [aws_internet_gateway.ig]

  tags = {
    Name        = "nat"
    Environment = "${var.environment}"
  }
}

# Routing table for private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-private-route-table"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-public-route-table"
    Environment = "${var.environment}"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Route table associations
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Route table associations
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnets,0)
  availability_zone       = element(var.availability_zones,0)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment}"
  }
}

# Second public subnet for ALB
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnets,1)
  availability_zone       = element(var.availability_zones,2)
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.environment}"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet
  availability_zone       = element(var.availability_zones,0)
  map_public_ip_on_launch = false
  tags = {
    Name  = "${var.environment}"
  }
}

resource "aws_security_group" "offsec" {
  name        = "${var.environment}-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = "${aws_vpc.main.id}"
  depends_on  = [aws_vpc.main]
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 3333
    to_port   = 3333
    protocol  = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Environment = "${var.environment}"
  }
}

# application load balancer security group
resource "aws_security_group" "alb" {
  description = "Security group for load balancer to only allow ingress traffic to port 80, 443, 3333"
  name   = "${random_pet.ec2.id}-sg-alb-${var.environment}"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 3333
    to_port          = 3333
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${random_pet.ec2.id}-sg-alb-${var.environment}"
    Environment = var.environment
  }
}
