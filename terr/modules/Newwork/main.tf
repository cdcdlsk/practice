resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "bcdlskvpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# resource "aws_subnet" "public_subnet1" {
#   availability_zone = "us-east-1c"
#   vpc_id = aws_vpc.main.id
#   cidr_block = "10.0.1.0/27"
# }

# resource "aws_subnet" "public_subnet2" {
#   availability_zone = "us-east-1a"
#   vpc_id = aws_vpc.main.id
#   cidr_block = "10.0.1.32/27"
# }

resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8,count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}





resource "aws_eip" "elastic_ip_bcd" {
    vpc = true
}


resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.elastic_ip_bcd.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public" {
    count = 2
  subnet_id      = element(aws_subnet.public_subnet.*.id,count.index)
  route_table_id = "${aws_route_table.public.id}"
}




resource "aws_route_table_association" "private" {
    count = 2
  subnet_id      = element(aws_subnet.private_subnet.*.id,count.index)
  route_table_id = "${aws_route_table.public.id}"
}

