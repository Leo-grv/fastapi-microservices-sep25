# ============================================================================
# VPC
# ============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc"
    }
  )
}

# ============================================================================
# INTERNET GATEWAY
# ============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-igw"
    }
  )
}

# ============================================================================
# SUBNETS PUBLICS (ALB + NAT Gateways)
# ============================================================================

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name                                           = "${var.project_name}-${var.environment}-public-${count.index + 1}"
      "kubernetes.io/role/elb"                       = "1"
      "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
    }
  )
}

# ============================================================================
# SUBNETS PRIVÉS EKS
# ============================================================================

resource "aws_subnet" "private_eks" {
  count = length(var.private_subnets_eks)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_eks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    var.tags,
    {
      Name                                           = "${var.project_name}-${var.environment}-private-eks-${count.index + 1}"
      "kubernetes.io/role/internal-elb"              = "1"
      "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
    }
  )
}

# ============================================================================
# SUBNETS PRIVÉS RDS
# ============================================================================

resource "aws_subnet" "private_rds" {
  count = length(var.private_subnets_rds)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_rds[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-private-rds-${count.index + 1}"
    }
  )
}

# ============================================================================
# ELASTIC IPs POUR NAT GATEWAYS
# ============================================================================

resource "aws_eip" "nat" {
  count  = length(var.public_subnets)
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ============================================================================
# NAT GATEWAYS (un par AZ)
# ============================================================================

resource "aws_nat_gateway" "main" {
  count = length(var.public_subnets)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ============================================================================
# ROUTE TABLE PUBLIQUE
# ============================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================================================
# ROUTE TABLES PRIVÉES (une par AZ pour NAT)
# ============================================================================

resource "aws_route_table" "private_eks" {
  count = length(var.private_subnets_eks)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-private-eks-rt-${count.index + 1}"
    }
  )
}

resource "aws_route_table_association" "private_eks" {
  count = length(var.private_subnets_eks)

  subnet_id      = aws_subnet.private_eks[count.index].id
  route_table_id = aws_route_table.private_eks[count.index].id
}

# ============================================================================
# ROUTE TABLE PRIVÉE RDS
# ============================================================================

resource "aws_route_table" "private_rds" {
  count = length(var.private_subnets_rds)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-private-rds-rt-${count.index + 1}"
    }
  )
}

resource "aws_route_table_association" "private_rds" {
  count = length(var.private_subnets_rds)

  subnet_id      = aws_subnet.private_rds[count.index].id
  route_table_id = aws_route_table.private_rds[count.index].id
}