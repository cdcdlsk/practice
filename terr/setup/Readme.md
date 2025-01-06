## Network Module Actions

### Overview
The Network module is responsible for setting up the foundational network infrastructure in AWS. This includes creating a VPC, subnets, route tables, and other necessary network components.

### Actions Performed

1. **VPC Creation**
   - Created a Virtual Private Cloud (VPC) to host the network resources.
   - Configured the CIDR block for the VPC.

2. **Subnet Creation**
   - Created public and private subnets across multiple availability zones for high availability.
   - Configured the CIDR blocks for each subnet.

3. **Internet Gateway**
   - Created an Internet Gateway and attached it to the VPC to allow internet access for public subnets.

4. **Elastic IP and NAT Gateway**
   - Allocated an Elastic IP address.
   - Created a NAT Gateway in the public subnet to allow outbound internet access for instances in private subnets.

5. **Route Tables**
   - Created route tables for public and private subnets.
   - Configured routes to direct traffic to the Internet Gateway for public subnets and to the NAT Gateway for private subnets.

6. **Route Table Associations**
   - Associated the public route table with public subnets.
   - Associated the private route table with private subnets.

### Example Configuration

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "elastic_ip_bcd" {
  vpc = true
}

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.elastic_ip_bcd.id
  subnet_id     = aws_subnet.public_subnet[0].id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}